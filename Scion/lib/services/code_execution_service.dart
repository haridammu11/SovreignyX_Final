import 'dart:convert';
import 'package:http/http.dart' as http;

class CodeExecutionService {
  // Use public Piston API
  final String baseUrl = 'https://emkc.org/api/v2/piston'; 

  CodeExecutionService();

  Future<Map<String, dynamic>> executeCode({
    required String language,
    required String code,
    String stdin = '',
  }) async {
    try {
      if (code.trim().isEmpty) {
        return {'success': false, 'error': 'Code cannot be empty'};
      }

      if (language.trim().isEmpty) {
        return {'success': false, 'error': 'Language must be selected'};
      }
      
      // Map common names to Piston runtime names
      String pistonLang = language.toLowerCase();
      String version = '*';
      
      if (pistonLang == 'python') {
        pistonLang = 'python';
        version = '3.10.0';
      } else if (pistonLang == 'javascript' || pistonLang == 'js') {
        pistonLang = 'javascript';
        version = '18.15.0';
      } else if (pistonLang == 'dart') {
        pistonLang = 'dart';
        version = '2.19.6';
      } else if (pistonLang == 'cpp' || pistonLang == 'c++') {
        pistonLang = 'c++';
        version = '10.2.0';
      } else if (pistonLang == 'java') {
         pistonLang = 'java';
         version = '15.0.2';
      }

      final url = Uri.parse('https://emkc.org/api/v2/piston/execute');
      print('Executing code at URL: $url with language: $pistonLang');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          "language": pistonLang,
          "version": version,
          "files": [
            {
              "content": code
            }
          ],
          "stdin": stdin,
        }),
      );

      print('Piston response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonData = jsonDecode(decodedBody);
        
        final runData = jsonData['run'];
        final stdout = runData['stdout'] ?? '';
        final stderr = runData['stderr'] ?? '';
        final output = '$stdout\n$stderr'.trim();
        
        return {
          'success': true, 
          'data': {'output': output.isEmpty ? 'Program ran successfully with no output.' : output}
        };
      } else {
        print('Piston Error Body: ${response.body}');
        return {
          'success': false,
          'error': 'Execution Service Error: ${response.statusCode} - ${response.reasonPhrase}\nDetails: ${response.body}',
        };
      }
    } catch (e) {
      print('Code execution error: $e');
      return {
        'success': false,
        'error': 'Network error: Unable to connect to code execution service ($e)',
      };
    }
  }

  // Snippets functionality temporarily disabled as it required custom backend
  Future<Map<String, dynamic>> getUserSnippets() async {
     return {'success': true, 'data': []};
  }

  Future<Map<String, dynamic>> saveSnippet({
    required String language,
    required String code,
    required String title,
  }) async {
     // Mock success for now
     return {'success': true, 'data': {}};
  }

  // Generate Portfolio Website using Django Backend
  Future<Map<String, dynamic>> generatePortfolio({
    required String name,
    required String bio,
    required String skills,
    required String interests,
    required String projects,
    required String certificates,
    required Map<String, String> socialLinks,
  }) async {
    // Local Django Service URL
    // Ensure you use your machine's local IP if testing on real device, or 10.0.2.2 for Android Emulator.
    // Assuming 10.0.2.2 for Android Emulator as per standard Flutter dev.
    // If Web, it's localhost.
    const baseUrl = 'https://vinays123.pythonanywhere.com/api/code'; 
    
    // Ensure no double slashes if baseUrl ends with /
    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

    try {
      final response = await http.post(
        Uri.parse('$cleanBaseUrl/generate-portfolio/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'bio': bio,
          'skills': skills,
          'interests': interests,
          'projects': projects,
          'certificates': certificates,
          'social_links': socialLinks,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {'success': true, 'url': data['url']};
        } else {
          return {'success': false, 'error': data['error']};
        }
      } else {
        return {'success': false, 'error': 'Server Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('Portfolio Generation Error: $e');
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }
}
