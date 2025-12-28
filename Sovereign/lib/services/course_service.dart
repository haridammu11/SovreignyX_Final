import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course.dart';

class CourseService {
  final SupabaseClient _client = Supabase.instance.client;

  // -- Company/Admin Methods --

  // Create a new course
  Future<int> createCourse(
    String title, 
    String description, 
    String engineeringStream,
    String? companyEmail,
    {int points = 50}
  ) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _client.from('courses').insert({
        'title': title,
        'description': description,
        'points': points,
        'instructor_id': user.id,
        'engineering_stream': engineeringStream,
        'company_email': companyEmail ?? user.email,
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

  // Get all courses (for viewing list of created courses)
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
          createdAt: DateTime.parse(json['created_at']),
          updatedAt: DateTime.parse(json['updated_at']),
        );
      }).toList();
    } catch (e) {
      print('Error fetching courses: $e');
      throw Exception('Failed to load courses');
    }
  }
}
