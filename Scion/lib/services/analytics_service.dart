import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/analytics.dart';

class AnalyticsService {
  static const String baseUrl =
      'https://9qcb6b3j-8000.inc1.devtunnels.ms/api/analytics/';
  final String? token;

  AnalyticsService({this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Token $token',
  };

  // Get user activity
  Future<List<UserActivity>> getUserActivities(int userId) async {
    final url = Uri.parse('${baseUrl}activities/?user=$userId');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => UserActivity.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load user activities');
    }
  }

  // Get user progress
  Future<List<UserProgress>> getUserProgress(int userId) async {
    final url = Uri.parse('${baseUrl}progress/?user=$userId');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => UserProgress.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load user progress');
    }
  }

  // Get quiz analytics
  Future<List<QuizAnalytics>> getQuizAnalytics(int userId) async {
    final url = Uri.parse('${baseUrl}quizzes/?user=$userId');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => QuizAnalytics.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load quiz analytics');
    }
  }

  // Get engagement metrics
  Future<List<EngagementMetric>> getEngagementMetrics(int userId) async {
    final url = Uri.parse('${baseUrl}engagement/?user=$userId');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => EngagementMetric.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load engagement metrics');
    }
  }

  // Get performance metrics
  Future<List<PerformanceMetric>> getPerformanceMetrics(int userId) async {
    final url = Uri.parse('${baseUrl}performance/?user=$userId');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => PerformanceMetric.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load performance metrics');
    }
  }
}
