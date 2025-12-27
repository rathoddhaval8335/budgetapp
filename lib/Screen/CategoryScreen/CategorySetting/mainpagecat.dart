import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Controllers/Expensecatgorycontroller.dart';
import '../../../Controllers/incomecategorycontroller.dart';
import '../maintabcategory.dart';
import 'addexpensecat.dart';
import 'addincomecat.dart';

class MainPageCat extends StatefulWidget {
  final int initialIndex;
  final String userId;

  const MainPageCat({super.key, this.initialIndex = 0, required this.userId});

  @override
  State<MainPageCat> createState() => _AddcatgoryState();
}

class _AddcatgoryState extends State<MainPageCat> {
  int selectedIndex = 0;

  // Keys for child refresh indicators
  final GlobalKey<RefreshIndicatorState> _expenseRefreshKey =
  GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _incomeRefreshKey =
  GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;

    // Initialize controllers (only if they don't exist)
    try {
      Get.find<ExpenseCategoryController>();
    } catch (e) {
      Get.put(ExpenseCategoryController(widget.userId));
    }

    try {
      Get.find<IncomeCategoryController>();
    } catch (e) {
      Get.put(IncomeCategoryController(widget.userId));
    }
  }

  // Function to trigger refresh in child widgets
  void _triggerRefresh() {
    if (selectedIndex == 0) {
      // Trigger refresh in Expense page
      _expenseRefreshKey.currentState?.show();
    } else {
      // Trigger refresh in Income page
      _incomeRefreshKey.currentState?.show();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          "Category Setting",
          style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: _triggerRefresh,
            tooltip: 'Refresh Data',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
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
      body: selectedIndex == 0
          ? Addexpensecategory(
        userId: widget.userId,
        refreshKey: _expenseRefreshKey,
      )
          : AddIncome(
        userId: widget.userId,
        refreshKey: _incomeRefreshKey,
      ),
    );
  }
}