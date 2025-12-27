// lib/Controllers/balance_report_controller.dart
import 'dart:convert';
import 'dart:io';
import 'package:budgetapp/Service/apiservice.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class BalanceReportController extends GetxController {
  // Rx variables
  var reportData = <Map<String, dynamic>>[].obs;
  var totalExpenses = 0.obs;
  var totalIncome = 0.obs;
  var totalBalance = 0.obs;
  var isLoading = true.obs;
  var isGeneratingPdf = false.obs;
  var selectedYear = DateTime.now().year.obs;
  var years = <int>[].obs;

  final String userId;

  BalanceReportController({required this.userId}) {
    initializeYears();
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  void initializeYears() {
    int currentYear = DateTime.now().year;
    years.value = List.generate(
      (currentYear + 1) - 2021 + 1,
          (index) => 2021 + index,
    );
  }

  Future<void> loadData() async {
    isLoading.value = true;
    await Future.wait([
      fetchMonthlyReport(selectedYear.value),
      _fetchTotals(selectedYear.value),
    ]);
    isLoading.value = false;
  }

  Future<void> fetchMonthlyReport(int year) async {
    try {
      final response = await http.post(
        Uri.parse(ApiService.getUrl("monthly_report.php")),
        body: {
          "user_id": userId,
          "year": year.toString(),
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'];

          reportData.value = data.map((item) {
            return {
              "month": item["month"],
              "expenses": item["expense"],
              "income": item["income"],
              "balance": item["balance"],
              "year": item["year"] ?? year,
            };
          }).toList();

          totalExpenses.value = reportData.fold(
              0, (sum, item) => sum + (item["expenses"] as num).toInt());
          totalIncome.value = reportData.fold(
              0, (sum, item) => sum + (item["income"] as num).toInt());
          totalBalance.value = totalIncome.value - totalExpenses.value;
        } else {
          reportData.clear();
          totalExpenses.value = 0;
          totalIncome.value = 0;
          totalBalance.value = 0;
        }
      }
    } catch (e) {
      reportData.clear();
      totalExpenses.value = 0;
      totalIncome.value = 0;
      totalBalance.value = 0;
      Get.snackbar(
        'Error',
        'Failed to fetch report',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _fetchTotals(int year) async {
    try {
      final [expenseTotal, incomeTotal] = await Future.wait([
        _fetchTotalExpense(year),
        _fetchTotalIncome(year),
      ]);

      totalExpenses.value = expenseTotal;
      totalIncome.value = incomeTotal;
      totalBalance.value = incomeTotal - expenseTotal;
    } catch (e) {
      // Error handled in snackbar
    }
  }

  Future<int> _fetchTotalExpense(int year) async {
    try {
      final response = await http.post(
        Uri.parse(ApiService.getUrl("total_expense.php")),
        body: {
          "user_id": userId,
          "year": year.toString(),
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          return (double.tryParse(jsonResponse['total'].toString()) ?? 0).toInt();
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _fetchTotalIncome(int year) async {
    try {
      final response = await http.post(
        Uri.parse(ApiService.getUrl("total_income.php")),
        body: {
          "user_id": userId,
          "year": year.toString(),
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          return (double.tryParse(jsonResponse['total'].toString()) ?? 0).toInt();
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> changeYear(int newYear) async {
    if (selectedYear.value != newYear) {
      selectedYear.value = newYear;
      isLoading.value = true;
      await Future.wait([
        fetchMonthlyReport(newYear),
        _fetchTotals(newYear),
      ]);
      isLoading.value = false;
    }
  }

  // Get month name from number
  String getMonthName(String monthNumber) {
    try {
      final monthNum = int.parse(monthNumber);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      if (monthNum >= 1 && monthNum <= 12) {
        return months[monthNum - 1];
      }
    } catch (e) {
      return monthNumber;
    }
    return monthNumber;
  }

  // Generate and save PDF
  Future<void> generateAndSavePdf() async {
    if (reportData.isEmpty) {
      Get.snackbar(
        'No Data',
        'No report data available to generate PDF',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isGeneratingPdf.value = true;

    try {
      // Check storage permission for Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          Get.snackbar(
            'Permission Required',
            'Storage permission is required to save PDF',
            snackPosition: SnackPosition.BOTTOM,
          );
          isGeneratingPdf.value = false;
          return;
        }
      }

      // Create PDF document
      final pdf = pw.Document();

      // Add content to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Column(
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
                      'Year: ${selectedYear.value}',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                    pw.Text(
                      'Generated on: ${DateTime.now().toString().split(' ')[0]}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Summary Section
              pw.SizedBox(height: 20),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue400, width: 1),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                padding: const pw.EdgeInsets.all(15),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Total Balance',
                          style: pw.TextStyle(
                            fontSize: 16,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          '₹$totalBalance',
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: totalBalance.value >= 0
                                ? PdfColors.green
                                : PdfColors.red,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Income: ₹$totalIncome',
                          style: pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.green,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Expense: ₹$totalExpenses',
                          style: pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Table Header
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue50,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Month',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Expenses',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Income',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Balance',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),

                  // Table Rows
                  for (var item in reportData)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(getMonthName(item["month"].toString())),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '₹${item["expenses"]}',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              color: PdfColors.red,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '₹${item["income"]}',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              color: PdfColors.green,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '₹${item["balance"]}',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                              color: (item["balance"] as num) < 0
                                  ? PdfColors.red
                                  : PdfColors.green,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Footer
              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'Generated by Budget App',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey500,
                  ),
                ),
              ),
            ];
          },
        ),
      );

      // Save PDF to device
      final directory = await getExternalStorageDirectory();
      final downloadsDir = Directory('/storage/emulated/0/Download');

      String filePath;
      if (await downloadsDir.exists()) {
        filePath = '${downloadsDir.path}/Balance_Report_${selectedYear.value}.pdf';
      } else {
        filePath = '${directory!.path}/Balance_Report_${selectedYear.value}.pdf';
      }

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Open the PDF file
      await OpenFile.open(filePath);

      Get.snackbar(
        'Success',
        'PDF saved to Downloads folder',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to generate PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isGeneratingPdf.value = false;
    }
  }
}