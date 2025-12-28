import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class AICourseService {
  final String _apiKey = AppConstants.groqApiKey;
  final String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  Future<Map<String, dynamic>> generateCourseOutline(String topic) async {
    final prompt = '''
      Create a detailed verified course outline on "$topic".
      Target audience: Beginners/Intermediate.
      Structure: 4-6 Modules, each with 3-5 Lesson titles.
      Return ONLY valid JSON in this format:
      {
        "title": "Course Title",
        "description": "Detailed course description",
        "modules": [
          {
            "title": "Module Name",
            "lessons": [
              {
                "title": "Lesson Name", 
                "description": "Brief description",
                "search_query": "Specific youtube search query",
                "resources": [
                  {"title": "Official Documentation", "url": "https://example.com/docs"}
                ]
              }
            ]
          }
        ]
      }
    ''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'system', 'content': 'You are an educational curriculum developer. Output ONLY JSON.'},
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'response_format': {'type': 'json_object'}
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return _parseJson(content);
      } else {
        throw Exception('AI API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to generate course: $e');
    }
  }

  Map<String, dynamic> _parseJson(String content) {
    try {
      final regex = RegExp(r'```(?:json)?\s*(.*?)\s*```', dotAll: true);
      final match = regex.firstMatch(content);
      return jsonDecode(match != null ? match.group(1)! : content);
    } catch (e) {
      return jsonDecode(content); // Try raw
    }
  }
}
