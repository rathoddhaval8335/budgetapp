import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:budgetapp/Service/apiservice.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

class BalanceReport extends StatefulWidget {
  final String userId;

  const BalanceReport({super.key, required this.userId});

  @override
  State<BalanceReport> createState() => _BalanceReportState();
}

class _BalanceReportState extends State<BalanceReport> {
  List<Map<String, dynamic>> reportData = [];
  int totalExpenses = 0;
  int totalIncome = 0;
  int totalBalance = 0;
  bool isLoading = true;
  bool isGeneratingPdf = false;

  late List<int> years;
  int selectedYear = DateTime.now().year;

  Future<void> fetchMonthlyReport(int year) async {
    setState(() => isLoading = true);

    try {
      var response = await http.post(
        Uri.parse(ApiService.getUrl("monthly_report.php")),
        body: {
          "user_id": widget.userId,
          "year": year.toString(),
        },
      );

      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] == 'success') {
        List<dynamic> data = jsonResponse['data'];
        setState(() {
          reportData = data
              .map((item) => {
            "month": item["month"],
            "expenses": item["expense"],
            "income": item["income"],
            "balance": item["balance"],
            "year": item["year"] ?? selectedYear,
          })
              .toList();

          totalExpenses = reportData.fold(
              0, (sum, item) => sum + (item["expenses"] as num).toInt());
          totalIncome = reportData.fold(
              0, (sum, item) => sum + (item["income"] as num).toInt());
          totalBalance = totalIncome - totalExpenses;
        });
      } else {
        print("No data found: ${jsonResponse['message']}");
        setState(() {
          reportData = [];
          totalExpenses = 0;
          totalIncome = 0;
          totalBalance = 0;
        });
      }
    } catch (e) {
      print("Error fetching report: $e");
      setState(() {
        reportData = [];
        totalExpenses = 0;
        totalIncome = 0;
        totalBalance = 0;
      });
    }

    setState(() => isLoading = false);
  }

  Future<int> fetchTotalExpense(String userId, int year) async {
    try {
      var response = await http.post(
        Uri.parse(ApiService.getUrl("total_expense.php")),
        body: {
          "user_id": userId,
          "year": year.toString(),
        },
      );

      var jsonResponse = jsonDecode(response.body);

      if (jsonResponse['status'] == 'success') {
        return (double.tryParse(jsonResponse['total'].toString()) ?? 0).toInt();
      }
    } catch (e) {
      print("Error fetching expense: $e");
    }
    return 0;
  }

  Future<int> fetchTotalIncome(String userId, int year) async {
    try {
      var response = await http.post(
        Uri.parse(ApiService.getUrl("total_income.php")),
        body: {
          "user_id": userId,
          "year": year.toString(),
        },
      );

      var jsonResponse = jsonDecode(response.body);

      if (jsonResponse['status'] == 'success') {
        return (double.tryParse(jsonResponse['total'].toString()) ?? 0).toInt();
      }
    } catch (e) {
      print("Error fetching income: $e");
    }
    return 0;
  }

  Future<void> _fetchTotals(int year) async {
    setState(() {
      isLoading = true;
    });

    int expense = await fetchTotalExpense(widget.userId, year);
    int income = await fetchTotalIncome(widget.userId, year);

    setState(() {
      totalExpenses = expense;
      totalIncome = income;
      totalBalance = income - expense;
    });
  }

  @override
  void initState() {
    super.initState();
    years = List.generate(
        (DateTime.now().year + 1) - 2021 + 1, (index) => 2021 + index);

    _fetchTotals(selectedYear);
    fetchMonthlyReport(selectedYear);
  }

  // PDF Generation Functions - Simplified
  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();

    // Format currency
    final currencyFormat = NumberFormat.currency(
      symbol: 'Rs.', // Change to your currency symbol
      decimalDigits: 0,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Balance Report',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        selectedYear == 0 ? 'All Years' : 'Year: $selectedYear',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        'Generated on: ${DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.now())}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey500,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    width: 50,
                    height: 50,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue100,
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'BR',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),

              // Summary Cards
              pw.Row(
                children: [
                  _buildSummaryCard(
                    'Total Income',
                    currencyFormat.format(totalIncome),
                    PdfColors.green,
                  ),
                  pw.SizedBox(width: 10),
                  _buildSummaryCard(
                    'Total Expenses',
                    currencyFormat.format(totalExpenses),
                    PdfColors.red,
                  ),
                  pw.SizedBox(width: 10),
                  _buildSummaryCard(
                    'Net Balance',
                    currencyFormat.format(totalBalance),
                    totalBalance >= 0 ? PdfColors.green : PdfColors.red,
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // Table Header
              pw.Container(
                padding: pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'Month',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        'Expenses',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        'Income',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        'Balance',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),

              // Table Data
              ...reportData.map((item) =>
                  pw.Container(
                    padding: pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.grey300,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            item["month"].toString(),
                            style: pw.TextStyle(fontSize: 12),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            currencyFormat.format(item["expenses"]),
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.red,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            currencyFormat.format(item["income"]),
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.green,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            currencyFormat.format(item["balance"]),
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: (item["balance"] as num) >= 0
                                  ? PdfColors.green
                                  : PdfColors.red,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
              ),

              // Footer
              pw.SizedBox(height: 40),
              pw.Divider(thickness: 1),
              pw.Center(
                child: pw.Text(
                  'Thank you for using Budget App',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey500,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  pw.Widget _buildSummaryCard(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: pw.EdgeInsets.all(15),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(
            color: PdfColor(0, 0, 0, 0.3), // RGBA (0–1 range)
            width: 2,
          ),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey700,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Check and request storage permission
  Future<bool> _checkAndRequestPermission() async {
    if (await Permission.storage.isGranted) {
      return true;
    } else {
      var status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  // Save PDF with proper error handling
  Future<void> _savePdfToDevice() async {
    if (isGeneratingPdf) return;

    setState(() {
      isGeneratingPdf = true;
    });

    try {
      // Show generating dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Generating PDF..."),
            ],
          ),
        ),
      );

      // Generate PDF
      final pdfBytes = await _generatePdf();

      // Get directory - use app's documents directory for better compatibility
      final directory = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('/storage/emulated/0/Download');

      String savePath;
      if (await downloadsDir.exists()) {
        savePath = downloadsDir.path;
      } else {
        savePath = directory.path;
      }

      // Create filename
      final fileName = 'Balance_Report_${selectedYear == 0 ? 'All_Years' : selectedYear}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final filePath = '$savePath/$fileName';

      // Save file
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      // Close dialog
      Navigator.pop(context);

      // Show success message with option to open
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("PDF Saved Successfully"),
          content: Text("File saved as: $fileName"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _openPdfFile(filePath);
              },
              child: Text("Open File"),
            ),
          ],
        ),
      );

    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      print('Error saving PDF: $e');

      // Show error with more details
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Error Saving PDF"),
          content: Text("Error: $e\n\nPlease check storage permissions."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings(); // Open app settings for permission
              },
              child: Text("Open Settings"),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        isGeneratingPdf = false;
      });
    }
  }

  // Open PDF file
  Future<void> _openPdfFile(String filePath) async {
    try {
      await OpenFile.open(filePath);
    } catch (e) {
      _showSnackBar('Could not open file: $e');
    }
  }

  // Print PDF
  Future<void> _printPdf() async {
    try {
      final pdfBytes = await _generatePdf();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      _showSnackBar('Printing error: $e');
    }
  }

  // Preview PDF
  Future<void> _previewPdf() async {
    try {
      final pdfBytes = await _generatePdf();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Balance_Report_${selectedYear == 0 ? 'All_Years' : selectedYear}.pdf',
      );
    } catch (e) {
      _showSnackBar('Preview error: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Show PDF options with permission check
  void _showPdfOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text('Generate PDF Report'),
              subtitle: Text('Balance Report for ${selectedYear == 0 ? 'All Years' : 'Year $selectedYear'}'),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.download, color: Colors.blue),
              title: Text('Download PDF'),
              subtitle: Text('Save PDF to device storage'),
              onTap: () {
                Navigator.pop(context);
                _savePdfToDevice();
              },
            ),
            ListTile(
              leading: Icon(Icons.print, color: Colors.green),
              title: Text('Print'),
              subtitle: Text('Print the report'),
              onTap: () {
                Navigator.pop(context);
                _printPdf();
              },
            ),
            ListTile(
              leading: Icon(Icons.share, color: Colors.orange),
              title: Text('Share'),
              subtitle: Text('Share PDF via other apps'),
              onTap: () {
                Navigator.pop(context);
                _previewPdf();
              },
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Note: Ensure storage permissions are granted',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(215),
        child: AppBar(
          centerTitle: true,
          backgroundColor: Colors.blue.shade700,
          elevation: 0,
          actions: [
            // PDF Download Button with loading indicator
            isGeneratingPdf
                ? Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
                : IconButton(
              icon: Icon(Icons.picture_as_pdf, color: Colors.white),
              onPressed: _showPdfOptions,
              tooltip: 'Generate PDF Report',
            ),
            // Year Dropdown
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 12),
              child: DropdownButton<int>(
                dropdownColor: Colors.black,
                value: selectedYear,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                items: [
                  const DropdownMenuItem<int>(
                    value: 0,
                    child: Text("All"),
                  ),
                  ...years.map((year) {
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }).toList(),
                ],
                onChanged: (value) async {
                  if (value != null) {
                    setState(() {
                      selectedYear = value;
                      isLoading = true;
                    });
                    await _fetchTotals(value);
                    await fetchMonthlyReport(value);
                  }
                },
              ),
            ),
          ],
          flexibleSpace: Padding(
            padding: const EdgeInsets.only(
                top: 40, left: 16, right: 16, bottom: 16),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    selectedYear == 0 ? "All Years" : "Year $selectedYear",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "₹$totalBalance", // Added currency symbol
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Expenses: ₹$totalExpenses   Income: ₹$totalIncome",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reportData.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              "No data found for selected year",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Table Headers
          Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    "Month",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Expenses",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    "Income",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    "Balance",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Data List
          Expanded(
            child: ListView.builder(
              itemCount: reportData.length,
              itemBuilder: (context, index) {
                final item = reportData[index];
                return Container(
                  color: index % 2 == 0
                      ? Colors.white
                      : Colors.grey.shade50,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            item["month"],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "₹${item["expenses"]}",
                            style: const TextStyle(
                                fontSize: 16, color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "₹${item["income"]}",
                            style: const TextStyle(
                                fontSize: 16, color: Colors.green),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "₹${item["balance"]}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: (item["balance"] as num) < 0
                                  ? Colors.red
                                  : Colors.green,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}