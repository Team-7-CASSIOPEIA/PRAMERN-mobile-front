import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomeController {

  Future<Map<String, String>?> fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('user_id');
    final String? accessToken = prefs.getString('accessToken');
    
    if (userId == null || accessToken == null) return null;

    final String apiUrl = '${dotenv.env['API_URL']}/api/user/$userId';  // Adjust API URL

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
        

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'first_name': data['user_fname'] ?? '',
          'last_name': data['user_lname'] ?? '',
          'profile_picture': data['user_img'] ?? '',
        };
      }
    } catch (e) {
      print(e);
      return null;
    }
  }
}