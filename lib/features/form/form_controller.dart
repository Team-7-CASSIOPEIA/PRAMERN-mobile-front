import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FormController {
  Future<Map<String, dynamic>?> fetchFormData(String formId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString('accessToken');

    if (accessToken == null) return null;

    final String apiUrl = '${dotenv.env['API_URL']}/api/form/$formId'; // Adjust API URL

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
        return data;
      } else {
        // Handle the case where the response status is not 200
        return null;
      }
    } catch (e) {
      print('Error fetching form data: $e');
      return null;
    }
  }

  Future<bool> submitForm(String assignId, String assigneeId, Map<String, dynamic> formData) async {
    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString('accessToken');

    if (accessToken == null) return false;

    final String apiUrl = '${dotenv.env['API_URL']}/api/sent-assignment/$assignId?assignee_id=$assigneeId'; 

    try {


      final String jsonBody = jsonEncode(formData);
      debugPrint('Form Data: $jsonBody');
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/x-www-form-urlencoded',        },
        body: {
          'data': jsonBody
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        // Handle the case where the response status is not 200
        return false;
      }
    } catch (e) {
      print('Error submitting form: $e');
      return false;
    }
  }

}