import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../Service/apiservice.dart';
import '../shared_pref/sharedpref_screen.dart';
import 'login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _phoneController;
  final SharedPrefManager _prefManager = SharedPrefManager();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _phoneController = TextEditingController();

    // Initialize SharedPreferences
    _prefManager.init();
  }

  Future<void> _registerUser() async {
    if (_isLoading || !(_formKey.currentState?.validate() ?? false)) return;

    // Unfocus keyboard before API call
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(ApiService.getUrl("fd_register.php"));

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "name": _nameController.text.trim(),
          "email": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
          "mobile_no": _phoneController.text.trim(),
        },
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      await _handleResponse(response);
    } on http.ClientException catch (e) {
      _showErrorSnackBar("Network error: ${e.message}");
    } on Exception catch (e) {
      _showErrorSnackBar("Error: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleResponse(http.Response response) async {
    if (response.statusCode == 200) {
      final cleanedResponse = response.body.trim();
      try {
        final data = jsonDecode(cleanedResponse);
        if (data["success"] == true) {
          // If registration is successful, save user data
          final userId = data["user_id"]?.toString() ?? data["id"]?.toString();
          if (userId != null) {
            await _prefManager.setUserId(userId);
            await _prefManager.setEmail(_emailController.text.trim());
            await _prefManager.setUserName(_nameController.text.trim());
          }

          _showSuccessSnackBar(
              data["message"] ?? "Registration successful");
          _navigateToLogin();
        } else {
          _showErrorSnackBar(data["message"] ?? "Registration failed");
        }
      } catch (e) {
        _showErrorSnackBar("Invalid server response format!");
      }
    } else {
      _showErrorSnackBar("Server error! Status: ${response.statusCode}");
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _navigateToLogin() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isLandscape = screenHeight < 500;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (isLandscape) {
              return _buildLandscapeLayout();
            }
            return _buildPortraitLayout(isSmallScreen, constraints.maxWidth);
          },
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(bool isSmallScreen, double maxWidth) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: 16,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: IntrinsicHeight(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Section
              _buildHeader(isSmallScreen),
              SizedBox(height: isSmallScreen ? 24 : 32),

              // Registration Form
              Expanded(
                child: _buildRegistrationForm(isSmallScreen),
              ),

              // Register Button
              SizedBox(height: isSmallScreen ? 24 : 32),
              _buildRegisterButton(isSmallScreen),

              // Login Link
              SizedBox(height: isSmallScreen ? 16 : 24),
              _buildLoginLink(),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: _buildHeader(true),
            ),
            const SizedBox(width: 32),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildRegistrationForm(true),
                  const SizedBox(height: 24),
                  _buildRegisterButton(true),
                  const SizedBox(height: 16),
                  _buildLoginLink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isSmallScreen ? 60 : 80,
          height: isSmallScreen ? 60 : 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.account_balance_wallet,
            color: Colors.white,
            size: isSmallScreen ? 30 : 40,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 20),
        Text(
          'Create Account',
          style: TextStyle(
            fontSize: isSmallScreen ? 22 : 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1976D2),
            height: 1.2,
          ),
        ),
        SizedBox(height: isSmallScreen ? 4 : 8),
        Text(
          'Sign up to start managing your budget',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: Colors.grey,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRegistrationForm(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Name Field
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              hintText: 'Enter your full name',
              prefixIcon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
              isSmallScreen: isSmallScreen,
            ),
            SizedBox(height: isSmallScreen ? 12 : 20),

            // Email Field
            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              hintText: 'Enter your email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
              isSmallScreen: isSmallScreen,
            ),
            SizedBox(height: isSmallScreen ? 12 : 20),

            // Password Field
            _buildPasswordField(
              controller: _passwordController,
              label: 'Password',
              hintText: 'Create a password',
              isPassword: _obscurePassword,
              onToggle: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
              isSmallScreen: isSmallScreen,
            ),
            SizedBox(height: isSmallScreen ? 12 : 20),

            // Confirm Password Field
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              hintText: 'Confirm your password',
              isPassword: _obscureConfirmPassword,
              onToggle: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              isSmallScreen: isSmallScreen,
            ),
            SizedBox(height: isSmallScreen ? 12 : 20),

            // Phone Number Field
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hintText: 'Enter your phone number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (!RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$')
                    .hasMatch(value)) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
              isSmallScreen: isSmallScreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData prefixIcon,
    required bool isSmallScreen,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1976D2),
            height: 1.2,
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: TextStyle(
              color: Colors.black87,
              fontSize: isSmallScreen ? 14 : 16,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: isSmallScreen ? 14 : 16,
              ),
              prefixIcon: Icon(
                prefixIcon,
                color: const Color(0xFF2196F3),
                size: isSmallScreen ? 20 : 24,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 14 : 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required bool isPassword,
    required VoidCallback onToggle,
    required String? Function(String?)? validator,
    required bool isSmallScreen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1976D2),
            height: 1.2,
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword,
            validator: validator,
            style: TextStyle(
              color: Colors.black87,
              fontSize: isSmallScreen ? 14 : 16,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: isSmallScreen ? 14 : 16,
              ),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: const Color(0xFF2196F3),
                size: isSmallScreen ? 20 : 24,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  isPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF2196F3),
                  size: isSmallScreen ? 20 : 24,
                ),
                onPressed: onToggle,
                splashRadius: isSmallScreen ? 18 : 24,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 14 : 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton(bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 48 : 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _registerUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor: Colors.blue.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 15),
          ),
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 12 : 16,
          ),
        ),
        child: _isLoading
            ? SizedBox(
          height: isSmallScreen ? 18 : 20,
          width: isSmallScreen ? 18 : 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Text(
          'Create Account',
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            color: Colors.grey,
            fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
          ),
        ),
        GestureDetector(
          onTap: _isLoading
              ? null
              : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          },
          child: Text(
            'Sign In',
            style: TextStyle(
              color: _isLoading ? Colors.grey : const Color(0xFF2196F3),
              fontWeight: FontWeight.w600,
              fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}