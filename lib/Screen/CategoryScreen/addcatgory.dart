import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Controllers/Expensecontroller.dart';
import '../../Controllers/Incomecontroller.dart';
import 'Expense/expense.dart';
import 'Income/income.dart';
import 'maintabcategory.dart';

class Addcatgory extends StatefulWidget {
  final String userId;
  const Addcatgory({super.key, required this.userId});

  @override
  State<Addcatgory> createState() => _AddcatgoryState();
}

class _AddcatgoryState extends State<Addcatgory> {
  int selectedIndex = 0;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();

  // Refresh function for both expense and income pages
  Future<void> _handleRefresh() async {
    if (selectedIndex == 0) {
      // Refresh Expense page
      try {
        final expenseController = Get.find<ExpenseController>();
        await expenseController.refreshData();
      } catch (e) {
        print("ExpenseController error: $e");
      }
    } else {
      // Refresh Income page
      try {
        final incomeController = Get.find<IncomeController>();
        await incomeController.refreshData();
      } catch (e) {
        print("IncomeController error: $e");
      }
    }
  }

  // Function to trigger refresh from AppBar
  void _triggerRefresh() {
    _refreshIndicatorKey.currentState?.show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          "Add",
          style: TextStyle(
              fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // Refresh Button in AppBar
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              _triggerRefresh();
            },
            tooltip: 'Refresh Data',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(36),
          child: ExInTabpage(
            selectedIndex: selectedIndex,
            onTabChanged: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
          ),
        ),
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _handleRefresh,
        color: Colors.blue,
        backgroundColor: Colors.white,
        strokeWidth: 2.5,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.9,
            child: selectedIndex == 0
                ? ExpensePage(userId: widget.userId)
                : IncomePage(userId: widget.userId),
          ),
        ),
      ),
    );
  }
}