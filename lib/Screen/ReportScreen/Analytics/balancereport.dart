import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  late List<int> years;
  int selectedYear = DateTime.now().year;

  Future<void> fetchMonthlyReport(int year) async {
    setState(() => isLoading = true);

    try {
      var response = await http.post(
        Uri.parse("http://192.168.43.192/BUDGET_APP/monthly_report.php"),
        body: {
          "user_id": widget.userId,
          "year": year.toString(), // send selected year (0 for All)
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

          // Calculate totals based on filtered data
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
        Uri.parse("http://192.168.43.192/BUDGET_APP/total_expense.php"),
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
        Uri.parse("http://192.168.43.192/BUDGET_APP/total_income.php"),
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

  // Group data by year for display
  Map<String, List<Map<String, dynamic>>> get groupedData {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in reportData) {
      String year = item["year"].toString();
      if (!grouped.containsKey(year)) {
        grouped[year] = [];
      }
      grouped[year]!.add(item);
    }

    return grouped;
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
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "$totalBalance",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Expenses : $totalExpenses   Income : $totalIncome",
                    style: const TextStyle(
                      color: Colors.black,
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
          ? const Center(
        child: Text(
          "No data found for selected year",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : Column(
        children: [
          // Table Headers
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Month",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  "Expenses",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  "Income",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  "Balance",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
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
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          item["month"],
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item["expenses"].toString(),
                          style: const TextStyle(fontSize: 17),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item["income"].toString(),
                          style: const TextStyle(fontSize: 17),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item["balance"].toString(),
                          style: TextStyle(
                            fontSize: 17,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}