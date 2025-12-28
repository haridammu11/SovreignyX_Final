import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ContestService {
  final SupabaseClient _client = Supabase.instance.client;

  // Fetch available contests
  Future<List<Map<String, dynamic>>> getContests() async {
    try {
      final response = await _client
          .from('contests')
          .select()
          .order('start_time', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching contests: $e');
      return [];
    }
  }

  // Join a contest (Register participant)
  Future<bool> joinContest(String contestId) async {
    final result = await joinContestWithResult(contestId);
    return result['success'] == true;
  }

  // Join a contest with detailed result
  Future<Map<String, dynamic>> joinContestWithResult(String contestId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'User not logged in'};
      }

      // Check if already joined
      final existing = await _client
          .from('contest_participants')
          .select()
          .eq('contest_id', contestId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existing != null) {
        return {'success': true, 'error': null};
      }

      await _client.from('contest_participants').insert({
        'contest_id': contestId,
        'user_id': user.id,
        'status': 'registered',
      });
      return {'success': true, 'error': null};
    } catch (e) {
      print('Error joining contest: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Submit contest results
  Future<bool> submitContestResult(String contestId, int score) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      await _client.from('contest_participants').update({
        'score': score,
        'status': 'completed',
      }).eq('contest_id', contestId).eq('user_id', user.id);

      return true;
    } catch (e) {
      print('Error submitting contest result: $e');
      return false;
    }
  }

  // Generate contest questions (Coding + Quiz)
  Future<Map<String, dynamic>> generateContestQuestions(String title, String description, String difficulty) async {
    final apiKey = AppConstants.groqApiKey; 
    const url = 'https://api.groq.com/openai/v1/chat/completions';

    final prompt = '''
    Act as an expert competitive programming contest setter for platforms like Codeforces or LeetCode.
    Create advanced content for a coding contest.
    
    CONTEST TITLE: "$title"
    THEME/DESCRIPTION: "$description"
    TARGET DIFFICULTY: "$difficulty"

    YOUR TASK:
    1. Generate 2 unique Coding Problems that are appropriate for the "$difficulty" level.
       - Each problem must include a clear description, input/output constraints, and 3 test cases.
       - The problems should be relevant to the contest theme.
    2. Generate 3 Multiple Choice Questions (Quiz) that test deep conceptual knowledge of the topic.
       - Each question must have 4 plausible options and 1 correct answer.

    OBLIGATORY JSON STRUCTURE:
    {
      "coding_problems": [
        {
          "title": "A challenging title",
          "description": "A detailed problem statement with examples...",
          "input_format": "Detailed input description with constraints (e.g., 1 <= N <= 10^5)",
          "output_format": "Exact output format required",
          "test_cases": [
             {"input": "sample input", "output": "expected output"}
          ]
        }
      ],
      "quiz_questions": [
        {
          "question": "A conceptual question about the field...",
          "options": ["Option A", "Option B", "Option C", "Option D"],
          "correct_answer_index": 0
        }
      ]
    }

    CRITICAL INSTRUCTIONS:
    - Return ONLY the raw JSON object.
    - DO NOT include markdown code blocks (```json).
    - Ensure the problems are significantly more advanced than basic "Hello World" or simple arithmetic.
    - If difficulty is "Advanced" or "Production-Level", include complex algorithms (Dynamic Programming, Graphs, System Design).
    ''';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama3-70b-8192',
          'messages': [
            {'role': 'system', 'content': 'You are a competitive programming contest setter.'},
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return Map<String, dynamic>.from(jsonDecode(_cleanJson(content)));
      }
    } catch (e) {
      print('Error generating questions: $e');
    }
    
    // Fallback
    return {
      "coding_problems": [
        {
          "title": "Default Problem",
          "description": "Write a program to print 'Hello World'.",
          "input_format": "None",
          "output_format": "Hello World",
          "test_cases": []
        }
      ],
      "quiz_questions": [
        {
          "question": "What is the time complexity of binary search?",
          "options": ["O(n)", "O(log n)", "O(n^2)", "O(1)"],
          "correct_answer_index": 1
        },
        {
          "question": "Which data structure follows LIFO?",
          "options": ["Queue", "Stack", "Tree", "Graph"],
          "correct_answer_index": 1
        }
      ]
    };
  }

  String _cleanJson(String text) {
    text = text.replaceAll('```json', '').replaceAll('```', '').trim();
    // Try to find object envelope
    final startObj = text.indexOf('{');
    final endObj = text.lastIndexOf('}');
    
    // Try to find list envelope (legacy support or if prompt ignored instructions)
    final startList = text.indexOf('[');
    final endList = text.lastIndexOf(']');

    if (startObj != -1 && endObj != -1 && (startList == -1 || startObj < startList)) {
       return text.substring(startObj, endObj + 1);
    } else if (startList != -1 && endList != -1) {
       return text.substring(startList, endList + 1);
    }
    
    return text;
  }
}
