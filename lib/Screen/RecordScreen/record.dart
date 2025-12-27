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
  String monthNumber = DateFormat('MM').format(DateTime.now());
  int totalExpense = 0;
  int totalIncome = 0;
  int balance = 0;
  bool _isRefreshing = false;

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
        monthNumber = DateFormat('MM').format(picked);
      });
      await _fetchTotals();
    }
  }

  Future<int> fetchTotalExpense(String userId) async {
    try {
      var response = await http.post(
        Uri.parse(ApiService.getUrl("total_exp_month.php")),
        body: {
          "user_id": userId,
          "month": monthNumber,
          "year": year,
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
        Uri.parse(ApiService.getUrl("total_income_month.php")),
        body: {
          "user_id": userId,
          "month": monthNumber,
          "year": year,
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
      _isRefreshing = true;
    });

    try {
      int expense = await fetchTotalExpense(widget.userId);
      int income = await fetchTotalIncome(widget.userId);

      setState(() {
        totalExpense = expense;
        totalIncome = income;
        balance = income - expense;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _isRefreshing = false;
      });
      print("Error fetching totals: $e");
    }
  }

  // Refresh button function
  void _handleRefresh() async {
    await _fetchTotals();
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
          IconButton(
            onPressed: _isRefreshing ? null : _handleRefresh,
            icon: _isRefreshing
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black,
              ),
            )
                : const Icon(Icons.refresh, color: Colors.black),
          ),
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
                    _isRefreshing
                        ? const SizedBox(
                      height: 15,
                      width: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                        : Text(totalExpense.toString(),
                        style: const TextStyle(
                            fontSize: 15, color: Colors.black)),
                  ],
                ),

                // Income
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Income",
                        style: TextStyle(fontSize: 15, color: Colors.black)),
                    const SizedBox(height: 5),
                    _isRefreshing
                        ? const SizedBox(
                      height: 15,
                      width: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                        : Text(totalIncome.toString(),
                        style: const TextStyle(
                            fontSize: 15, color: Colors.black)),
                  ],
                ),

                // Balance
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Balance",
                        style: TextStyle(fontSize: 15, color: Colors.black)),
                    const SizedBox(height: 5),
                    _isRefreshing
                        ? const SizedBox(
                      height: 15,
                      width: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                        : Text(balance.toString(),
                        style: const TextStyle(
                            fontSize: 15, color: Colors.black)),
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
        onDataRefresh: _fetchTotals, // Pass callback to TransactionListPage
      ),
    );
  }
}