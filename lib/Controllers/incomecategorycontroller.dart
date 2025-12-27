import 'dart:convert';
import 'package:budgetapp/Service/apiservice.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class IncomeCategoryController extends GetxController {
  final String userId;
  IncomeCategoryController(this.userId);

  var categories = <dynamic>[].obs;
  var isLoading = true.obs;

  var isDeleting = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;
      update(); // Notify UI to show loading

      String apiUrl = ApiService.getUrl("fd_view_income.php");

      var response = await http.post(
          Uri.parse(apiUrl),
          body: {"userid": userId}
      );

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);

        if (jsonData['status'] == "success") {
          categories.value = jsonData['data'] ?? [];
        } else {
          categories.value = [];
          Get.snackbar(
            "Info",
            jsonData['message'] ?? "No income categories found",
            backgroundColor: Colors.blue,
            colorText: Colors.white,
          );
        }
      } else {
        categories.value = [];
        Get.snackbar(
          "Error",
          "Server error: ${response.statusCode}",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
      isLoading.value = false;
      update(); // Notify UI that loading is complete

    } catch (e) {
      print("Error fetching income categories: $e");
      isLoading.value = false;
      update(); // Notify UI that loading failed

      Get.snackbar(
        "Error",
        "Error fetching income categories: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    }
  }

  // Future<void> deleteCategory(String id) async {
  //   try {
  //     String apiUrl = ApiService.getUrl("fd_delete_income.php");
  //
  //     var response = await http.post(
  //       Uri.parse(apiUrl),
  //       body: {
  //         "id": id,
  //         "userid": userId,
  //       },
  //     );
  //
  //     if (response.statusCode == 200) {
  //       var jsonData = jsonDecode(response.body);
  //
  //       if (jsonData['status'] == "success") {
  //         Get.snackbar(
  //           "Success",
  //           "Income category deleted successfully",
  //           backgroundColor: Colors.green,
  //           colorText: Colors.white,
  //         );
  //
  //         await fetchCategories(); // refresh list
  //       } else {
  //         Get.snackbar(
  //           "Error",
  //           jsonData['message'] ?? "Delete failed",
  //           backgroundColor: Colors.red,
  //           colorText: Colors.white,
  //         );
  //       }
  //     } else {
  //       Get.snackbar(
  //         "Error",
  //         "Server error: ${response.statusCode}",
  //         backgroundColor: Colors.red,
  //         colorText: Colors.white,
  //       );
  //     }
  //   } catch (e) {
  //     Get.snackbar(
  //       "Error",
  //       "Server error: $e",
  //       backgroundColor: Colors.red,
  //       colorText: Colors.white,
  //     );
  //   }
  // }

  Future<void> deleteCategory(String id) async {
    try {
      isDeleting.value = true; // Start deleting

      String apiUrl = ApiService.getUrl("fd_delete_income.php");

      var response = await http.post(
        Uri.parse(apiUrl),
        body: {
          "id": id,
          "userid": userId,
        },
      );

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);

        if (jsonData['status'] == "success") {
          await fetchCategories(); // refresh list
        } else {
          Get.snackbar(
            "Error",
            jsonData['message'] ?? "Delete failed",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          "Error",
          "Server error: ${response.statusCode}",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Server error: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isDeleting.value = false; // Stop deleting
    }
  }


  Future<void> refreshData() async {
    await fetchCategories();
  }

  // Optional: Add a new category
  Future<void> addCategory(String name, String iconCode) async {
    try {
      isLoading.value = true;
      update();

      String apiUrl = ApiService.getUrl("fd_insert_income.php");

      var response = await http.post(
        Uri.parse(apiUrl),
        body: {
          "userid": userId,
          "cat_icon": iconCode,
          "cat_name": name,
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data['status'] == "success") {
          await fetchCategories(); // Refresh list
        } else {
          Get.snackbar(
            "Error",
            data['message'] ?? "Failed to add category",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          "Error",
          "Server error: ${response.statusCode}",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }

      isLoading.value = false;
      update();

    } catch (e) {
      isLoading.value = false;
      update();

      Get.snackbar(
        "Error",
        "Error adding category: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Get category by ID
  Map<String, dynamic>? getCategoryById(String id) {
    try {
      return categories.firstWhere(
            (cat) => cat['id'].toString() == id,
        orElse: () => null,
      );
    } catch (e) {
      return null;
    }
  }

  // Get category count
  int getCategoryCount() {
    return categories.length;
  }

  // Check if category exists
  bool categoryExists(String name) {
    return categories.any((cat) =>
    cat['cat_name'].toString().toLowerCase() == name.toLowerCase()
    );
  }

  // Clear all data (for logout or reset)
  void clearData() {
    categories.clear();
    isLoading.value = true;
    update();
  }
}