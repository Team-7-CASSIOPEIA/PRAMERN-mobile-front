import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginController with ChangeNotifier {
  bool _isPasswordVisible = false;

  bool get isPasswordVisible => _isPasswordVisible;

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

Future<String> login(String username, String password, bool rememberMe, BuildContext context) async {
  final String apiUrl = 'http://localhost:3000/auth/login';
  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password, 'remember': rememberMe}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final String accessToken = data['accessToken'];
      final String userId = data['user']['id'].toString();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', accessToken);
      await prefs.setString('user_id', userId);
      print('เข้าสู่ระบบสำเร็จ');
      // Redirect to home screen
      Navigator.pushReplacementNamed(context, '/home');
      
      return 'เข้าสู่ระบบสำเร็จ';
    } else {
      final errorMessage = jsonDecode(response.body)['message'] ?? 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ';
      return errorMessage;
    }
  } catch (error) {
    return 'เกิดข้อผิดพลาดในการเชื่อมต่อกับเซิร์ฟเวอร์';
  }
}
}