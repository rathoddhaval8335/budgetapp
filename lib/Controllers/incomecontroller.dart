import 'dart:convert';
import 'package:budgetapp/Service/apiservice.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class IncomeController extends GetxController {
  final String userId;
  IncomeController(this.userId);

  var incomeCategories = <dynamic>[].obs;
  var isLoading = true.obs;

  final String url = ApiService.getUrl("fd_view_income.php");

  @override
  void onInit() {
    super.onInit();
    fetchIncomeCategories();
  }

  Future<void> fetchIncomeCategories() async {
    try {
      isLoading.value = true;
      var response = await http.post(
        Uri.parse(url),
        body: {"userid": userId},
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'success') {
          incomeCategories.value = jsonResponse['data'] ?? [];
        }
      }
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        "Error",
        "Error fetching data: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> refreshData() async {
    await fetchIncomeCategories();
  }
}