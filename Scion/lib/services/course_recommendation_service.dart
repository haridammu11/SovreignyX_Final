import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course.dart';

class CourseRecommendationService {
  final SupabaseClient _client = Supabase.instance.client;

  // Weight factors for recommendation algorithm
  static const double INTEREST_MATCH_WEIGHT = 0.5;
  static const double STREAM_MATCH_WEIGHT = 0.3;
  static const double RATING_WEIGHT = 0.15;
  static const double DIFFICULTY_WEIGHT = 0.05;

  /// Get personalized course recommendations for the current student
  Future<List<Map<String, dynamic>>> getRecommendations({
    int limit = 10,
    String? filterByInterest,
    double? minRating,
    String? difficulty,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      // Get student's interests
      final interestsResponse = await _client
          .from('student_interests')
          .select('interest_category')
          .eq('student_email', user.email!);

      final studentInterests = List<String>.from(
        interestsResponse.map((item) => item['interest_category'] as String),
      );

      if (studentInterests.isEmpty) {
        // No interests set, return popular courses
        return await _getPopularCourses(limit: limit);
      }

      // Get student's engineering stream (from users table)
      final userResponse = await _client
          .from('users')
          .select('engineering_stream')
          .eq('email', user.email!)
          .single();

      final studentStream = userResponse['engineering_stream'] as String?;

      // Get all courses with their tags
      var coursesQuery = _client
          .from('courses')
          .select('''
            *,
            course_tags(tag)
          ''');

      // Apply filters

      if (difficulty != null) {
        coursesQuery = coursesQuery.eq('difficulty', difficulty);
      }

      final coursesResponse = await coursesQuery;

      // Calculate match scores
      final scoredCourses = <Map<String, dynamic>>[];
      
      for (final courseData in coursesResponse) {
        double score = 0.0;

        // Extract course tags
        final tags = (courseData['course_tags'] as List?)
                ?.map((t) => t['tag'] as String)
                .toList() ??
            [];

        // Interest matching
        if (filterByInterest != null) {
          // If filtering by specific interest, only show courses with that tag
          if (!tags.contains(filterByInterest)) continue;
        }

        final matchingInterests =
            tags.where((tag) => studentInterests.contains(tag)).length;
        if (studentInterests.isNotEmpty) {
          final interestScore = matchingInterests / studentInterests.length;
          score += interestScore * INTEREST_MATCH_WEIGHT;
        }

        // Stream matching
        final company = courseData['companies'];
        if (company != null && studentStream != null) {
          final courseStream = company['engineering_stream'] as String?;
          if (courseStream == studentStream) {
            score += STREAM_MATCH_WEIGHT;
          }
        }

        // Rating factor
        final rating = (courseData['rating'] as num?)?.toDouble() ?? 0.0;
        score += (rating / 5.0) * RATING_WEIGHT;

        // Difficulty preference (favor beginner for new students)
        final courseDifficulty = courseData['difficulty'] as String?;
        if (courseDifficulty == 'Beginner') {
          score += DIFFICULTY_WEIGHT;
        }

        // Add to scored courses
        scoredCourses.add({
          ...courseData,
          'match_score': score,
          'match_percentage': (score * 100).round(),
          'matching_interests': matchingInterests,
        });
      }

      // Sort by score and return top N
      scoredCourses.sort((a, b) =>
          (b['match_score'] as double).compareTo(a['match_score'] as double));

      return scoredCourses.take(limit).toList();
    } catch (e) {
      print('Error getting recommendations: $e');
      return [];
    }
  }

  /// Get popular courses (fallback when no interests are set)
  Future<List<Map<String, dynamic>>> _getPopularCourses({
    int limit = 10,
  }) async {
    try {
      final response = await _client
          .from('courses')
          .select('''
            *
          ''')
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response.map((course) => {
            ...course,
            'match_score': 0.0,
            'match_percentage': 0,
            'matching_interests': 0,
          }));
    } catch (e) {
      print('Error getting popular courses: $e');
      return [];
    }
  }

  /// Get recommended courses as Course objects
  Future<List<Course>> getRecommendedCourses({
    int limit = 10,
    String? filterByInterest,
    double? minRating,
    String? difficulty,
  }) async {
    try {
      final recommendations = await getRecommendations(
        limit: limit,
        filterByInterest: filterByInterest,
        minRating: minRating,
        difficulty: difficulty,
      );

      return recommendations.map((data) {
        return Course(
          id: data['id'] as int, // Fixed: id is int
          title: data['title'] as String,
          description: data['description'] as String,
          categoryId: data['category'] as int? ?? 0,
          instructorId: data['instructor'] as int? ?? 0,
          thumbnail: data['thumbnail_url'] as String?,
          price: (data['price'] as num?)?.toDouble() ?? 0.0,
          isPublished: data['is_published'] as bool? ?? true,
          difficulty: data['difficulty'] as String? ?? 'Beginner',
          rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
          points: data['points'] as int? ?? 50,
          createdAt: DateTime.parse(data['created_at']),
          updatedAt: DateTime.parse(data['updated_at']),
        );
      }).toList();
    } catch (e) {
      print('Error converting recommendations to courses: $e');
      return [];
    }
  }

  /// Get all available interest tags from courses
  Future<List<String>> getAvailableInterests() async {
    try {
      final response = await _client
          .from('course_tags')
          .select('tag')
          .order('tag');

      final tags = response.map((item) => item['tag'] as String).toSet().toList();
      return tags;
    } catch (e) {
      print('Error getting available interests: $e');
      return [];
    }
  }

  /// Add tags to a course (for course creators)
  Future<bool> addCourseTags(String courseId, List<String> tags) async {
    try {
      // Delete existing tags
      await _client
          .from('course_tags')
          .delete()
          .eq('course_id', courseId);

      // Insert new tags
      if (tags.isNotEmpty) {
        final data = tags.map((tag) {
          return {
            'course_id': courseId,
            'tag': tag,
          };
        }).toList();

        await _client.from('course_tags').insert(data);
      }

      return true;
    } catch (e) {
      print('Error adding course tags: $e');
      return false;
    }
  }

  /// Get tags for a specific course
  Future<List<String>> getCourseTags(String courseId) async {
    try {
      final response = await _client
          .from('course_tags')
          .select('tag')
          .eq('course_id', courseId);

      return List<String>.from(
        response.map((item) => item['tag'] as String),
      );
    } catch (e) {
      print('Error getting course tags: $e');
      return [];
    }
  }
}
