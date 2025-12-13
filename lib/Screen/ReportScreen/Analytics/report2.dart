import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../Service/apiservice.dart';
import '../budgetset.dart';

class BudgetCard extends StatefulWidget {
  final String userId;
  const BudgetCard({super.key, required this.userId});

  @override
  State<BudgetCard> createState() => _BudgetCardState();
}

class _BudgetCardState extends State<BudgetCard> {
  double budget = 0;
  double remaining = 0;
  double used = 0; // Changed to use actual expense data
  bool isLoading = true;

  String year = DateFormat('yyyy').format(DateTime.now());
  String month = DateFormat('MMM').format(DateTime.now()).toUpperCase();
  String monthNumber = DateFormat('MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await Future.wait([
      fetchMonthlyBudget(),
      fetchTotalExpense(), // Fetch current month expense
    ]);
  }

  Future<void> fetchMonthlyBudget() async {
    try {
      final response = await http.post(
       // Uri.parse("http://192.168.43.192/BUDGET_APP/fd_get_monthly.php"),
        Uri.parse(ApiService.getUrl("fd_get_monthly.php")),
        body: {"userid": widget.userId},
      );

      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        setState(() {
          budget = double.tryParse(data['data']['budget'].toString()) ?? 0;
          remaining = double.tryParse(data['data']['remaining'].toString()) ?? 0;
        });
      }
    } catch (e) {
      print("Error fetching budget: $e");
    }
  }

  Future<void> fetchTotalExpense() async {
    try {
      var response = await http.post(
        //Uri.parse("http://192.168.43.192/BUDGET_APP/total_exp_month.php"),
        Uri.parse(ApiService.getUrl("total_exp_month.php")),
        body: {
          "user_id": widget.userId,
          "month": monthNumber,
          "year": year,
        },
      );

      var jsonResponse = jsonDecode(response.body);
      print('Expense API Response: $jsonResponse'); // Debug print

      if (jsonResponse['status'] == 'success') {
        double expense = double.tryParse(jsonResponse['total'].toString()) ?? 0;
        setState(() {
          used = expense;
          // Update remaining based on actual expense
          remaining = budget - expense;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching expense: $e");
      setState(() => isLoading = false);
    }
  }

  // Refresh data when widget is updated
  @override
  void didUpdateWidget(BudgetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = budget > 0 ? (used / budget).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BudgetScreen(userId: widget.userId),
          ),
        ).then((_) {
          // Refresh data when returning from BudgetScreen
          _fetchData();
        });
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Monthly Budget ($month)",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: _fetchData,
                    iconSize: 20,
                  ),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    height: 90,
                    width: 90,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress > 0.8 ? Colors.red :
                            progress > 0.5 ? Colors.orange : Colors.blue,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${(progress * 100).toStringAsFixed(0)}%",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: progress > 0.8 ? Colors.red : Colors.black,
                              ),
                            ),
                            Text(
                              month,
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Remaining
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Remaining:", style: TextStyle(fontSize: 12)),
                            Text(
                              "₹${remaining.toStringAsFixed(0)}",
                              style: TextStyle(
                                fontSize: 12,
                                color: remaining < 0 ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(thickness: 1, color: Colors.grey),
                        const SizedBox(height: 8),
                        // Budget
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Budget:", style: TextStyle(fontSize: 12)),
                            Text(
                              "₹${budget.toStringAsFixed(0)}",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Expenses (Current Month)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Expenses:", style: TextStyle(fontSize: 12)),
                            Text(
                              "₹${used.toStringAsFixed(0)}",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "($month $year)",
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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
  }
}