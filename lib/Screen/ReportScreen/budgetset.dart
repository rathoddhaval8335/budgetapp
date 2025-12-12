import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'budgetupdate.dart';
import 'setbudgetcat.dart';

class BudgetItem {
  final int id;
  final String title;
  final double budget;
  final double remaining;
  final int iconCode;
  final String month;

  BudgetItem({
    required this.id,
    required this.iconCode,
    required this.title,
    required this.budget,
    required this.remaining,
    required this.month,
  });
}

class BudgetScreen extends StatefulWidget {
  final String userId;
  const BudgetScreen({super.key, required this.userId});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  List<BudgetItem> budgetItems = [];
  bool isLoading = true;

  List<String> monthList = [];
  String? selectedMonth;

  @override
  void initState() {
    super.initState();
    generateMonthList();
    fetchBudgetData();
  }

  void generateMonthList() {
    final now = DateTime.now();
    int currentYear = now.year;
    int currentMonth = now.month;

    monthList.clear();

    // Start from January 2025
    DateTime start = DateTime(2025, 1);

    // ✅ End month = current month + 1 (next month bhi show ho)
    DateTime end = DateTime(currentYear, currentMonth + 1);

    while (start.isBefore(end) ||
        (start.month == end.month && start.year == end.year)) {
      String monthName = "${_getMonthName(start.month)} ${start.year}";
      monthList.add(monthName);

      // Move to next month
      start = DateTime(start.year, start.month + 1);
    }

    // ✅ Default selected month = current month
    selectedMonth = "${_getMonthName(currentMonth)} $currentYear";
  }

  String _getMonthName(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  Future<void> fetchBudgetData() async {
    if (selectedMonth == null) return;

    final url = Uri.parse(
        'http://192.168.43.192/BUDGET_APP/fd_remainig_val.php?userid=${widget.userId}&month=$selectedMonth');

    print('Fetching data for month: $selectedMonth');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        List<BudgetItem> loadedItems = data.map((item) {
          double budget = double.tryParse(item['budget'].toString()) ?? 0;
          double remaining = double.tryParse(item['remaining'].toString()) ?? 0;

          return BudgetItem(
            title: item['cat_name'] ?? 'No Name',
            budget: budget,
            remaining: remaining,
            iconCode: int.tryParse(item['cat_icon'].toString()) ?? 0,
            id: int.tryParse(item['id'].toString()) ?? 0,
            month: item['month'] ?? selectedMonth!,
          );
        }).toList();

        setState(() {
          budgetItems = loadedItems;
          isLoading = false;
        });
      } else {
        print('Server Error: ${response.statusCode}');
        print('Response: ${response.body}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() => isLoading = false);
    }
  }

  // Method to fetch data when month changes
  Future<void> fetchBudgetDataForMonth(String month) async {
    setState(() {
      isLoading = true;
      selectedMonth = month;
    });

    final url = Uri.parse(
        'http://192.168.43.192/BUDGET_APP/fd_remainig_val.php?userid=${widget.userId}&month=$month');

    print('Fetching data for month: $month');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        List<BudgetItem> loadedItems = data.map((item) {
          double budget = double.tryParse(item['budget'].toString()) ?? 0;
          double remaining = double.tryParse(item['remaining'].toString()) ?? 0;

          return BudgetItem(
            title: item['cat_name'] ?? 'No Name',
            budget: budget,
            remaining: remaining,
            iconCode: int.tryParse(item['cat_icon'].toString()) ?? 0,
            id: int.tryParse(item['id'].toString()) ?? 0,
            month: item['month'] ?? month,
          );
        }).toList();

        setState(() {
          budgetItems = loadedItems;
          isLoading = false;
        });
      } else {
        print('Server Error: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Budgets"),
        backgroundColor: Colors.blue[700],
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedMonth,
                dropdownColor: Colors.white,
                items: monthList.map((month) {
                  return DropdownMenuItem<String>(
                    value: month,
                    child: Text(month,
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w600)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    fetchBudgetDataForMonth(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : budgetItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.money_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No budget set for $selectedMonth",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              "Go to Budget Settings to add budgets",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: budgetItems.length,
        itemBuilder: (context, index) {
          final item = budgetItems[index];
          double spent = item.budget - item.remaining; // Expenses
          double percentage =
          item.budget == 0 ? 0 : item.remaining / item.budget;
          String percentageText = item.budget == 0
              ? "--"
              : "${(percentage * 100).toStringAsFixed(1)}%";

          return GestureDetector(
            onTap: () async {
              bool? updated = await showDialog(
                context: context,
                builder: (context) => BudgetUpdateDialog(
                  id: item.id, // fd_budget table ka ID
                  title: item.title,
                  currentBudget: item.budget,
                  userId: widget.userId,
                  month: selectedMonth!,
                ),
              );

              if (updated == true) {
                fetchBudgetDataForMonth(selectedMonth!);
              }
            },
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              IconData(
                                item.iconCode,
                                fontFamily: 'MaterialIcons',
                              ),
                              color: Colors.blue,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              item.title,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        Text(
                          item.month,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          height: 110,
                          width: 110,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: percentage,
                                strokeWidth: 6,
                                backgroundColor: Colors.grey[300],
                                valueColor:
                                AlwaysStoppedAnimation<Color>(
                                    Colors.blue),
                              ),
                              Text(
                                percentageText,
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Remaining :",
                                      style: TextStyle(fontSize: 12)),
                                  Text("₹${item.remaining.toStringAsFixed(0)}",
                                      style: TextStyle(fontSize: 12)),
                                ],
                              ),
                              SizedBox(height: 8),
                              Divider(thickness: 1, color: Colors.grey),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Budget :",
                                      style: TextStyle(fontSize: 12)),
                                  Text("₹${item.budget.toStringAsFixed(0)}",
                                      style: TextStyle(fontSize: 12)),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Expenses :",
                                      style: TextStyle(fontSize: 12)),
                                  Text("₹${spent.toStringAsFixed(0)}",
                                      style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Setbudgetcat(
                  userId: widget.userId,
                  selectedMonth: selectedMonth!,
                ),
              ),
            ).then((_) {
              // Refresh data when returning from budget settings
              fetchBudgetDataForMonth(selectedMonth!);
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            padding: EdgeInsets.symmetric(vertical: 16),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            "+ Budget Settings",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}