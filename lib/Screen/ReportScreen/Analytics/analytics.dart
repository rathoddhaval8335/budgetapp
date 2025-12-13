import 'dart:convert';

import 'package:budgetapp/Service/apiservice.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'balancereport.dart';
import 'report2.dart';

class AnalyticsPage extends StatefulWidget {
  final String userId;
  const AnalyticsPage({super.key, required this.userId});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  String year = DateFormat('yyyy').format(DateTime.now());
  String month = DateFormat('MMM').format(DateTime.now()).toUpperCase();
  String monthNumber = DateFormat('MM').format(DateTime.now()); // Add this for month number
  int totalExpense = 0;
  int totalIncome = 0;
  int balance = 0;
  bool isLoading = true;
  // Current month name in short format (OCT, NOV, DEC, etc.)
  String getCurrentMonth() {
    return DateFormat('MMM').format(DateTime.now()).toUpperCase();
  }

  Future<int> fetchTotalExpense(String userId) async {
    try {
      var response = await http.post(
        //Uri.parse("http://192.168.43.192/BUDGET_APP/total_exp_month.php"),
        Uri.parse(ApiService.getUrl("total_exp_month.php")),
        body: {
          "user_id": userId,
          "month": monthNumber, // Add month parameter
          "year": year, // Add year parameter
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

  Future<int> fetchTotalIncome(String userId) async {
    try {
      var response = await http.post(
        //Uri.parse("http://192.168.43.192/BUDGET_APP/total_income_month.php"),
        Uri.parse(ApiService.getUrl("total_income_month.php")),
        body: {
          "user_id": userId,
          "month": monthNumber, // Add month parameter
          "year": year, // Add year parameter
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

  Future<void> _fetchTotals() async {
    setState(() {
      isLoading = true;
    });
    int expense = await fetchTotalExpense(widget.userId);
    int income = await fetchTotalIncome(widget.userId);

    setState(() {
      totalExpense = expense;
      totalIncome = income;
      balance = income - expense;
      isLoading = false;
    });
  }
  @override
  void initState() {
    super.initState();
    _fetchTotals();
  }
  @override
  Widget build(BuildContext context) {
    String currentMonth = getCurrentMonth();

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 190,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BalanceReport(
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Monthly Statics",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Icon(Icons.arrow_forward),
                          ],
                        ),
                        SizedBox(height: 20),
                        // Data Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              currentMonth, // Dynamic month here
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:  FontWeight.w600,
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  "Expense",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  totalExpense.toString(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight:  FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  "Income",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight:  FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  totalIncome.toString(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight:  FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  "Balance",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight:  FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  balance.toString(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight:  FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: BudgetCard(userId: widget.userId,),
          ),
        ],
      ),
    );
  }
}