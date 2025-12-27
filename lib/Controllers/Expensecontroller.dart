import 'dart:convert';
import 'package:budgetapp/Service/apiservice.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ExpenseController extends GetxController {
  final String userId;
  ExpenseController(this.userId);

  var expenseCategories = <dynamic>[].obs;
  var isLoading = true.obs;

  final String url = ApiService.getUrl("fd_view_exp.php");

  @override
  void onInit() {
    super.onInit();
    fetchExpenseCategories();
  }

  Future<void> fetchExpenseCategories() async {
    try {
      isLoading.value = true;
      update(); // यहाँ update() call करें

      var response = await http.post(
        Uri.parse(url),
        body: {"userid": userId},
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'success') {
          expenseCategories.value = jsonResponse['data'] ?? [];
        }
      }
      isLoading.value = false;
      update(); // यहाँ भी update() call करें
    } catch (e) {
      isLoading.value = false;
      update(); // Error होने पर भी update()
      Get.snackbar(
        "Error",
        "Error fetching data: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> refreshData() async {
    await fetchExpenseCategories();
  }
}