import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course.dart';

class CourseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Get all courses
  Future<List<Course>> getCourses() async {
    try {
      final response = await _client.from('courses').select();
      
      return (response as List).map((json) {
        return Course(
          id: json['id'],
          title: json['title'],
          description: json['description'] ?? '',
          categoryId: 0,
          instructorId: 0,
          thumbnail: json['thumbnail_url'],
          price: 0.0,
          isPublished: true,
          points: json['points'] ?? 50, // Map points
          createdAt: DateTime.parse(json['created_at']),
          updatedAt: DateTime.parse(json['updated_at']),
        );
      }).toList();
    } catch (e) {
      print('Error fetching courses: $e');
      throw Exception('Failed to load courses');
    }
  }

  // Search courses
  Future<List<Course>> searchCourses(String query) async {
    try {
      final response = await _client
          .from('courses')
          .select()
          .ilike('title', '%$query%');
      
      return (response as List).map((json) {
        return Course(
          id: json['id'],
          title: json['title'],
          description: json['description'] ?? '',
          categoryId: 0,
          instructorId: 0,
          thumbnail: json['thumbnail_url'],
          price: 0.0,
          isPublished: true,
          points: json['points'] ?? 50,
          createdAt: DateTime.parse(json['created_at']),
          updatedAt: DateTime.parse(json['updated_at']),
        );
      }).toList();
    } catch (e) {
      print('Error searching courses: $e');
      return [];
    }
  }

  // Get course by ID
  Future<Course> getCourse(int id) async {
    try {
      final response = await _client
          .from('courses')
          .select()
          .eq('id', id)
          .single();
          
      return Course(
          id: response['id'],
          title: response['title'],
          description: response['description'] ?? '',
          categoryId: 0,
          instructorId: 0,
          thumbnail: response['thumbnail_url'],
          price: 0.0,
          isPublished: true,
          points: response['points'] ?? 50,
          createdAt: DateTime.parse(response['created_at']),
          updatedAt: DateTime.parse(response['updated_at']),
      );
    } catch (e) {
      print('Error fetching course: $e');
      throw Exception('Failed to load course');
    }
  }

  // Get modules for a course
  Future<List<Module>> getModules(int courseId) async {
    try {
      final response = await _client
          .from('modules')
          .select()
          .eq('course_id', courseId)
          .order('order_index');
          
      return (response as List).map((json) {
        return Module(
          id: json['id'],
          courseId: json['course_id'],
          title: json['title'],
          description: '', 
          order: json['order_index'] ?? 0,
          createdAt: DateTime.parse(json['created_at']),
          updatedAt: DateTime.parse(json['created_at']), 
        );
      }).toList();
    } catch (e) {
      print('Error fetching modules: $e');
      throw Exception('Failed to load modules');
    }
  }

  // Get lessons for a module
  Future<List<Lesson>> getLessons(int moduleId) async {
    try {
      final response = await _client
          .from('lessons')
          .select()
          .eq('module_id', moduleId)
          .order('order_index');
          
      return (response as List).map((json) {
        return Lesson(
          id: json['id'],
          moduleId: json['module_id'],
          title: json['title'],
          content: json['description'] ?? '', 
          videoUrl: json['video_url'],
          order: json['order_index'] ?? 0,
          createdAt: DateTime.parse(json['created_at']),
          updatedAt: DateTime.parse(json['created_at']),
        );
      }).toList();
    } catch (e) {
      print('Error fetching lessons: $e');
      throw Exception('Failed to load lessons');
    }
  }

  // Enroll in a course (for User)
  Future<void> enrollInCourse(int courseId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      await _client.from('enrollments').insert({
        'user_id': user.id,
        'course_id': courseId,
        'enrolled_at': DateTime.now().toIso8601String(),
        'progress': 0,
      });
    } catch (e) {
      if (e.toString().contains('duplicate')) {
         return;
      }
      print('Error enrolling: $e');
      throw Exception('Failed to enroll');
    }
  }

  // Mark course as completed and award points
  Future<void> completeCourse(int courseId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      // Check if already completed
      final enrollment = await _client.from('enrollments')
        .select('progress')
        .eq('user_id', user.id)
        .eq('course_id', courseId)
        .maybeSingle();
      
      if (enrollment != null && enrollment['progress'] == 100) {
        return; // Already completed
      }

      // Update enrollment
      await _client.from('enrollments').update({
        'progress': 100,
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('user_id', user.id).eq('course_id', courseId);

      // Fetch points for this course
      final course = await _client.from('courses').select('points').eq('id', courseId).single();
      final pointsAwarded = course['points'] as int? ?? 50;

      // Update user points
      // Note: Ideally use RPC for atomicity. Doing read-update for simplicity.
      final userProfile = await _client.from('users').select('points').eq('id', user.id).single();
      final currentPoints = userProfile['points'] as int? ?? 0;
      
      await _client.from('users').update({
        'points': currentPoints + pointsAwarded,
        'last_points_earned_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

    } catch (e) {
      print('Error completing course: $e');
      throw Exception('Failed to complete course');
    }
  }
  
  // Get user enrollments
  Future<List<Enrollment>> getUserEnrollments() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('enrollments')
          .select()
          .eq('user_id', user.id);
      
      return (response as List).map((json) {
        return Enrollment(
          id: json['id'] is String ? 0 : json['id'], 
          userId: 0, 
          courseId: json['course_id'],
          enrolledAt: DateTime.parse(json['enrolled_at']),
          progress: (json['progress'] ?? 0).toDouble(),
          completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
        ); 
      }).toList();
    } catch (e) {
      print('Error fetching enrollments: $e');
      return [];
    }
  }

  // -- Company/Admin Methods --

  // Create a new course
  Future<int> createCourse(String title, String description) async {
    try {
      final response = await _client.from('courses').insert({
        'title': title,
        'description': description,
        'points': 50, // Default points
      }).select().single();
      
      return response['id'];
    } catch (e) {
      print('Error creating course: $e');
      throw Exception('Failed to create course');
    }
  }

  // Create a module
  Future<int> createModule(int courseId, String title, int orderIndex) async {
    try {
      final response = await _client.from('modules').insert({
        'course_id': courseId,
        'title': title,
        'order_index': orderIndex,
      }).select().single();
      
      return response['id'];
    } catch (e) {
      print('Error creating module: $e');
      throw Exception('Failed to create module');
    }
  }

  // Create a lesson
  Future<void> createLesson(int moduleId, String title, String videoUrl, String description, int orderIndex) async {
    try {
      await _client.from('lessons').insert({
        'module_id': moduleId,
        'title': title,
        'video_url': videoUrl,
        'description': description,
        'order_index': orderIndex,
      });
    } catch (e) {
      print('Error creating lesson: $e');
      throw Exception('Failed to create lesson');
    }
  }
}
