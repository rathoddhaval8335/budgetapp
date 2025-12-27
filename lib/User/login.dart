import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../Bottomnav/bottomnavigation.dart';
import '../Service/apiservice.dart';
import '../shared_pref/sharedpref_screen.dart';
import 'forgotpassword.dart';
import 'register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  final SharedPrefManager _prefManager = SharedPrefManager();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isAutoLoginLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();

    // Initialize SharedPreferences and check for saved credentials
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _prefManager.init();

    // Check if user is already logged in
    if (await _prefManager.shouldAutoLogin()) {
      _attemptAutoLogin();
    } else {
      // Load saved email if remember me was checked
      _loadSavedCredentials();
    }
  }

  Future<void> _loadSavedCredentials() async {
    setState(() {
      _rememberMe = _prefManager.getRememberMe();
    });

    if (_rememberMe) {
      final savedEmail = _prefManager.getEmail();
      final savedPassword = _prefManager.getPassword();

      if (savedEmail != null) {
        _emailController.text = savedEmail;
      }
      if (savedPassword != null) {
        _passwordController.text = savedPassword;
      }
    }
  }

  Future<void> _attemptAutoLogin() async {
    setState(() {
      _isAutoLoginLoading = true;
    });

    final savedData = _prefManager.getSavedLoginData();
    final savedEmail = savedData['email'];
    final savedPassword = savedData['password'];
    final savedUserId = savedData['userId'];

    // If we have all required data for auto-login
    if (savedEmail != null && savedPassword != null && savedUserId != null) {
      // Try to auto-login
      await _performAutoLogin(savedEmail, savedPassword, savedUserId);
    } else {
      // If auto-login data is incomplete, clear login status
      await _prefManager.clearLoginData();
      setState(() {
        _isAutoLoginLoading = false;
      });
    }
  }

  Future<void> _performAutoLogin(String email, String password, String userId) async {
    try {
      // You could add a quick API call to verify token/session here
      // For simplicity, we'll just navigate directly
      await Future.delayed(const Duration(milliseconds: 500)); // Small delay for UX

      if (mounted) {
        _navigateToHome(userId);
      }
    } catch (e) {
      // If auto-login fails, clear saved data
      await _prefManager.clearLoginData();
      if (mounted) {
        setState(() {
          _isAutoLoginLoading = false;
        });
        _showErrorSnackBar('Auto-login failed. Please login manually.');
      }
    }
  }

  Future<void> loginUser(String email, String password) async {
    if (_isLoading) return;

    // Unfocus keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(ApiService.getUrl("fd_login.php"));
    try {
      final response = await http.post(
        url,
        body: {
          "email": email.trim(),
          "password": password.trim(),
        },
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        try {
          final jsonResponse = json.decode(response.body.trim());

          if (jsonResponse['status'] == true) {
            // Get userId
            String userId = jsonResponse['data']['id'].toString();
            String? userName = jsonResponse['data']['name']?.toString();

            // Save credentials to SharedPreferences
            await _prefManager.saveLoginCredentials(
              userId: userId,
              email: email,
              password: _rememberMe ? password : null,
              rememberMe: _rememberMe,
              userName: userName,
            );

            // Navigate to BottomNav with userId
            _navigateToHome(userId);
          } else {
            _showErrorSnackBar(jsonResponse['message'] ?? 'Invalid credentials');
          }
        } catch (e) {
          _showErrorSnackBar('Invalid server response format');
        }
      } else {
        _showErrorSnackBar('Server error: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      _showErrorSnackBar('Network error: ${e.message}');
    } on Exception catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToHome(String userId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BottomNav(userId: userId),
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

  @override
  Widget build(BuildContext context) {
    // Show loading screen for auto-login
    if (_isAutoLoginLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FBFF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
              ),
              const SizedBox(height: 20),
              Text(
                'Auto-logging in...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isLandscape = screenHeight < 500;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (isLandscape) {
              return _buildLandscapeLayout(isSmallScreen, keyboardVisible);
            }
            return _buildPortraitLayout(isSmallScreen, keyboardVisible);
          },
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(bool isSmallScreen, bool keyboardVisible) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 14 : 20,
        vertical: keyboardVisible ? 8 : 12,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: IntrinsicHeight(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!keyboardVisible) ...[
                // Header Section
                _buildHeader(isSmallScreen),
                SizedBox(height: isSmallScreen ? 20 : 28),
              ],

              // Login Form - Expanded हटा दिया
              _buildLoginForm(isSmallScreen),

              // Remember Me & Forgot Password
              if (!keyboardVisible) ...[
                SizedBox(height: isSmallScreen ? 12 : 16),
                _buildRememberForgot(isSmallScreen),
              ],

              // Login Button
              SizedBox(height: isSmallScreen ? 16 : 24),
              _buildLoginButton(isSmallScreen),

              // Register Link
              if (!keyboardVisible) ...[
                SizedBox(height: isSmallScreen ? 12 : 16),
                _buildRegisterLink(isSmallScreen),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildLandscapeLayout(bool isSmallScreen, bool keyboardVisible) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!keyboardVisible) ...[
            Expanded(
              flex: 1,
              child: _buildHeader(true),
            ),
            const SizedBox(width: 32),
          ],
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLoginForm(true),
                if (!keyboardVisible) ...[
                  const SizedBox(height: 20),
                  _buildRememberForgot(true),
                ],
                const SizedBox(height: 24),
                _buildLoginButton(true),
                if (!keyboardVisible) ...[
                  const SizedBox(height: 20),
                  _buildRegisterLink(true),
                ],
              ],
            ),
          ),
        ],
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
          'Welcome Back',
          style: TextStyle(
            fontSize: isSmallScreen ? 22 : 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1976D2),
            height: 1.2,
          ),
        ),
        SizedBox(height: isSmallScreen ? 4 : 8),
        Text(
          'Sign in to continue managing your budget',
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

  Widget _buildLoginForm(bool isSmallScreen) {
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
          mainAxisSize: MainAxisSize.min,
          children: [
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
            SizedBox(height: isSmallScreen ? 16 : 20),

            // Password Field
            _buildPasswordField(
              controller: _passwordController,
              label: 'Password',
              hintText: 'Enter your password',
              isPassword: _obscurePassword,
              onToggle: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
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

  Widget _buildRememberForgot(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Remember Me Checkbox
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: isSmallScreen ? 0.9 : 1.0,
                ),
              ],
            ),
          ),

          // Forgot Password
          Flexible(
            child: GestureDetector(
              onTap: _isLoading
                  ? null
                  : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: _isLoading ? Colors.grey : const Color(0xFF2196F3),
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 48 : 56,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () {
          if (_formKey.currentState!.validate()) {
            loginUser(
              _emailController.text,
              _passwordController.text,
            );
          }
        },
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
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Text(
          'Sign In',
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink(bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(
            color: Colors.grey,
            fontSize: isSmallScreen ? 14 : 16,
          ),
        ),
        GestureDetector(
          onTap: _isLoading
              ? null
              : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const RegisterScreen()),
            );
          },
          child: Text(
            'Sign Up',
            style: TextStyle(
              color: _isLoading ? Colors.grey : const Color(0xFF2196F3),
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}