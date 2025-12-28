import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quiz.dart';

class QuizService {
  static const String baseUrl =
      'https://9qcb6b3j-8000.inc1.devtunnels.ms/api/quizzes';
  final String? token;

  QuizService({this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Token $token',
  };

  // Get all quizzes for a course
  Future<List<Quiz>> getQuizzes(int courseId) async {
    final url = Uri.parse('${baseUrl}?course=$courseId');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Quiz.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load quizzes');
    }
  }

  // Get quiz by ID
  Future<Quiz> getQuiz(int id) async {
    final url = Uri.parse('${baseUrl}$id/');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Quiz.fromJson(data);
    } else {
      throw Exception('Failed to load quiz');
    }
  }

  // Get questions for a quiz
  Future<List<Question>> getQuestions(int quizId) async {
    final url = Uri.parse('${baseUrl}questions/?quiz=$quizId');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Question.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load questions');
    }
  }

  // Get choices for a question
  Future<List<Choice>> getChoices(int questionId) async {
    final url = Uri.parse('${baseUrl}choices/?question=$questionId');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Choice.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load choices');
    }
  }

  // Start a quiz attempt
  Future<UserQuizAttempt> startQuizAttempt(int quizId) async {
    final url = Uri.parse('${baseUrl}attempts/');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'quiz': quizId,
        'started_at': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return UserQuizAttempt.fromJson(data);
    } else {
      throw Exception('Failed to start quiz attempt');
    }
  }

  // Submit an answer
  Future<void> submitAnswer({
    required int attemptId,
    required int questionId,
    int? selectedChoiceId,
    String? shortAnswer,
  }) async {
    final url = Uri.parse('${baseUrl}answers/');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'attempt': attemptId,
        'question': questionId,
        'selected_choice': selectedChoiceId,
        'short_answer': shortAnswer,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to submit answer');
    }
  }

  // Complete a quiz attempt
  Future<UserQuizAttempt> completeQuizAttempt(int attemptId) async {
    final url = Uri.parse('${baseUrl}attempts/$attemptId/');
    final response = await http.patch(
      url,
      headers: _headers,
      body: jsonEncode({'completed_at': DateTime.now().toIso8601String()}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return UserQuizAttempt.fromJson(data);
    } else {
      throw Exception('Failed to complete quiz attempt');
    }
  }
}
