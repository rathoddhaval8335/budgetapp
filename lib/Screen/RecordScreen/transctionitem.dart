import 'dart:convert';
import 'dart:math';
import 'package:budgetapp/Service/apiservice.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'tranctiondetails.dart';

class TransactionListPage extends StatefulWidget {
  final String userId;
  final String selectedMonth;
  final String selectedYear;
  const TransactionListPage({super.key, required this.userId, required this.selectedMonth, required this.selectedYear});

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  List<dynamic> transactions = [];
  bool isLoading = true;

  final List<Color> bgColors = [
    Colors.red.shade400,
    Colors.blue.shade400,
    Colors.green.shade400,
    Colors.orange.shade400,
    Colors.purple.shade400,
    Colors.teal.shade400,
    Colors.amber.shade400,
  ];

  Color getRandomColor() {
    final random = Random();
    return bgColors[random.nextInt(bgColors.length)];
  }

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  // ✅ ADD THIS METHOD - This detects when month/year changes
  @override
  void didUpdateWidget(TransactionListPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if month or year changed
    if (oldWidget.selectedMonth != widget.selectedMonth ||
        oldWidget.selectedYear != widget.selectedYear) {
      // Reset and reload data
      setState(() {
        isLoading = true;
        transactions = [];
      });
      fetchTransactions();
    }
  }

  Future<void> fetchTransactions() async {
   // final String expenseApi = "http://192.168.43.192/BUDGET_APP/fd_exp_tranction.php";
    final String expenseApi = ApiService.getUrl("fd_exp_tranction.php");
    //final String incomeApi = "http://192.168.43.192/BUDGET_APP/fd_income_tranction.php";
    final String incomeApi = ApiService.getUrl("fd_income_tranction.php");

    try {
      // POST request for both APIs with month and year
      final expenseResponse = await http.post(
        Uri.parse(expenseApi),
        body: {
          'userid': widget.userId,
          'month': widget.selectedMonth, // e.g. OCT
          'year': widget.selectedYear,   // e.g. 2025
        },
      );

      final incomeResponse = await http.post(
        Uri.parse(incomeApi),
        body: {
          'userid': widget.userId,
          'month': widget.selectedMonth,
          'year': widget.selectedYear,
        },
      );

      List<dynamic> mergedData = [];

      if (expenseResponse.statusCode == 200) {
        final expData = jsonDecode(expenseResponse.body);
        if (expData['success'] == true) {
          List<dynamic> expenses = expData['data'];
          for (var e in expenses) {
            e['type'] = 'Expense';
          }
          mergedData.addAll(expenses);
        }
      }

      if (incomeResponse.statusCode == 200) {
        final incData = jsonDecode(incomeResponse.body);
        if (incData['success'] == true) {
          List<dynamic> incomes = incData['data'];
          for (var e in incomes) {
            e['type'] = 'Income';
          }
          mergedData.addAll(incomes);
        }
      }

      // Sort by latest date
      mergedData.sort((a, b) {
        DateTime dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(2000);
        DateTime dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });

      setState(() {
        transactions = mergedData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : transactions.isEmpty
          ? const Center(child: Text("No transactions found for this month"))
          : ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final t = transactions[index];
          final iconData = IconData(
            int.tryParse(t['cat_icon'] ?? '0') ?? 0,
            fontFamily: 'MaterialIcons',
          );
          final Color bgColor = getRandomColor();

          // Prepare amount for trailing
          String displayAmount = t['amount'] ?? '';
          if (t['type'] == 'Income' && displayAmount.startsWith('-')) {
            displayAmount = displayAmount.substring(1); // remove minus for income
          }

          // Summary
          String summary = "${t['type']}: ₹$displayAmount";

          return buildDateSection(
            date: t['date'] ?? '',
            day: t['day'] ?? '',
            summary: summary,
            transactions: [
              TransactionItem(
                id: t['id']?.toString() ?? '',
                income_id: t['income_id']?.toString() ?? '',
                type: t['type'],
                iconData: iconData,
                bgColor: bgColor,
                title: t['cat_name'] ?? '',
                amount: displayAmount,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionDetailPage(
                          categoryName: t['cat_name'] ?? '',
                          iconData: iconData,
                          type: t['type'],
                          amount: displayAmount,
                          date: t['date'] ?? '',
                          id: t['id']?.toString() ?? '',
                          income_id: t['income_id']?.toString() ?? ''
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildDateSection({
    required String date,
    required String day,
    required String summary,
    required List<TransactionItem> transactions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$date $day',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              Text(
                summary,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
        ...transactions.map((item) => item),
        const SizedBox(height: 10),
      ],
    );
  }
}

class TransactionItem extends StatelessWidget {
  final String id;
  final String income_id;
  final IconData iconData;
  final Color bgColor;
  final String title;
  final String amount;
  final String type;
  final VoidCallback? onTap;

  const TransactionItem({
    super.key,
    required this.id,
    required this.income_id,
    required this.iconData,
    required this.bgColor,
    required this.title,
    required this.amount,
    required this.type,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: bgColor,
          child: Icon(iconData, color: Colors.white, size: 25),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: Text(
          amount,
          style: TextStyle(
            fontSize: 16,
            color: type == 'Expense' ? Colors.red : Colors.green,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}