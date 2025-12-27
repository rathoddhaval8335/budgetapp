import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../Service/apiservice.dart';

class ProfileController extends GetxController {
  // User Data
  final RxString userName = ''.obs;
  final RxString email = ''.obs;
  final RxString phone = ''.obs;
  final RxString profileImage = ''.obs;
  final RxString memberSince = ''.obs;

  // Financial Data
  final RxInt totalExpense = 0.obs;
  final RxInt totalIncome = 0.obs;
  final RxInt balance = 0.obs;
  final RxDouble savingsPercentage = 0.0.obs;

  // States
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isRefreshing = false.obs;

  // Date & Image
  final RxString year = DateFormat('yyyy').format(DateTime.now()).obs;
  final RxString month = DateFormat('MMM').format(DateTime.now()).toUpperCase().obs;
  final RxString monthNumber = DateFormat('MM').format(DateTime.now()).obs;
  final Rx<XFile?> selectedImage = Rx<XFile?>(null);

  // User ID - Simple variable
  late String userId;

  // Set User ID Method
  void setUserId(String id) {
    userId = id;
    fetchAllData();
  }

  // Fetch all data
  Future<void> fetchAllData() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      await Future.wait([
        fetchUserData(),
        fetchTotals(),
        fetchUserSince(),
      ]);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load data: $e';
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  // Refresh data
  Future<void> refreshData() async {
    isRefreshing.value = true;
    await fetchAllData();
  }

  // Fetch user data
  Future<void> fetchUserData() async {
    try {
      final response = await http.post(
        Uri.parse(ApiService.getUrl("fd_profile.php")),
        body: {'userid': userId},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'success') {
          userName.value = data['data']['name'] ?? "No Name";
          email.value = data['data']['email'] ?? "No Email";
          phone.value = data['data']['mobile_no'] ?? "No Mobile";
          profileImage.value = data['data']['profile_image'] ?? "";
        } else {
          throw Exception(data['message'] ?? "Unknown error occurred");
        }
      } else {
        throw Exception("Failed to load data. Status code: ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

  // Fetch totals
  Future<void> fetchTotals() async {
    try {
      final expense = await fetchTotalExpense();
      final income = await fetchTotalIncome();

      totalExpense.value = expense;
      totalIncome.value = income;
      balance.value = income - expense;

      // Calculate savings percentage
      if (totalIncome.value > 0) {
        savingsPercentage.value = (balance.value / totalIncome.value * 100);
      } else {
        savingsPercentage.value = 0.0;
      }
    } catch (e) {
      rethrow;
    }
  }

  // Fetch total expense
  Future<int> fetchTotalExpense() async {
    try {
      final response = await http.post(
        Uri.parse(ApiService.getUrl("total_exp_month.php")),
        body: {
          "user_id": userId,
          "month": monthNumber.value,
          "year": year.value,
        },
      );

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['status'] == 'success') {
        return (double.tryParse(jsonResponse['total'].toString()) ?? 0).toInt();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Fetch total income
  Future<int> fetchTotalIncome() async {
    try {
      final response = await http.post(
        Uri.parse(ApiService.getUrl("total_income_month.php")),
        body: {
          "user_id": userId,
          "month": monthNumber.value,
          "year": year.value,
        },
      );

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['status'] == 'success') {
        return (double.tryParse(jsonResponse['total'].toString()) ?? 0).toInt();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Fetch user since
  Future<void> fetchUserSince() async {
    try {
      final response = await http.post(
        Uri.parse(ApiService.getUrl("fd_user_since.php")),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final user = data.firstWhere(
              (u) => u['id'].toString() == userId,
          orElse: () => null,
        );

        if (user != null) {
          memberSince.value = user['formatted_date'] ?? "Not available";
        }
      }
    } catch (e) {
      memberSince.value = "Not available";
    }
  }

  // Update profile
  Future<void> updateProfile(Map<String, String> updatedData) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiService.getUrl("profile_edit.php")),
      );

      request.fields['id'] = userId;
      request.fields['name'] = updatedData['name']!;
      request.fields['email'] = updatedData['email']!;
      request.fields['mobile_no'] = updatedData['mobile_no']!;

      if (selectedImage.value != null) {
        final file = await http.MultipartFile.fromPath(
          'profile_image',
          selectedImage.value!.path,
        );
        request.files.add(file);
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final result = json.decode(responseData);

      if (response.statusCode == 200 && result['success'] == true) {
        // Update local data
        userName.value = updatedData['name']!;
        email.value = updatedData['email']!;
        phone.value = updatedData['mobile_no']!;

        if (result['image_url'] != null) {
          profileImage.value = result['image_url'];
        }

        selectedImage.value = null;

        Get.snackbar(
          'Success',
          result['message'] ?? 'Profile updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Refresh data
        fetchAllData();
      } else {
        throw Exception(result['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update profile: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Pick image
  Future<void> pickImage(ImageSource source) async {
    try {
      final imagePicker = ImagePicker();
      final pickedImage = await imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedImage != null) {
        selectedImage.value = pickedImage;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Clear selected image
  void clearSelectedImage() {
    selectedImage.value = null;
  }
}