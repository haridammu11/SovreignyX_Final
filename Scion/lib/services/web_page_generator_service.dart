import 'dart:convert';
import 'package:http/http.dart' as http;

class WebPageGeneratorService {
  // Update this URL to match your Django backend
  static const String baseUrl = 'https://vinays123.pythonanywhere.com/api/code';

  /// Create a new AI-generated web page
  ///
  /// Example usage:
  /// ```dart
  /// final result = await WebPageGeneratorService.createPage(
  ///   pageType: 'registration',
  ///   fields: [
  ///     {'name': 'email', 'type': 'email', 'required': true, 'label': 'Email'},
  ///     {'name': 'password', 'type': 'password', 'required': true, 'label': 'Password'},
  ///   ],
  ///   theme: 'dark',
  ///   projectName: 'User Registration',
  /// );
  /// ```
  static Future<Map<String, dynamic>> createPage({
    required String pageType,
    required List<Map<String, dynamic>> fields,
    String theme = 'dark',
    Map<String, String>? validationRules,
    String? submitEndpoint,
    String? projectName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create-page/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'page_type': pageType,
          'fields': fields,
          'theme': theme,
          'validation_rules': validationRules ?? {},
          'submit_endpoint': submitEndpoint ?? '/api/submit/',
          'project_name': projectName ?? '$pageType Page',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'project_id': data['project_id'],
            'web_url': data['web_url'],
            'metadata': data['metadata'],
          };
        } else {
          return {'success': false, 'error': data['error']};
        }
      } else {
        return {
          'success': false,
          'error': 'Server Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Web Page Generation Error: $e');
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Get the URL and metadata for a specific project
  static Future<Map<String, dynamic>> getPageUrl(String projectId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/page-url/$projectId/'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'web_url': data['web_url'],
            'metadata': data['metadata'],
          };
        } else {
          return {'success': false, 'error': data['error']};
        }
      } else {
        return {
          'success': false,
          'error': 'Server Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// List all generated projects
  static Future<Map<String, dynamic>> listProjects() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/list-projects/'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {'success': true, 'projects': data['projects']};
        } else {
          return {'success': false, 'error': data['error']};
        }
      } else {
        return {
          'success': false,
          'error': 'Server Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Delete a generated page
  static Future<Map<String, dynamic>> deletePage(String projectId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/delete-page/$projectId/'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'success': false,
          'error': 'Server Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Generate page from natural language prompt (DYNAMIC)
  ///
  /// Example:
  /// ```dart
  /// final result = await WebPageGeneratorService.generateFromPrompt(
  ///   prompt: 'Create an effective dashboard with charts, stats cards, and user activity feed',
  ///   theme: 'dark',
  /// );
  /// ```
  static Future<Map<String, dynamic>> generateFromPrompt({
    required String prompt,
    String theme = 'dark',
    String? projectName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create-page-from-prompt/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': prompt,
          'theme': theme,
          'project_name': projectName ?? 'AI Generated Page',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'project_id': data['project_id'],
            'web_url': data['web_url'],
            'metadata': data['metadata'],
          };
        } else {
          return {'success': false, 'error': data['error']};
        }
      } else {
        return {
          'success': false,
          'error': 'Server Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Prompt-based Generation Error: $e');
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Generate page with REAL backend functionality
  ///
  /// Example for Supabase:
  /// ```dart
  /// final result = await WebPageGeneratorService.generateWithBackend(
  ///   prompt: 'Create a registration page',
  ///   theme: 'dark',
  ///   backendConfig: {
  ///     'type': 'supabase',
  ///     'supabase_url': 'YOUR_SUPABASE_URL',
  ///     'supabase_anon_key': 'YOUR_SUPABASE_ANON_KEY',
  ///     'table_name': 'users',
  ///   },
  /// );
  /// ```
  static Future<Map<String, dynamic>> generateWithBackend({
    required String prompt,
    String theme = 'dark',
    String? projectName,
    Map<String, dynamic>? backendConfig,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create-page-with-backend/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': prompt,
          'theme': theme,
          'project_name': projectName ?? 'Backend-Enabled Page',
          'backend_config': backendConfig ?? {},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'project_id': data['project_id'],
            'web_url': data['web_url'],
            'metadata': data['metadata'],
          };
        } else {
          return {'success': false, 'error': data['error']};
        }
      } else {
        return {
          'success': false,
          'error': 'Server Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Backend Generation Error: $e');
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Modify existing page with prompt
  static Future<Map<String, dynamic>> modifyPage({
    required String projectId,
    required String prompt,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/modify-page/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'project_id': projectId, 'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'],
            'project_id': data['project_id'],
          };
        } else {
          return {'success': false, 'error': data['error']};
        }
      } else {
        return {
          'success': false,
          'error': 'Server Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Modify Page Error: $e');
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Quick templates for common page types
  static Map<String, dynamic> getRegistrationTemplate() {
    return {
      'pageType': 'registration',
      'fields': [
        {
          'name': 'username',
          'type': 'text',
          'required': true,
          'label': 'Username',
        },
        {'name': 'email', 'type': 'email', 'required': true, 'label': 'Email'},
        {
          'name': 'password',
          'type': 'password',
          'required': true,
          'label': 'Password',
        },
        {
          'name': 'confirm_password',
          'type': 'password',
          'required': true,
          'label': 'Confirm Password',
        },
      ],
      'validationRules': {
        'email': 'email_format',
        'password': 'min_8_chars',
        'confirm_password': 'match_password',
      },
    };
  }

  static Map<String, dynamic> getLoginTemplate() {
    return {
      'pageType': 'login',
      'fields': [
        {'name': 'email', 'type': 'email', 'required': true, 'label': 'Email'},
        {
          'name': 'password',
          'type': 'password',
          'required': true,
          'label': 'Password',
        },
        {
          'name': 'remember_me',
          'type': 'checkbox',
          'required': false,
          'label': 'Remember Me',
        },
      ],
    };
  }

  static Map<String, dynamic> getContactTemplate() {
    return {
      'pageType': 'contact',
      'fields': [
        {
          'name': 'name',
          'type': 'text',
          'required': true,
          'label': 'Full Name',
        },
        {'name': 'email', 'type': 'email', 'required': true, 'label': 'Email'},
        {
          'name': 'subject',
          'type': 'text',
          'required': true,
          'label': 'Subject',
        },
        {
          'name': 'message',
          'type': 'textarea',
          'required': true,
          'label': 'Message',
        },
      ],
    };
  }
}
