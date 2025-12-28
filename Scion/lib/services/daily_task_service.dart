import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class DailyTaskService {
  final SupabaseClient _client = Supabase.instance.client;
  // Note: Practically, this key should be in Env variables.
  final String _groqApiKey = 'YOUR_GROQ_API_KEY'; 
  final String _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';

  Future<Map<String, dynamic>> getTodaysTasks() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    try {
      // 1. Check if tasks exist for today
      final response = await _client
          .from('user_daily_tasks')
          .select()
          .eq('user_id', user.id)
          .eq('date', today)
          .maybeSingle();

      if (response != null && _isValidTaskData(response)) {
        return response;
      }
      
      // 2. If not exists OR Invalid, Generate New Tasks
      print('Generating new daily tasks (Previous valid: ${response != null})...');
      final newTasks = await _generateDailyContent();
      
      // 3. Insert or Upsert into DB
      final insertResponse = await _client.from('user_daily_tasks').upsert({
        'user_id': user.id,
        'date': today,
        'challenge_data': newTasks['challenge'],
        'quiz_data': newTasks['quiz'],
        'brain_game_data': newTasks['game'],
      }).select().single();
      
      return insertResponse;

    } catch (e) {
      print('Error fetching/generating daily tasks: $e');
      throw Exception('Failed to load daily tasks');
    }
  }

  bool _isValidTaskData(Map<String, dynamic> data) {
    try {
      final quiz = data['quiz_data'];
      if (quiz == null) return false;
      if (quiz is List && quiz.isNotEmpty) {
        // Checking first item structure
        return quiz[0]['options'] != null;
      }
      return false; // Not a list or empty
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _generateDailyContent() async {
    // Generate all 3 in parallel or sequence
    // We'll pick a random language for the quiz
    final languages = ['Python', 'Dart', 'JavaScript', 'Java', 'C++'];
    final language = languages[Random().nextInt(languages.length)];

    final challengeFuture = _generateCodeChallenge();
    final quizFuture = _generateQuiz(language);
    final gameFuture = _generateBrainGame();

    final results = await Future.wait([challengeFuture, quizFuture, gameFuture]);
    
    return {
      'challenge': results[0],
      'quiz': results[1],
      'game': results[2],
    };
  }

  Future<Map<String, dynamic>> _generateCodeChallenge() async {
    final prompt = '''
      Generate 1 coding challenge for a beginner/intermediate developer.
      Return ONLY valid JSON format:
      {
        "title": "Challenge Title",
        "description": "Problem description...",
        "language": "python",
        "starter_code": "def solution():\\n    pass"
      }
    ''';
    final result = await _callGroqJson(prompt);
    return result ?? _getFallbackChallenge();
  }

  Future<List<dynamic>> _generateQuiz(String language) async {
    final prompt = '''
      Generate 5 multiple choice quiz questions about $language.
      Return ONLY valid JSON array:
      [
        {
          "question": "Question text?",
          "options": ["A", "B", "C", "D"],
          "correct_index": 0
        }
      ]
    ''';
    final result = await _callGroqJson(prompt);
    if (result == null || (result is! List && result['questions'] == null)) {
       return getFallbackQuiz();
    }
    return result is List ? result : [result]; // Handle format variance
  }

  Future<Map<String, dynamic>> _generateBrainGame() async {
    final prompt = '''
      Generate 1 trivia or logic riddle with a SINGLE WORD answer.
      Return ONLY valid JSON format:
      {
        "type": "Word Puzzle",
        "question": "The question or riddle text...",
        "answer": "FLUTTER", 
        "hint": "Developed by Google"
      }
      Ensure "answer" is a single word (no spaces), alphanumeric.
    ''';
    final result = await _callGroqJson(prompt);
    return result ?? _getFallbackGame();
  }

  Future<dynamic> _callGroqJson(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'system', 'content': 'You are a content generator. Output ONLY JSON.'},
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'response_format': {'type': 'json_object'} 
        }),
      );

      if (response.statusCode == 200) {
        final content = jsonDecode(response.body)['choices'][0]['message']['content'];
        return _parseJsonContent(content);
      } else {
        throw Exception('AI API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('AI Gen Error: $e');
      // Return null or empty to signal failure, so we can use fallback
      return null;
    }
  }

  dynamic _parseJsonContent(String content) {
    try {
      // 1. Try to find JSON block
      final regex = RegExp(r'```(?:json)?\s*(.*?)\s*```', dotAll: true);
      final match = regex.firstMatch(content);
      String jsonStr = match != null ? match.group(1)! : content;
      
      // 2. Clean up potentially leading/trailing text if regex missed
      jsonStr = jsonStr.trim();
      final start = jsonStr.indexOf(RegExp(r'[\[\{]'));
      final end = jsonStr.lastIndexOf(RegExp(r'[\]\}]'));
      if (start != -1 && end != -1) {
        jsonStr = jsonStr.substring(start, end + 1);
      }
      
      return jsonDecode(jsonStr);
    } catch (e) {
      print('JSON Parse Error: $e\nContent: $content');
      return null;
    }
  }

  // Fallback Data Generators
  List<Map<String, dynamic>> getFallbackQuiz() {
    return [
      {
        "question": "Which keyword is used to define a function in Python?",
        "options": ["func", "def", "function", "define"],
        "correct_index": 1
      },
      {
        "question": "What is the output of print(2 ** 3)?",
        "options": ["6", "8", "9", "5"],
        "correct_index": 1
      },
       {
        "question": "Which data type is immutable in Python?",
        "options": ["List", "Dictionary", "Set", "Tuple"],
        "correct_index": 3
      },
      {
        "question": "How do you start a comment in Python?",
        "options": ["//", "/*", "#", "<!--"],
        "correct_index": 2
      },
      {
        "question": "What does len() function do?",
        "options": ["Returns length", "Returns type", "Returns last item", "None"],
        "correct_index": 0
      }
    ];
  }

  Map<String, dynamic> _getFallbackChallenge() {
    return {
      "title": "Sum of Array",
      "description": "Write a function that returns the sum of all numbers in an array/list.",
      "language": "python",
      "starter_code": "def solution(numbers):\n    # Your code here\n    pass"
    };
  }

  Map<String, dynamic> _getFallbackGame() {
    return {
      "type": "Word Puzzle",
      "question": "Which mobile platform is developed by Google?",
      "answer": "FLUTTER",
      "hint": "Developed by Google"
    };
  }

  // Update Progress
  Future<void> updateTaskStatus(String taskType, bool isCompleted) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    final today = DateTime.now().toIso8601String().split('T')[0];

    String column = '';
    if (taskType == 'challenge') column = 'challenge_completed';
    else if (taskType == 'quiz') column = 'quiz_completed';
    else if (taskType == 'game') column = 'game_completed';
    else return;

    await _client.from('user_daily_tasks')
        .update({column: isCompleted})
        .eq('user_id', user.id)
        .eq('date', today);
        
    // Check if ALL completed
    await syncDailyCompletion(user.id, today);
  }

  Future<void> syncDailyCompletion(String userId, String date) async {
    try {
      final task = await _client.from('user_daily_tasks')
          .select()
          .eq('user_id', userId)
          .eq('date', date)
          .single();
          
      // If all 3 done, but 'all_completed' is FALSE OR streak history missing?
      // We process if all 3 done.
      final bool allThree = (task['challenge_completed'] ?? false) && 
                            (task['quiz_completed'] ?? false) && 
                            (task['game_completed'] ?? false);
                            
      // Verify via history table to be robust (ignore all_completed flag validation)
      final history = await _client.from('user_streak_history')
          .select()
          .eq('user_id', userId)
          .eq('completed_date', date)
          .maybeSingle();

      if (allThree && history == null) {
        print('Syncing Streak: All tasks done & History missing. Updating DB...');
        // 1. Mark daily task as all completed (idempotent)
        await _client.from('user_daily_tasks')
            .update({'all_completed': true})
            .eq('user_id', userId)
            .eq('date', date);
            
        // 2. Add to streak history
        try {
          await _client.from('user_streak_history').upsert({
            'user_id': userId,
            'completed_date': date,
          }, onConflict: 'user_id, completed_date');
          
          // 3. Increment User Streak
          final user = await _client.from('users').select('streak').eq('id', userId).single();
          int currentStreak = user['streak'] ?? 0;
          await _client.from('users').update({'streak': currentStreak + 1}).eq('id', userId);
          
          print('Streak Incremented to ${currentStreak + 1}');
        } catch (e) {
          print('Streak Insert/Update Error: $e');
        }
      } else if (allThree) {
          print('Tasks done, but streak history already exists. Skipping increment.');
      }
    } catch (e) {
      print('Sync Error: $e');
    }
  }
  
  // Calculate Streak dynamically from history (Robust fallback)
  Future<int> calculateStreak(String userId) async {
    try {
      final data = await _client.from('user_streak_history')
          .select('completed_date')
          .eq('user_id', userId)
          .order('completed_date', ascending: false);
      
      if ((data as List).isEmpty) return 0;
      
      List<String> dates = data.map<String>((e) => e['completed_date'].toString()).toList();
      Set<String> uniqueDates = dates.toSet();
      
      final today = DateTime.now();
      final todayStr = today.toIso8601String().split('T')[0];
      
      int streak = 0;
      DateTime checkDate = today;
      
      // If today is not done, check if yesterday was done to maintain streak
      if (!uniqueDates.contains(todayStr)) {
         checkDate = today.subtract(const Duration(days: 1));
         if (!uniqueDates.contains(checkDate.toIso8601String().split('T')[0])) {
           return 0; // Streak broken (today & yesterday missing)
         }
      }
      
      // Count backwards
      while (uniqueDates.contains(checkDate.toIso8601String().split('T')[0])) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
      return streak;
    } catch (e) {
      print('Streak Calc Error: $e');
      return 0;
    }
  }

  // Fetch Streak Calendar
  Future<List<DateTime>> getStreakCalendar() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    
    try {
      final response = await _client.from('user_streak_history')
          .select('completed_date')
          .eq('user_id', user.id);
          
      return (response as List).map((e) => DateTime.parse(e['completed_date'])).toList();
    } catch (e) {
      return [];
    }
  }
}
