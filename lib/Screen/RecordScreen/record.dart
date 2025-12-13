import 'dart:convert';

import 'package:budgetapp/Screen/RecordScreen/transctionitem.dart';
import 'package:budgetapp/Service/apiservice.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

class RecordPage extends StatefulWidget {
  final String userId;
  const RecordPage({super.key, required this.userId});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  String year = DateFormat('yyyy').format(DateTime.now());
  String month = DateFormat('MMM').format(DateTime.now()).toUpperCase();
  String monthNumber = DateFormat('MM').format(DateTime.now()); // Add this for month number
  int totalExpense = 0;
  int totalIncome = 0;
  int balance = 0;

  Future<void> _pickMonthYear() async {
    final DateTime? picked = await showMonthPicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        year = DateFormat('yyyy').format(picked);
        month = DateFormat('MMM').format(picked).toUpperCase();
        monthNumber = DateFormat('MM').format(picked); // Update month number
      });
      _fetchTotals(); // Refresh totals when month changes
    }
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
    int expense = await fetchTotalExpense(widget.userId);
    int income = await fetchTotalIncome(widget.userId);

    setState(() {
      totalExpense = expense;
      totalIncome = income;
      balance = income - expense;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchTotals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.blue,
        title: const Text(
          "Money Tracker",
          style: TextStyle(
              fontSize: 15, color: Colors.black, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.calendar_month)),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Year + Month
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      year,
                      style: const TextStyle(fontSize: 15, color: Colors.black),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          month,
                          style: const TextStyle(
                              fontSize: 20, color: Colors.black),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _pickMonthYear,
                          icon: const Icon(Icons.arrow_circle_down, size: 22),
                        ),
                      ],
                    ),
                  ],
                ),

                // Expenses
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Expenses",
                        style: TextStyle(fontSize: 15, color: Colors.black)),
                    const SizedBox(height: 5),
                    Text(totalExpense.toString(),
                        style: const TextStyle(fontSize: 15, color: Colors.black)),
                  ],
                ),

                // Income
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children:  [
                    const Text("Income",
                        style: TextStyle(fontSize: 15, color: Colors.black)),
                    const SizedBox(height: 5),
                    Text(totalIncome.toString(),
                        style: const TextStyle(fontSize: 15, color: Colors.black)),
                  ],
                ),

                // Balance
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children:  [
                    const Text("Balance",
                        style: TextStyle(fontSize: 15, color: Colors.black)),
                    const SizedBox(height: 5),
                    Text(balance.toString(),
                        style: const TextStyle(fontSize: 15, color: Colors.black)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: TransactionListPage(
        userId: widget.userId,
        selectedMonth: month,
        selectedYear: year,
      ),
    );
  }
}