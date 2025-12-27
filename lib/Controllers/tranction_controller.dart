import 'dart:convert';
import 'dart:math';
import 'package:budgetapp/Service/apiservice.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class TransactionController extends GetxController {
  late String userId;
  late String selectedMonth;
  late String selectedYear;

  TransactionController({
    required String userId,
    required String selectedMonth,
    required String selectedYear,
  }) {
    this.userId = userId;
    this.selectedMonth = selectedMonth;
    this.selectedYear = selectedYear;
  }

  // Rx variables for state management
  var transactions = <dynamic>[].obs;
  var isLoading = true.obs;
  var isRefreshing = false.obs;
  var errorMessage = ''.obs;

  // Colors for category icons
  final List<Color> _bgColors = [
    Colors.red.shade400,
    Colors.blue.shade400,
    Colors.green.shade400,
    Colors.orange.shade400,
    Colors.purple.shade400,
    Colors.teal.shade400,
    Colors.amber.shade400,
    Colors.indigo.shade400,
    Colors.pink.shade400,
    Colors.cyan.shade400,
    Colors.deepOrange.shade400,
    Colors.lime.shade400,
  ];

  // Get random color for category icon
  Color getRandomColor() {
    final random = Random();
    return _bgColors[random.nextInt(_bgColors.length)];
  }

  // Initialize controller
  @override
  void onInit() {
    super.onInit();
    fetchTransactions();
  }

  // Update month and year
  void updateMonthYear(String month, String year) {
    selectedMonth = month;
    selectedYear = year;
    transactions.clear();
    isLoading.value = true;
    fetchTransactions();
  }

  // Fetch transactions from API
  Future<void> fetchTransactions({bool refresh = false}) async {
    try {
      if (refresh) {
        isRefreshing.value = true;
      } else {
        isLoading.value = true;
      }

      errorMessage.value = '';

      // API URLs
      final String expenseApi = ApiService.getUrl("fd_exp_tranction.php");
      final String incomeApi = ApiService.getUrl("fd_income_tranction.php");

      // Make parallel API calls
      final responses = await Future.wait([
        _fetchExpenseTransactions(expenseApi),
        _fetchIncomeTransactions(incomeApi),
      ]);

      // Combine and sort data
      List<dynamic> mergedData = [...responses[0], ...responses[1]];
      _sortTransactions(mergedData);

      transactions.value = mergedData;
    } catch (e) {
      errorMessage.value = 'Failed to load transactions: ${e.toString()}';
      _showErrorSnackbar();
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  // Fetch expense transactions
  Future<List<dynamic>> _fetchExpenseTransactions(String apiUrl) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'userid': userId,
          'month': selectedMonth,
          'year': selectedYear,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          List<dynamic> expenses = data['data'];
          for (var expense in expenses) {
            expense['type'] = 'Expense';
          }
          return expenses;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Fetch income transactions
  Future<List<dynamic>> _fetchIncomeTransactions(String apiUrl) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'userid': userId,
          'month': selectedMonth,
          'year': selectedYear,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          List<dynamic> incomes = data['data'];
          for (var income in incomes) {
            income['type'] = 'Income';
          }
          return incomes;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Sort transactions by date (newest first)
  void _sortTransactions(List<dynamic> data) {
    data.sort((a, b) {
      DateTime dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(2000);
      DateTime dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });
  }

  // Get transaction statistics
  Map<String, dynamic> getStatistics() {
    double totalIncome = 0;
    double totalExpense = 0;
    int expenseCount = 0;
    int incomeCount = 0;

    for (var transaction in transactions) {
      double amount = double.tryParse(transaction['amount']?.toString() ?? '0') ?? 0;
      if (transaction['type'] == 'Income') {
        totalIncome += amount.abs();
        incomeCount++;
      } else {
        totalExpense += amount.abs();
        expenseCount++;
      }
    }

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'expenseCount': expenseCount,
      'incomeCount': incomeCount,
      'netBalance': totalIncome - totalExpense,
      'totalTransactions': transactions.length,
    };
  }

  // Show error snackbar
  void _showErrorSnackbar() {
    if (errorMessage.value.isNotEmpty) {
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(10),
        borderRadius: 8,
      );
    }
  }

  // Clear all data
  void clearData() {
    transactions.clear();
    isLoading.value = true;
    errorMessage.value = '';
  }

  // Check if same date as previous transaction
  bool isSameDateAsPrevious(int index) {
    if (index == 0) return false;

    String currentDate = transactions[index]['date'] ?? '';
    String previousDate = transactions[index - 1]['date'] ?? '';

    return currentDate == previousDate;
  }

  // Format amount display
  String formatAmount(dynamic transaction) {
    String amount = transaction['amount']?.toString() ?? '0';
    if (transaction['type'] == 'Income' && amount.startsWith('-')) {
      amount = amount.substring(1);
    }
    return amount;
  }

  // Get icon data for transaction
  IconData getIconData(dynamic transaction) {
    return IconData(
      int.tryParse(transaction['cat_icon']?.toString() ?? '0') ?? 0,
      fontFamily: 'MaterialIcons',
    );
  }
}