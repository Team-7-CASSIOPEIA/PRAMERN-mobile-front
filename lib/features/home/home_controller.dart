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

    final String apiUrl = '${dotenv.env['API_URL']}/api/user/$userId';

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
    return null;
  }

  Future<List<Map<String, dynamic>>?> fetchEvaluationData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('user_id');
    final String? accessToken = prefs.getString('accessToken');

    if (userId == null || accessToken == null) return null;

    final String apiUrl =
        '${dotenv.env['API_URL']}/api/assigns/$userId';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> assignData = jsonDecode(response.body);
        List<Map<String, dynamic>> assignItems = [];

        for (var assign in assignData) {
          final evalId = assign['eval_id'];
          final formId = assign['form_id'];

          for (var assignee in assign['assignees']) {
            if (assign['assessor']['_id'] == userId) {
              assignItems.add({
                'assign_id': assign['_id'],
                'eval_id': evalId['_id'],
                'eval_name': evalId['eval_name'],
                'eval_template_id': formId['_id'],
                'eval_template': formId['form_name'],
                'assignee':
                    '${assignee['assignee']['user_fname']} ${assignee['assignee']['user_lname']}',
                'assignee_id': assignee['assignee']['_id'],
                'assign_status': assignee['status'],
                'round_number': assign['round_number'],
                'is_available': assign['isAvailable'],
              });
            }
          }
        }

        return assignItems;
      } else {
        return [];
      }
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('accessToken');
  }
}
