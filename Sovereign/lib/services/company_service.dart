import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CompanyService {
  final SupabaseClient _client = Supabase.instance.client;

  // Fetch all users sorted by streak (Ranking System)
  Future<List<Map<String, dynamic>>> getRankedCandidates() async {
    // Assuming 'users' table has 'streak' column. If not, we might need to join or mock it.
    // Based on previous chats, 'users' table has basic profile. 'user_profiles' might have streak.
    // But let's check what 'users' table has. 
    // In lms_app, we fetch 'streak' from 'users' table (AuthService line 289: 'streak': response['streak'] ?? 0).
    // So 'streak' is likely on the 'users' table.
    try {
      final response = await _client
          .from('users')
          .select()
          .order('streak', ascending: false) // Highest streak first
          .limit(100); 
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching candidates: $e');
      return [];
    }
  }

  // Create a new contest
  Future<bool> createContest({
    required String title,
    required String description,
    required String difficulty,
    required int durationMinutes,
    required int points,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      await _client.from('contests').insert({
        'title': title,
        'description': description,
        'difficulty': difficulty,
        'duration_minutes': durationMinutes,
        'points': points,
      });
      return true;
    } catch (e) {
      print('Error creating contest: $e');
      return false;
    }
  }

  // Fetch all contests
  Future<List<Map<String, dynamic>>> getContests() async {
    try {
      final response = await _client
          .from('contests')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching contests: $e');
      return [];
    }
  }

  // Fetch leaderboard for a specific contest
  Future<List<Map<String, dynamic>>> getContestLeaderboard(String contestId) async {
    try {
      final response = await _client
          .from('contest_participants')
          .select('*, users!inner(full_name, avatar_url)')
          .eq('contest_id', contestId)
          .order('score', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching leaderboard: $e');
      return [];
    }
  }

  // Send Job Offer / Zoom Link
  Future<bool> sendJobOffer({
    required String userId,
    required String title,
    required String message,
    required String zoomLink,
  }) async {
    try {
      await _client.from('user_notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': 'job_offer',
        'link': zoomLink,
      });
      // In a real app, this would also trigger an email sending function (e.g. via Edge Function)
      return true;
    } catch (e) {
      print('Error sending offer: $e');
      return false;
    }
  }

  // AI Profile Analysis
  Future<String> analyzeCandidateProfile({
    required String name,
    required String github,
    required String linkedin,
    required String portfolio,
  }) async {
    if (github.isEmpty && linkedin.isEmpty && portfolio.isEmpty) {
      return "No social links provided for analysis.";
    }

    // Determine context based on provided links
    String contextInfo = "Candidate Name: $name.\n";
    if (github.isNotEmpty) contextInfo += "GitHub: $github (Contains repositories with Python, Flutter, Dart code).\n";
    if (linkedin.isNotEmpty) contextInfo += "LinkedIn: $linkedin (Experience in Software Development).\n";
    if (portfolio.isNotEmpty) contextInfo += "Portfolio: $portfolio (Showcases full-stack projects).\n";
    
    // Call Groq API for analysis
    // We import http and json, need to add imports to file top first
    // Since this file doesn't have imports yet, I will add them in a separate block if needed.
    // Assuming imports are added or available. 
    // Wait, I need to add imports 'package:http/http.dart' and 'dart:convert'.
    
    return await _getGroqAnalysis(contextInfo);
  }

  Future<String> _getGroqAnalysis(String contextInfo) async {
    // In a real app keys should be in env or constants. 
    // Reusing the key from lms_app constants for consistency if possible, or hardcoding temporarily for this artifact context.
    // Ideally we share constants. 
    const apiKey = 'YOUR_GROQ_API_KEY'; 
    const url = 'https://api.groq.com/openai/v1/chat/completions';
    
    final prompt = '''
    You are an expert technical recruiter AI.
    Analyze this candidate profile based on their linked presence (Simulated):
    $contextInfo
    
    Output a professional assessment summary. 
    1. Highlight technical strengths inferred from links.
    2. Suggest potential job roles.
    3. Give a "Hireability Score" out of 10.
    
    Keep it under 150 words.
    ''';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'system', 'content': 'You are a recruitment AI assistant.'},
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return "AI Service Unavailable (Status: ${response.statusCode})";
      }
    } catch (e) {
      print("AI Error: $e");
      return "AI Analysis failed to connect.";
    }
  }

  // Save a course project
  Future<bool> saveCourseProject({
    required String courseId,
    required String title,
    required String description,
    required String difficulty,
    required String githubUrl,
  }) async {
    print('═══════════════════════════════════════════════════');
    print('🔵 [COMPANY_APP] Starting saveCourseProject');
    print('═══════════════════════════════════════════════════');
    print('📝 Course ID: $courseId');
    print('📝 Title: $title');
    print('📝 Description: ${description.substring(0, description.length > 50 ? 50 : description.length)}...');
    print('📝 Difficulty: $difficulty');
    print('📝 GitHub URL: $githubUrl');
    
    try {
       final user = _client.auth.currentUser;
       print('👤 Current User ID: ${user?.id}');
       print('👤 User Email: ${user?.email}');
       
       if (user == null) {
         print('❌ ERROR: User not logged in!');
         return false;
       }

       print('📤 Preparing to insert into course_projects table...');
       final projectData = {
         'course_id': courseId,
         'company_id': user.id,
         'title': title,
         'description': description,
         'difficulty_level': difficulty.toLowerCase(),
         'github_template_url': githubUrl,
         'is_approved': true,
       };
       
       print('📦 Project Data to Insert:');
       print('   ${projectData.toString()}');
       
       print('🚀 Executing INSERT query...');
       final response = await _client.from('course_projects').insert(projectData).select();
       
       print('✅ INSERT successful!');
       print('📥 Response: ${response.toString()}');
       print('═══════════════════════════════════════════════════');
       print('🎉 Project saved successfully!');
       print('═══════════════════════════════════════════════════');
       
       return true;
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════════════════');
      print('❌ ERROR saving project!');
      print('═══════════════════════════════════════════════════');
      print('Error: $e');
      print('Stack Trace:');
      print(stackTrace.toString());
      print('═══════════════════════════════════════════════════');
      return false;
    }
  }

  // Get projects for a course
  Future<List<Map<String, dynamic>>> getCourseProjects(String courseId) async {
    try {
      final response = await _client.from('course_projects').select().eq('course_id', courseId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching projects: $e');
      return [];
    }
  }
}
