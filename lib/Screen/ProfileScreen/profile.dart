import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../Controllers/profile_controller.dart';
import '../../User/login.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileController _controller = Get.put(ProfileController());

  @override
  void initState() {
    super.initState();
    // Initialize controller with userId
    _controller.setUserId(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 2,
        shadowColor: Colors.blueAccent.withOpacity(0.3),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _controller.refreshData,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value && !_controller.isRefreshing.value) {
          return _buildLoadingWidget();
        }

        if (_controller.hasError.value) {
          return _buildErrorWidget();
        }

        return _buildProfileWidget();
      }),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
          ),
          SizedBox(height: 16),
          Text(
            "Loading Profile...",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              "Failed to load profile",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _controller.refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileWidget() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return RefreshIndicator(
      onRefresh: _controller.refreshData,
      color: Colors.blueAccent,
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isLargeScreen ? 24 : 20),
        child: Column(
          children: [
            // Profile Image Section
            _buildProfileImageSection(isLargeScreen),
            SizedBox(height: isLargeScreen ? 30 : 20),

            // User Info
            _buildUserInfoSection(isLargeScreen),
            SizedBox(height: isLargeScreen ? 30 : 25),

            // Budget Summary Card
            _buildBudgetSummaryCard(isLargeScreen),
            SizedBox(height: isLargeScreen ? 30 : 25),

            // Action Buttons
            _buildActionButtonsSection(isLargeScreen),
            SizedBox(height: isLargeScreen ? 20 : 15),

            // Additional Info Section
            _buildAdditionalInfoSection(isLargeScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageSection(bool isLargeScreen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: isLargeScreen ? 160 : 130,
            height: isLargeScreen ? 160 : 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.blueAccent,
                  Colors.blueAccent.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Obx(() {
              final hasSelectedImage = _controller.selectedImage.value != null;
              final hasProfileImage = _controller.profileImage.value.isNotEmpty;

              return CircleAvatar(
                radius: isLargeScreen ? 75 : 60,
                backgroundColor: Colors.transparent,
                backgroundImage: hasSelectedImage
                    ? FileImage(File(_controller.selectedImage.value!.path))
                    : hasProfileImage
                    ? NetworkImage(_controller.profileImage.value) as ImageProvider
                    : null,
                child: _controller.userName.isEmpty && !hasSelectedImage && !hasProfileImage
                    ? Icon(
                  Icons.person,
                  size: isLargeScreen ? 60 : 50,
                  color: Colors.white.withOpacity(0.8),
                )
                    : null,
              );
            }),
          ),
          Positioned(
            bottom: 5,
            right: 5,
            child: GestureDetector(
              onTap: () => _showEditProfileDialog(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.blueAccent, width: 2),
                ),
                padding: EdgeInsets.all(isLargeScreen ? 10 : 8),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.blueAccent,
                  size: isLargeScreen ? 22 : 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection(bool isLargeScreen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Column(
        children: [
          Obx(() => Text(
            _controller.userName.value.isNotEmpty
                ? _controller.userName.value
                : "No Name",
            style: TextStyle(
              fontSize: isLargeScreen ? 28 : 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          )),
          SizedBox(height: isLargeScreen ? 12 : 8),
          Obx(() => _buildInfoRow(
            Icons.email_outlined,
            _controller.email.value.isNotEmpty
                ? _controller.email.value
                : "No Email",
            isLargeScreen,
          )),
          SizedBox(height: isLargeScreen ? 8 : 4),
          Obx(() => _buildInfoRow(
            Icons.phone_outlined,
            _controller.phone.value.isNotEmpty
                ? _controller.phone.value
                : "No Mobile",
            isLargeScreen,
          )),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isLargeScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: isLargeScreen ? 18 : 16, color: Colors.grey[600]),
        SizedBox(width: isLargeScreen ? 8 : 6),
        Text(
          text,
          style: TextStyle(
            fontSize: isLargeScreen ? 16 : 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetSummaryCard(bool isLargeScreen) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isLargeScreen ? 25 : 20),
      ),
      elevation: 4,
      shadowColor: Colors.blueAccent.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(isLargeScreen ? 24 : 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_outlined,
                    color: Colors.blueAccent, size: isLargeScreen ? 24 : 20),
                SizedBox(width: isLargeScreen ? 12 : 8),
                Text(
                  "Monthly Summary",
                  style: TextStyle(
                    fontSize: isLargeScreen ? 22 : 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: isLargeScreen ? 20 : 16),
            Container(
              height: 1,
              color: Colors.grey[200],
            ),
            SizedBox(height: isLargeScreen ? 24 : 20),

            // Summary Items
            isLargeScreen ? _buildDesktopSummary() : _buildMobileSummary(),

            SizedBox(height: isLargeScreen ? 20 : 16),

            // Savings Percentage
            Obx(() => Container(
              padding: EdgeInsets.symmetric(
                horizontal: isLargeScreen ? 16 : 12,
                vertical: isLargeScreen ? 12 : 8,
              ),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isLargeScreen ? 15 : 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.savings_outlined,
                      size: isLargeScreen ? 20 : 16,
                      color: Colors.blueAccent),
                  SizedBox(width: isLargeScreen ? 10 : 6),
                  Text(
                    "Savings: ${_controller.savingsPercentage.value.toStringAsFixed(1)}%",
                    style: TextStyle(
                      fontSize: isLargeScreen ? 18 : 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
            child: _buildSummaryItem(
              "Income",
              "₹${_controller.totalIncome.value.toStringAsFixed(0)}",
              Colors.green,
              Icons.arrow_upward,
            )),
        _buildVerticalDivider(),
        Expanded(
            child: _buildSummaryItem(
              "Expense",
              "₹${_controller.totalExpense.value.toStringAsFixed(0)}",
              Colors.orange,
              Icons.arrow_downward,
            )),
        _buildVerticalDivider(),
        Expanded(
            child: _buildSummaryItem(
              "Remaining",
              "₹${_controller.balance.value.toStringAsFixed(0)}",
              Colors.blueAccent,
              Icons.account_balance_wallet,
            )),
      ],
    );
  }

  Widget _buildDesktopSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildDesktopSummaryItem(
          "Income",
          "₹${_controller.totalIncome.value.toStringAsFixed(0)}",
          Colors.green,
          Icons.arrow_upward,
        ),
        _buildDesktopSummaryItem(
          "Expense",
          "₹${_controller.totalExpense.value.toStringAsFixed(0)}",
          Colors.orange,
          Icons.arrow_downward,
        ),
        _buildDesktopSummaryItem(
          "Remaining",
          "₹${_controller.balance.value.toStringAsFixed(0)}",
          Colors.blueAccent,
          Icons.account_balance_wallet,
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
      String title, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDesktopSummaryItem(
      String title, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.grey[300],
    );
  }

  Widget _buildActionButtonsSection(bool isLargeScreen) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showEditProfileDialog(),
            icon: Icon(Icons.edit_outlined, size: isLargeScreen ? 22 : 20),
            label: Text(
              "Edit Profile",
              style: TextStyle(
                fontSize: isLargeScreen ? 18 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: isLargeScreen ? 18 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isLargeScreen ? 18 : 15),
              ),
              elevation: 2,
              shadowColor: Colors.blueAccent.withOpacity(0.3),
            ),
          ),
        ),
        SizedBox(height: isLargeScreen ? 16 : 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showLogoutDialog(),
            icon: Icon(Icons.logout_rounded, size: isLargeScreen ? 22 : 20),
            label: Text(
              "Logout",
              style: TextStyle(
                fontSize: isLargeScreen ? 18 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent, width: 1.5),
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: isLargeScreen ? 18 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isLargeScreen ? 18 : 15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoSection(bool isLargeScreen) {
    return Container(
      padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(isLargeScreen ? 20 : 15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(
            "Account Information",
            style: TextStyle(
              fontSize: isLargeScreen ? 20 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isLargeScreen ? 16 : 12),
          Obx(() => _buildDesktopInfoRow(
            "Member since",
            _controller.memberSince.value.isNotEmpty
                ? _controller.memberSince.value
                : "Not available",
            Icons.calendar_today,
            isLargeScreen,
          )),
          _buildDesktopInfoRow(
            "Account status",
            "Active",
            Icons.verified_outlined,
            isLargeScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopInfoRow(
      String title, String value, IconData icon, bool isLargeScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isLargeScreen ? 12 : 8),
      child: Row(
        children: [
          Icon(icon, size: isLargeScreen ? 22 : 18, color: Colors.blueAccent),
          SizedBox(width: isLargeScreen ? 16 : 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isLargeScreen ? 18 : 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isLargeScreen ? 18 : 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController =
    TextEditingController(text: _controller.userName.value);
    final emailController =
    TextEditingController(text: _controller.email.value);
    final phoneController =
    TextEditingController(text: _controller.phone.value);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.edit, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text("Edit Profile"),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Profile Image
                    GestureDetector(
                      onTap: () => _showImagePickerOptions(setDialogState),
                      child: Obx(() {
                        final hasSelectedImage =
                            _controller.selectedImage.value != null;
                        final hasProfileImage =
                            _controller.profileImage.value.isNotEmpty;

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                Border.all(color: Colors.blueAccent, width: 2),
                              ),
                              child: hasSelectedImage
                                  ? CircleAvatar(
                                backgroundImage: FileImage(File(
                                    _controller.selectedImage.value!.path)),
                                radius: 50,
                              )
                                  : hasProfileImage
                                  ? CircleAvatar(
                                backgroundImage: NetworkImage(
                                    _controller.profileImage.value),
                                radius: 50,
                              )
                                  : CircleAvatar(
                                backgroundColor:
                                Colors.blueAccent.withOpacity(0.1),
                                child: Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    // Form Fields
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person, color: Colors.blueAccent),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email, color: Colors.blueAccent),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        prefixIcon: Icon(Icons.phone, color: Colors.blueAccent),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _controller.clearSelectedImage();
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty ||
                        emailController.text.isEmpty ||
                        phoneController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final updatedData = {
                      'name': nameController.text,
                      'email': emailController.text,
                      'mobile_no': phoneController.text,
                    };

                    await _controller.updateProfile(updatedData);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Update"),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            );
          },
        );
      },
    );
  }

  void _showImagePickerOptions(void Function(void Function()) setDialogState) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _controller.pickImage(ImageSource.gallery);
                  setDialogState(() {});
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _controller.pickImage(ImageSource.camera);
                  setDialogState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text("Logout"),
            ],
          ),
          content: const Text("Are you sure you want to logout?"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }

  void _performLogout() {
    // Clear GetX controllers
    Get.delete<ProfileController>();

    // Navigate to Login Screen
    Get.offAll(() => LoginScreen());

    // Show logout success message
    Get.snackbar(
      'Success',
      'Logged out successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }
}