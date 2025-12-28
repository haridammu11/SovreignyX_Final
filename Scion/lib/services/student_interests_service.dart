import 'package:supabase_flutter/supabase_flutter.dart';

class StudentInterestsService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Get all interests for the current student
  Future<List<String>> getStudentInterests() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('student_interests')
          .select('interest_category')
          .eq('student_email', user.email!);

      return List<String>.from(
        response.map((item) => item['interest_category'] as String),
      );
    } catch (e) {
      print('Error fetching student interests: $e');
      return [];
    }
  }

  /// Save student interests (replaces existing)
  Future<bool> saveStudentInterests(List<String> interests) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      // Delete existing interests
      await _client
          .from('student_interests')
          .delete()
          .eq('student_email', user.email!);

      // Insert new interests
      if (interests.isNotEmpty) {
        final data = interests.map((interest) {
          return {
            'student_email': user.email,
            'interest_category': interest,
          };
        }).toList();

        await _client.from('student_interests').insert(data);
      }

      return true;
    } catch (e) {
      print('Error saving student interests: $e');
      return false;
    }
  }

  /// Add a single interest
  Future<bool> addInterest(String interest) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      await _client.from('student_interests').insert({
        'student_email': user.email,
        'interest_category': interest,
      });

      return true;
    } catch (e) {
      print('Error adding interest: $e');
      return false;
    }
  }

  /// Remove a single interest
  Future<bool> removeInterest(String interest) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      await _client
          .from('student_interests')
          .delete()
          .eq('student_email', user.email!)
          .eq('interest_category', interest);

      return true;
    } catch (e) {
      print('Error removing interest: $e');
      return false;
    }
  }

  /// Check if student has set up interests
  Future<bool> hasInterests() async {
    try {
      final interests = await getStudentInterests();
      return interests.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get interest statistics (for analytics)
  Future<Map<String, int>> getInterestStatistics() async {
    try {
      final response = await _client
          .from('student_interests')
          .select('interest_category');

      final stats = <String, int>{};
      for (final item in response) {
        final interest = item['interest_category'] as String;
        stats[interest] = (stats[interest] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('Error fetching interest statistics: $e');
      return {};
    }
  }
}
