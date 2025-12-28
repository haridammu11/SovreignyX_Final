import 'dart:convert';
import 'package:http/http.dart' as http;

class AiCourseService {
  static const String _apiKey = 'YOUR_GROQ_API_KEY';
  static const String _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';

  /// Generates a list of course modules based on topic and count
  static Future<List<String>> generateModules(String courseName, int count) async {
    final prompt = '''
    You are an expert curriculum designer. Create a comprehensive list of EXACTLY $count modules (headings) for a course titled "$courseName".
    
    The modules should cover the subject from beginner to advanced levels.
    Return ONLY a JSON list of strings. Do not include numbering, markdown formatting, or extra text.
    
    Example output format:
    ["Introduction to $courseName", "Basic Concepts", "Advanced Topics"]
    ''';

    try {
      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'system', 'content': 'You are a helpful curriculum assistant that outputs raw JSON.'},
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'];
        
        // Clean up markdown if present
        if (content.contains('```json')) {
          content = content.split('```json')[1].split('```')[0];
        } else if (content.contains('```')) {
          content = content.split('```')[1];
        }

        final List<dynamic> jsonList = jsonDecode(content.trim());
        return jsonList.cast<String>();
      } else {
        throw Exception('Failed to generate modules: ${response.body}');
      }
    } catch (e) {
      print('AI Module Generation Error: $e');
      throw Exception('Failed to connect to AI service');
    }
  }

  /// Generates a detailed description for a specific module/video
  static Future<String> generateVideoDescription(String courseName, String moduleName) async {
    final prompt = '''
    You are an expert instructor for the course "$courseName".
    
    Write a COMPREHENSIVE and CLEAR explanation for the lesson module: "$moduleName".
    
    Your goal is to explain the core concepts of this specific topic in an understandable format for students who will watch a video on this subject.
    
    Include:
    1. Definition of the concept.
    2. Why it is important.
    3. Key points to remember.
    4. A simple code example (if applicable).
    
    Format the output in clean Markdown. Return ONLY the content.
    ''';

    try {
      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'system', 'content': 'You are an educational content creator.'},
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to generate description: ${response.body}');
      }
    } catch (e) {
      print('AI Description Generation Error: $e');
      throw Exception('Failed to connect to AI service');
    }
  }
  // ... (previous methods)

  /// Generates effective project ideas for a course
  static Future<List<Map<String, dynamic>>> generateProjectIdeas(String courseName) async {
    final prompt = '''
    You are an expert curriculum designer. 
    Generate 3 distinct, effective capstone project ideas for a course titled "$courseName".
    
    Each project should be comprehensive and test the core skills of the course.
    
    Return ONLY a JSON list of objects with the following structure:
    [
      {
        "title": "Project Title",
        "description": "Detailed description of requirements and goals (approx 50 words).",
        "difficulty": "beginner" | "intermediate" | "advanced"
      }
    ]
    Do not include markdown blocks or extra text.
    ''';

    try {
      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'system', 'content': 'You are a helpful curriculum assistant that outputs raw JSON.'},
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'];
        
        // Clean up markdown
        if (content.contains('```json')) {
          content = content.split('```json')[1].split('```')[0];
        } else if (content.contains('```')) {
          content = content.split('```')[1];
        }

        final List<dynamic> jsonList = jsonDecode(content.trim());
        return jsonList.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to generate project ideas: ${response.body}');
      }
    } catch (e) {
      print('AI Project Generation Error: $e');
      return [];
    }
  }
}
