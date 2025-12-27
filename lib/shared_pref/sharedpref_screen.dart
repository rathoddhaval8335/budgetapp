import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefManager {
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUserId = 'userId';
  static const String _keyEmail = 'email';
  static const String _keyPassword = 'password';
  static const String _keyRememberMe = 'rememberMe';
  static const String _keyUserName = 'userName';

  // Singleton instance
  static SharedPrefManager? _instance;
  static SharedPreferences? _prefs;

  SharedPrefManager._internal();

  factory SharedPrefManager() {
    return _instance ??= SharedPrefManager._internal();
  }

  // Initialize SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Check if SharedPreferences is initialized
  bool get isInitialized => _prefs != null;

  // Login Status Methods
  Future<bool> setLoggedIn(bool value) async {
    if (!isInitialized) await init();
    return await _prefs!.setBool(_keyIsLoggedIn, value);
  }

  bool getLoggedIn() {
    if (!isInitialized) return false;
    return _prefs!.getBool(_keyIsLoggedIn) ?? false;
  }

  // User ID Methods
  Future<bool> setUserId(String userId) async {
    if (!isInitialized) await init();
    return await _prefs!.setString(_keyUserId, userId);
  }

  String? getUserId() {
    if (!isInitialized) return null;
    return _prefs!.getString(_keyUserId);
  }

  // User Name Methods
  Future<bool> setUserName(String name) async {
    if (!isInitialized) await init();
    return await _prefs!.setString(_keyUserName, name);
  }

  String? getUserName() {
    if (!isInitialized) return null;
    return _prefs!.getString(_keyUserName);
  }

  // Email Methods
  Future<bool> setEmail(String email) async {
    if (!isInitialized) await init();
    return await _prefs!.setString(_keyEmail, email);
  }

  String? getEmail() {
    if (!isInitialized) return null;
    return _prefs!.getString(_keyEmail);
  }

  // Password Methods (only when Remember Me is checked)
  Future<bool> setPassword(String password) async {
    if (!isInitialized) await init();
    return await _prefs!.setString(_keyPassword, password);
  }

  String? getPassword() {
    if (!isInitialized) return null;
    return _prefs!.getString(_keyPassword);
  }

  // Remember Me Methods
  Future<bool> setRememberMe(bool value) async {
    if (!isInitialized) await init();
    return await _prefs!.setBool(_keyRememberMe, value);
  }

  bool getRememberMe() {
    if (!isInitialized) return false;
    return _prefs!.getBool(_keyRememberMe) ?? false;
  }

  // Save login credentials
  Future<void> saveLoginCredentials({
    required String userId,
    required String email,
    String? password,
    bool rememberMe = false,
    String? userName,
  }) async {
    await setLoggedIn(true);
    await setUserId(userId);
    await setEmail(email);

    if (userName != null) {
      await setUserName(userName);
    }

    if (rememberMe && password != null) {
      await setRememberMe(true);
      await setPassword(password);
    } else {
      await setRememberMe(false);
      await _prefs!.remove(_keyPassword);
    }
  }

  // Clear all saved data (logout)
  Future<void> clearAllData() async {
    if (!isInitialized) await init();
    await _prefs!.clear();
  }

  // Clear only login data but keep other preferences if needed
  Future<void> clearLoginData() async {
    if (!isInitialized) await init();
    await _prefs!.remove(_keyIsLoggedIn);
    await _prefs!.remove(_keyUserId);
    await _prefs!.remove(_keyEmail);
    await _prefs!.remove(_keyPassword);
    await _prefs!.remove(_keyRememberMe);
    await _prefs!.remove(_keyUserName);
  }

  // Check if user should auto-login
  Future<bool> shouldAutoLogin() async {
    if (!isInitialized) await init();
    return getLoggedIn() && getUserId() != null;
  }

  // Get saved login data for auto-login
  Map<String, String?> getSavedLoginData() {
    return {
      'email': getEmail(),
      'password': getPassword(),
      'userId': getUserId(),
      'userName': getUserName(),
    };
  }
}