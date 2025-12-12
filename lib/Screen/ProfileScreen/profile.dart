import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../User/login.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // User data variables
  String userName = "";
  String email = "";
  String phone = "";
  String profileImage = "";
  String year = DateFormat('yyyy').format(DateTime.now());
  String month = DateFormat('MMM').format(DateTime.now()).toUpperCase();
  String monthNumber = DateFormat('MM').format(DateTime.now()); // Add this for month number
  int totalExpense = 0;
  int totalIncome = 0;
  int balance = 0;

  bool isLoading = true;
  bool hasError = false;
  String errorMessage = "";
  String? memberSince;
  Future<void> _fetchUserSince() async {
    final response = await http.post(
      Uri.parse("http://192.168.43.192/BUDGET_APP/fd_user_since.php"), // your PHP URL
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      // Find the logged-in user's record (match by ID)
      var user = data.firstWhere(
            (u) => u['id'].toString() == widget.userId,
        orElse: () => null,
      );

      if (user != null) {
        setState(() {
          memberSince = user['formatted_date'];
        });
      }
    }
  }
  String getCurrentMonth() {
    return DateFormat('MMM').format(DateTime.now()).toUpperCase();
  }
  Future<int> fetchTotalExpense(String userId) async {
    try {
      var response = await http.post(
        Uri.parse("http://192.168.43.192/BUDGET_APP/total_exp_month.php"),
        body: {
          "user_id": userId,
          "month": monthNumber, // Add month parameter
          "year": year, // Add year parameter
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
        Uri.parse("http://192.168.43.192/BUDGET_APP/total_income_month.php"),
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
      isLoading = true;
    });
    int expense = await fetchTotalExpense(widget.userId);
    int income = await fetchTotalIncome(widget.userId);

    setState(() {
      totalExpense = expense;
      totalIncome = income;
      balance = income - expense;
      isLoading = false;
    });
  }
  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchTotals();
    _fetchUserSince();
  }

  // Function to fetch user data from API
  Future<void> _fetchUserData() async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.43.192/BUDGET_APP/fd_profile.php'),
        body: {
          'userid': widget.userId,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'success') {
          setState(() {
            userName = data['data']['name'] ?? "No Name";
            email = data['data']['email'] ?? "No Email";
            phone = data['data']['mobile_no'] ?? "No Mobile";
            profileImage = data['data']['profile_image'] ?? "";
            isLoading = false;
          });
        } else {
          setState(() {
            hasError = true;
            errorMessage = data['message'] ?? "Unknown error occurred";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          hasError = true;
          errorMessage = "Failed to load data. Status code: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = "Network error: $e";
        isLoading = false;
      });
    }
  }

  // Function to update profile data
  Future<void> _updateProfileData(Map<String, String> updatedData) async {
    try {
      // Create multipart request for image upload
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.43.192/BUDGET_APP/profile_edit.php'),
      );

      // Add all fields
      request.fields['id'] = widget.userId;
      request.fields['name'] = updatedData['name']!;
      request.fields['email'] = updatedData['email']!;
      request.fields['mobile_no'] = updatedData['mobile_no']!;

      // Add image if selected
      if (_selectedImage != null) {
        var file = await http.MultipartFile.fromPath(
          'profile_image',
          _selectedImage!.path,
        );
        request.files.add(file);
      }

      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var result = json.decode(responseData);

      if (response.statusCode == 200) {
        if (result['success'] == true) {
          // Update local state with new data
          setState(() {
            userName = updatedData['name']!;
            email = updatedData['email']!;
            phone = updatedData['mobile_no']!;
            if (result['image_url'] != null) {
              profileImage = result['image_url'];
            }
            _selectedImage = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh data
          _fetchUserData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to update profile'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server error: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to show edit profile dialog
  void _showEditProfileDialog() {
    final TextEditingController nameController = TextEditingController(text: userName);
    final TextEditingController emailController = TextEditingController(text: email);
    final TextEditingController phoneController = TextEditingController(text: phone);

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
                    // Profile Image Section
                    GestureDetector(
                      onTap: () async {
                        await _pickImage(setDialogState);
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.blueAccent, width: 2),
                            ),
                            child: _selectedImage != null
                                ? CircleAvatar(
                              backgroundImage: FileImage(File(_selectedImage!.path)),
                              radius: 50,
                            )
                                : profileImage.isNotEmpty
                                ? CircleAvatar(
                              backgroundImage: NetworkImage(profileImage),
                              radius: 50,
                            )
                                : CircleAvatar(
                              backgroundColor: Colors.blueAccent.withOpacity(0.1),
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
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Name Field
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

                    // Email Field
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

                    // Phone Field
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
                    _selectedImage = null;
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

                    Map<String, String> updatedData = {
                      'name': nameController.text,
                      'email': emailController.text,
                      'mobile_no': phoneController.text,
                    };

                    await _updateProfileData(updatedData);
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

  // Function to pick image from gallery or camera
  Future<void> _pickImage(void Function(void Function()) setDialogState) async {
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
                  final XFile? image = await _imagePicker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    setDialogState(() {
                      _selectedImage = image;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await _imagePicker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    setDialogState(() {
                      _selectedImage = image;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Rest of your build methods remain the same...
  @override
  Widget build(BuildContext context) {
    double remaining = (totalIncome - totalExpense).toDouble();
    double savingsPercentage = totalIncome > 0 ? (remaining / totalIncome * 100) : 0;


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
            onPressed: _fetchUserData,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: isLoading
          ? _buildLoadingWidget()
          : hasError
          ? _buildErrorWidget()
          : _buildProfileWidget(remaining, savingsPercentage),
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
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchUserData,
              icon: Icon(Icons.refresh),
              label: Text("Try Again"),
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

  Widget _buildProfileWidget(double remaining, double savingsPercentage) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Image Section
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 130,
                  height: 130,
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
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.transparent,
                    backgroundImage: profileImage.isNotEmpty
                        ? NetworkImage(profileImage) as ImageProvider
                        : const AssetImage('assets/your_image.png'),
                    child: userName.isEmpty && profileImage.isEmpty
                        ? Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white.withOpacity(0.8),
                    )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () {
                      _showEditProfileDialog();
                    },
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
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.blueAccent,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // User Info
          Container(
            margin: const EdgeInsets.only(bottom: 25),
            child: Column(
              children: [
                Text(
                  userName.isNotEmpty ? userName : "No Name",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.email_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      email.isNotEmpty ? email : "No Email",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      phone.isNotEmpty ? phone : "No Mobile",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Budget Summary Card
          Container(
            margin: const EdgeInsets.only(bottom: 30),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 4,
              shadowColor: Colors.blueAccent.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics_outlined, color: Colors.blueAccent),
                        SizedBox(width: 8),
                        Text(
                          "Monthly Summary",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      color: Colors.grey[200],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryItem("Income", "₹${totalIncome.toStringAsFixed(0)}", Colors.green, Icons.arrow_upward),
                        _buildVerticalDivider(),
                        _buildSummaryItem("Expense", "₹${totalExpense.toStringAsFixed(0)}", Colors.orange, Icons.arrow_downward),
                        _buildVerticalDivider(),
                        _buildSummaryItem("Remaining", "₹${remaining.toStringAsFixed(0)}", Colors.blueAccent, Icons.account_balance_wallet),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Savings Percentage
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.savings_outlined, size: 16, color: Colors.blueAccent),
                          const SizedBox(width: 6),
                          Text(
                            "Savings: ${savingsPercentage.toStringAsFixed(1)}%",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Action Buttons
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 15),
            child: ElevatedButton.icon(
              onPressed: _showEditProfileDialog,
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: const Text(
                "Edit Profile",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 2,
                shadowColor: Colors.blueAccent.withOpacity(0.3),
              ),
            ),
          ),

          Container(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _showLogoutDialog(context);
              },
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text(
                "Logout",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),

          // Additional Info Section
          Container(
            margin: const EdgeInsets.only(top: 30),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                const Text(
                  "Account Information",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow("Member since", memberSince!, Icons.calendar_today),
                _buildInfoRow("Account status", "Active", Icons.verified_outlined),
                _buildInfoRow("Last login", "2 hours ago", Icons.access_time_filled),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Column(
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
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.grey[300],
    );
  }

  Widget _buildInfoRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
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
                _performLogout(context);
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

// ✅ Simple Logout function
  void _performLogout(BuildContext context) {
    // 1. Close the dialog
    Navigator.of(context).pop();

    // 2. Navigate directly to Login Screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false, // Remove all previous routes
    );

    // 3. Show logout success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Logged out successfully"),
        backgroundColor: Colors.green,
      ),
    );
  }
}