import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class GroqService {
  // Groq API endpoint
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  // API key
  final String _apiKey;

  GroqService({required String apiKey}) : _apiKey = apiKey {
    print('GroqService initialized with API key length: ${apiKey.length}');
    print(
      'GroqService API key starts with: ${apiKey.substring(0, min(10, apiKey.length))}...',
    );

    if (apiKey.isEmpty) {
      print('WARNING: GroqService initialized with empty API key');
    }
    // Check if API key looks valid (should start with 'gsk_')
    else if (!apiKey.startsWith('gsk_')) {
      print('WARNING: GroqService API key does not start with "gsk_" prefix');
      print('Actual API key: "$apiKey"');
    }
  }

  /// Send a message to the Groq AI and get a response
  Future<String> sendMessage(
    String message, {
    List<Map<String, dynamic>>? history,
  }) async {
    // Check if API key is valid
    if (_apiKey.isEmpty) {
      throw Exception(
        'Invalid API Key: Please configure your Groq API key in lib/utils/constants.dart. '
        'Get your free API key at: https://console.groq.com/',
      );
    }

    // Check if API key looks valid
    if (!_apiKey.startsWith('gsk_')) {
      throw Exception(
        'Invalid API Key Format: Groq API keys should start with "gsk_". '
        'Please check your API key in lib/utils/constants.dart. '
        'Get your free API key at: https://console.groq.com/',
      );
    }

    try {
      print('=== GROQ SERVICE DEBUG INFO ===');
      print('API Key length: ${_apiKey.length}');
      print(
        'API Key starts with: ${_apiKey.substring(0, min(10, _apiKey.length))}...',
      );
      print('Base URL: $_baseUrl');
      print('Message: $message');
      print('History length: ${history?.length ?? 0}');

      // Prepare the request body for Groq API
      final List<Map<String, dynamic>> messages = [
        // Add system prompt as the first message
        {'role': 'system', 'content': AppConstants.defaultSystemPrompt},
      ];

      print('Added system message');

      // Add history messages if provided
      if (history != null && history.isNotEmpty) {
        print('Processing history messages...');
        messages.addAll(history);
        print('Added ${history.length} history messages');
      } else {
        print('No history messages to add');
      }

      // Add the current user message
      messages.add({'role': 'user', 'content': message});
      print('Added current user message');

      final requestBody = {
        'model': 'llama-3.3-70b-versatile', // Keep the specified model
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 1024,
      };

      print('Request body prepared:');
      print(jsonEncode(requestBody));

      // Make the API request
      print('Making API request...');
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Headers Keys: ${response.headers.keys.toList()}');
      // Don't print the full response body as it might contain sensitive information
      print('API Response Body Length: ${response.body.length}');

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Parse the response
        final responseData = jsonDecode(response.body);

        // Debug: Print the response structure (without full content)
        print(
          'API Response Parsed - Choices count: ${responseData['choices']?.length ?? 0}',
        );

        // Extract the AI response
        if (responseData['choices'] != null &&
            responseData['choices'].isNotEmpty &&
            responseData['choices'][0]['message'] != null) {
          final aiResponse = responseData['choices'][0]['message']['content'];
          print('AI Response Length: ${aiResponse.length}');
          return aiResponse;
        } else {
          throw Exception('Invalid response format from Groq service');
        }
      } else if (response.statusCode == 401) {
        // Handle authorization errors specifically
        print('Groq API Authorization Error Details:');
        print(
          'Response Body Preview: ${response.body.substring(0, min(200, response.body.length))}',
        );
        throw Exception(
          'Groq API authorization failed. Please check your API key. '
          'Get your free API key at: https://console.groq.com/',
        );
      } else if (response.statusCode == 400) {
        // Handle bad request errors
        throw Exception('Groq API bad request: ${response.body}');
      } else if (response.statusCode == 429) {
        // Handle rate limiting
        throw Exception(
          'Groq API rate limit exceeded. Please try again later.',
        );
      } else if (response.statusCode >= 500) {
        // Handle server errors
        throw Exception(
          'Groq API server error (${response.statusCode}). Please try again later.',
        );
      } else {
        // Handle other error responses
        throw Exception(
          'Groq API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      print('=== GROQ SERVICE ERROR ===');
      print('Exception: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to communicate with Groq service: $e');
    }
  }

  /// Send a message with streaming response (if supported by the API)
  Future<Stream<String>> streamMessage(
    String message, {
    List<Map<String, dynamic>>? history,
  }) async {
    // For now, we'll implement a simple version that returns the full response as a stream
    // In a more advanced implementation, this would connect to a streaming endpoint

    print('Streaming message: $message');
    final completer = Completer<Stream<String>>();

    try {
      final response = await sendMessage(message, history: history);
      completer.complete(Stream.value(response));
    } catch (e, stackTrace) {
      print('Stream error: $e');
      print('Stream error stack trace: $stackTrace');
      completer.completeError(e);
    }

    return completer.future;
  }
}

