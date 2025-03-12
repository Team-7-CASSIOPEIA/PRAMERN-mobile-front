import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginController with ChangeNotifier {
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  bool get isPasswordVisible => _isPasswordVisible;
  bool get isLoading => _isLoading;

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<String> login(
    String username,
    String password,
    bool rememberMe,
    BuildContext context,
  ) async {
    // Reset loading state
    setLoading(true);

    final String apiUrl = 'http://localhost:3000/auth/login';

    try {
      // Validate input before making API call
      if (username.trim().isEmpty || password.trim().isEmpty) {
        setLoading(false);
        return 'กรุณากรอกชื่อผู้ใช้และรหัสผ่าน';
      }

      // Make API call
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username.trim(),
          'password': password.trim(),
          'remember': rememberMe,
        }),
      );

      // Handle response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Validate response data
        if (data['accessToken'] == null || data['user']?['id'] == null) {
          setLoading(false);
          return 'ข้อมูลการตอบกลับจากเซิร์ฟเวอร์ไม่ถูกต้อง';
        }

        final String accessToken = data['accessToken'];
        final String userId = data['user']['id'].toString();

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await Future.wait([
          prefs.setString('accessToken', accessToken),
          prefs.setString('user_id', userId),
          if (rememberMe) prefs.setBool('rememberMe', true),
        ]);

        // Log success
        debugPrint('Login successful - User ID: $userId');

        // Navigate to home screen
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }

        return 'เข้าสู่ระบบสำเร็จ';
      } else {
        // Handle error response
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 
            'เกิดข้อผิดพลาดในการเข้าสู่ระบบ (Error ${response.statusCode})';
        return errorMessage;
      }
    } on http.ClientException {
      return 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ กรุณาตรวจสอบการเชื่อมต่อ';
    } on FormatException {
      return 'รูปแบบข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง';
    } catch (error) {
      debugPrint('Login error: $error');
      return 'เกิดข้อผิดพลาด: ${error.toString()}';
    } finally {
      if (context.mounted) {
        setLoading(false);
      }
    }
  }

  // Optional: Method to check if user is already logged in
  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    return accessToken != null;
  }

  // Optional: Method to logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove('accessToken'),
      prefs.remove('user_id'),
      prefs.remove('rememberMe'),
    ]);
    notifyListeners();
  }
}