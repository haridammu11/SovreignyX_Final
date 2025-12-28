import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../models/course_reel_model.dart';
import '../services/youtube_service.dart';
import '../services/supabase_service.dart';

class CourseReelsService {
  final SupabaseService _supabaseService = SupabaseService();
  final YouTubeService _youtubeService = YouTubeService();

  static final CourseReelsService _instance = CourseReelsService._internal();
  factory CourseReelsService() => _instance;
  CourseReelsService._internal();

  /// ULTRA-STRICT Populate course reels with YouTube videos for a specific course and language
  /// This method ensures ONLY the EXACT course videos are retrieved and inserted
  Future<void> populateCourseReels({
    required String courseId,
    required String courseTitle,
    required String language,
  }) async {
    try {
      print(
        '🔴 ULTRA-STRICT [INFO] Populating reels for course: $courseTitle ($language)',
      );
      print('═' * 100);

      // Validate inputs
      if (courseId.isEmpty || courseTitle.isEmpty || language.isEmpty) {
        throw Exception(
          'Invalid input parameters: courseId, courseTitle, and language are required',
        );
      }

      // STEP 1: Build an ULTRA-STRICT search query with both course and language
      print(
        '🔍 [STEP 1] Building ULTRA-STRICT search query for: "$courseTitle" in "$language"',
      );

      // Create a highly specific search query
      final searchQuery = '$courseTitle $language tutorial introduction basics';
      print('🔍 [QUERY] Search query: "$searchQuery"');

      // For AI courses, we want ONLY relevant educational content
      // Use ULTRA-STRICT filtering from YouTubeService
      final videos = await _youtubeService.searchVideos(
        searchQuery,
        maxResults: 100, // Get even MORE results for better filtering
        language: language,
        courseTitle: courseTitle,
      );

      print(
        '📊 [STEP 2] YouTube service returned ${videos.length} videos (will be ultra-strictly filtered)',
      );

      if (videos.isEmpty) {
        print(
          '⚠️ [WARNING] No videos found for course: $courseTitle ($language)',
        );
        return;
      }

      // STEP 3: ULTRA-STRICT VALIDATION - Only insert videos that ACTUALLY match the course and language
      print('🔍 [STEP 3] Applying ULTRA-STRICT validation filters...');
      final validatedVideos = <YouTubeVideo>[];

      for (var video in videos) {
        // ULTRA-STRICT CHECK 1: Video title must contain EXACT course name
        final titleContainsCourse = video.title.toLowerCase().contains(
          courseTitle.toLowerCase(),
        );

        // ULTRA-STRICT CHECK 2: Validate it's not some random educational video
        final lowerTitle = video.title.toLowerCase();
        final lowerDesc = (video.description ?? '').toLowerCase();
        final isEducational =
            lowerTitle.contains('tutorial') ||
            lowerTitle.contains('introduction') ||
            lowerTitle.contains('basics') ||
            lowerTitle.contains('beginner') ||
            lowerTitle.contains('course') ||
            lowerDesc.contains('learn');

        // ULTRA-STRICT CHECK 3: Reject clearly unrelated content
        final isUnrelated = _isUltraStrictlyUnrelatedContent(
          video.title,
          courseTitle,
        );

        print(
          '  🔎 Video: "${video.title.substring(0, min(50, video.title.length))}"...',
        );
        print('     - Course match: $titleContainsCourse');
        print('     - Educational: $isEducational');
        print('     - Unrelated: $isUnrelated');

        // ULTRA-STRICT RULE: ALL conditions must pass
        if (titleContainsCourse && isEducational && !isUnrelated) {
          validatedVideos.add(video);
          print('     ✅ ACCEPTED');
        } else {
          print('     ❌ REJECTED');
        }
      }

      print(
        '📊 [STEP 4] Validation complete: ${validatedVideos.length}/${videos.length} videos passed ultra-strict filters',
      );

      if (validatedVideos.isEmpty) {
        print(
          '⚠️ [WARNING] No videos passed ultra-strict validation for $courseTitle ($language)',
        );
        return;
      }

      // STEP 5: Insert ONLY validated videos with ULTRA-STRICT duplication checking
      print(
        '🔍 [STEP 5] Inserting validated videos into database with ULTRA-STRICT checks...',
      );
      int insertedCount = 0;
      int skippedCount = 0;

      for (var video in validatedVideos) {
        try {
          // ULTRA-STRICT: Check if reel already exists with MULTIPLE matching criteria
          final isNumericId = int.tryParse(courseId) != null;

          // Build query with MULTIPLE conditions to ensure exact match
          final query = Supabase.instance.client
              .from('course_reels')
              .select()
              .eq('video_id', video.id)
              .eq('language', language)
              .eq(
                'course_title',
                courseTitle,
              ); // MUST match course title exactly

          // Add course_id condition only if it's a numeric ID
          if (isNumericId) {
            query.eq('course_id', int.parse(courseId));
          }

          final existingReels = await query;

          if ((existingReels as List).isEmpty) {
            // Insert new reel with ALL required fields
            final insertData = {
              'course_title': courseTitle,
              'video_id': video.id,
              'title': video.title,
              'description': video.description ?? '',
              'language': language, // MANDATORY
              'likes': 0,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            };

            // Add course_id only if it's a numeric ID
            if (isNumericId) {
              insertData['course_id'] = int.parse(courseId);
            }

            await Supabase.instance.client
                .from('course_reels')
                .insert(insertData);

            print('✅ [SUCCESS] Inserted reel: ${video.title}');
            insertedCount++;
          } else {
            print('ℹ️ [SKIP] Reel already exists: ${video.title}');
            skippedCount++;
          }
        } catch (e, stackTrace) {
          print('❌ [ERROR] Error inserting reel ${video.title}: $e');
          print('📝 [STACK TRACE] $stackTrace');
          // Continue with other videos
        }
      }

      print(
        '🎉 [COMPLETED] Course reel population for $courseTitle ($language):',
      );
      print('   - Inserted: $insertedCount new reels');
      print('   - Skipped: $skippedCount (already exist)');
      print('   - Total validated: ${validatedVideos.length}');
      print('═' * 100);
    } catch (e, stackTrace) {
      print('💥 [FATAL ERROR] Error populating course reels: $e');
      print('📝 [STACK TRACE] $stackTrace');
      rethrow;
    }
  }

  /// ULTRA-STRICT Check if a video is unrelated to the course topic
  bool _isUltraStrictlyUnrelatedContent(String videoTitle, String courseTitle) {
    final lowerTitle = videoTitle.toLowerCase();
    final lowerCourse = courseTitle.toLowerCase();

    // ULTRA-STRICT: If course is Python, reject ALL other programming languages and web technologies
    if (lowerCourse.contains('python')) {
      final otherLanguages = [
        'java',
        'javascript',
        'nodejs',
        'c++',
        'cpp',
        'c#',
        'csharp',
        'php',
        'ruby',
        'go',
        'golang',
        'rust',
        'kotlin',
        'swift',
        'objective-c',
        'scala',
        'perl',
        'r programming',
        'matlab',
      ];

      for (final lang in otherLanguages) {
        if (lowerTitle.contains(lang)) {
          return true;
        }
      }

      // Also reject web technologies
      final webTech = [
        'html',
        'css',
        'react',
        'angular',
        'vue',
        'jquery',
        'typescript',
        'frontend',
        'backend',
        'fullstack',
        'design',
        'ux',
        'ui',
      ];

      for (final tech in webTech) {
        if (lowerTitle.contains(tech)) {
          return true;
        }
      }
    }
    // ULTRA-STRICT: If course is Java, reject ALL other programming languages
    else if (lowerCourse.contains('java') &&
        !lowerCourse.contains('javascript')) {
      final otherLanguages = [
        'python',
        'javascript',
        'c++',
        'cpp',
        'c#',
        'csharp',
        'php',
        'ruby',
        'go',
        'golang',
        'rust',
        'kotlin',
        'swift',
        'objective-c',
        'scala',
        'perl',
        'r programming',
        'matlab',
      ];

      for (final lang in otherLanguages) {
        if (lowerTitle.contains(lang)) {
          return true;
        }
      }
    }
    // ULTRA-STRICT: If course is JavaScript, reject ALL other programming languages
    else if (lowerCourse.contains('javascript')) {
      final otherLanguages = [
        'python',
        'java',
        'c++',
        'cpp',
        'c#',
        'csharp',
        'php',
        'ruby',
        'go',
        'golang',
        'rust',
        'kotlin',
        'swift',
        'objective-c',
        'scala',
        'perl',
        'r programming',
        'matlab',
      ];

      for (final lang in otherLanguages) {
        if (lowerTitle.contains(lang)) {
          return true;
        }
      }
    }
    // ULTRA-STRICT: Handle other common courses similarly
    else if (lowerCourse.contains('c++') || lowerCourse.contains('cpp')) {
      final conflicting = [
        'python',
        'java',
        'javascript',
        'c#',
        'csharp',
        'php',
        'ruby',
        'go',
        'golang',
        'rust',
        'kotlin',
        'swift',
        'objective-c',
        'scala',
        'perl',
        'r programming',
        'matlab',
        'html',
        'css',
        'react',
        'angular',
      ];

      for (final term in conflicting) {
        if (lowerTitle.contains(term)) {
          return true;
        }
      }
    }

    // ULTRA-STRICT: Common unrelated content that should NEVER appear
    const nonCourseKeywords = [
      'unboxing',
      'review',
      'vs ',
      'comparison',
      'merchandise',
      'giveaway',
      'sponsored',
      'vlog',
      'podcast',
      'reaction',
      'commentary',
      'music video',
      'movie',
      'trailer',
      'interview',
      'parody',
      'challenge',
      'compilation',
      'playlist',
      'best of',
      'top 10',
      'ranked',
    ];

    for (final keyword in nonCourseKeywords) {
      if (lowerTitle.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  /// Manually add a course reel with validation and duplicate checking
  Future<void> addManualReel({
    required String courseId,
    required String courseTitle,
    required String videoId,
    required String title,
    required String description,
    required String language,
  }) async {
    try {
      print('➕ [INFO] Adding manual reel for course: $courseTitle ($language)');

      // Validate inputs
      if (courseId.isEmpty ||
          courseTitle.isEmpty ||
          videoId.isEmpty ||
          title.isEmpty ||
          language.isEmpty) {
        throw Exception(
          'Invalid input parameters: courseId, courseTitle, videoId, title, and language are required',
        );
      }

      // Check if reel already exists with enhanced validation
      final isNumericId = int.tryParse(courseId) != null;

      // First, validate that the video exists and is accessible
      final isAccessible = await _youtubeService.isVideoAccessible(videoId);
      if (!isAccessible) {
        throw Exception(
          'Video with ID $videoId is not accessible or does not exist',
        );
      }

      final query = Supabase.instance.client
          .from('course_reels')
          .select()
          .eq('video_id', videoId)
          .eq('language', language);

      // Add the appropriate course identifier
      if (isNumericId) {
        query.eq('course_id', int.parse(courseId));
      } else {
        query.eq('course_title', courseTitle);
      }

      final existingReels = await query;

      if ((existingReels as List).isNotEmpty) {
        print('ℹ️ [INFO] Reel already exists: $title');
        return;
      }

      // Insert new reel
      final insertData = {
        'course_title': courseTitle,
        'video_id': videoId,
        'title': title,
        'description': description,
        'language': language,
        'likes': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add course_id only if it's a numeric ID
      if (isNumericId) {
        insertData['course_id'] = int.parse(courseId);
      }

      await Supabase.instance.client.from('course_reels').insert(insertData);

      print('✅ [SUCCESS] Added manual reel: $title');
    } catch (e, stackTrace) {
      print('💥 [FATAL ERROR] Error adding manual reel: $e');
      print('📝 [STACK TRACE] $stackTrace');
      rethrow;
    }
  }

  /// Get personalized reels based on user's liked content with enhanced algorithm
  Future<List<CourseReel>> getPersonalizedReels({
    required String userId,
    int limit = 30, // Increase limit for better personalization
  }) async {
    try {
      print(
        '🔍 [DEBUG] Getting personalized reels for userId: $userId with limit: $limit',
      );

      // Validate inputs
      if (userId.isEmpty) {
        throw Exception('User ID is required');
      }

      // Get user's liked reels to determine preferences
      final likedReels = await _supabaseService.getUserLikedReels();
      print('📊 [STATS] User has liked ${likedReels.length} reels');

      if (likedReels.isEmpty) {
        // If no liked reels, return recent reels
        print('ℹ️ [INFO] No liked reels found, returning recent reels');
        final response = await Supabase.instance.client
            .from('course_reels')
            .select()
            .order('created_at', ascending: false)
            .limit(limit);

        final result =
            (response as List)
                .map((data) => CourseReel.fromJson(data))
                .toList();

        print('✅ [SUCCESS] Retrieved ${result.length} recent reels');
        return result;
      }

      // Enhanced personalization algorithm:
      // 1. Get detailed information about liked reels to understand user preferences
      print('🔍 [DEBUG] Analyzing user preferences from liked reels');
      final likedReelsData = await Supabase.instance.client
          .from('course_reels')
          .select()
          .inFilter('id', likedReels)
          .limit(100);

      // 2. Calculate preference weights for languages and courses
      final languageWeights = <String, int>{};
      final courseWeights = <String, int>{};
      final categoryPreferences = <String, int>{};

      for (var reel in likedReelsData as List) {
        final language = reel['language'] as String;
        final courseId = reel['course_id'] as String;
        final courseTitle = reel['course_title'] as String;

        // Weight languages and courses based on likes
        languageWeights[language] = (languageWeights[language] ?? 0) + 1;
        courseWeights[courseId] = (courseWeights[courseId] ?? 0) + 1;

        // Extract categories from course titles (simple approach)
        if (courseTitle.toLowerCase().contains('java')) {
          categoryPreferences['java'] = (categoryPreferences['java'] ?? 0) + 1;
        } else if (courseTitle.toLowerCase().contains('python')) {
          categoryPreferences['python'] =
              (categoryPreferences['python'] ?? 0) + 1;
        } else if (courseTitle.toLowerCase().contains('javascript')) {
          categoryPreferences['javascript'] =
              (categoryPreferences['javascript'] ?? 0) + 1;
        } else if (courseTitle.toLowerCase().contains('react')) {
          categoryPreferences['react'] =
              (categoryPreferences['react'] ?? 0) + 1;
        } else if (courseTitle.toLowerCase().contains('flutter')) {
          categoryPreferences['flutter'] =
              (categoryPreferences['flutter'] ?? 0) + 1;
        }
      }

      print('📊 [PREFERENCES] Language weights: $languageWeights');
      print('📊 [PREFERENCES] Course weights: $courseWeights');
      print('📊 [PREFERENCES] Category preferences: $categoryPreferences');

      // 3. Sort preferences by weight to prioritize strongest preferences
      final sortedLanguages =
          languageWeights.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      final sortedCourses =
          courseWeights.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      final sortedCategories =
          categoryPreferences.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      // 4. Build query with weighted preferences using proper Supabase syntax
      print('🔍 [DEBUG] Building personalized query with weighted preferences');

      // Create OR conditions for top preferences
      final orConditions = <String>[];

      // Add top 3 language preferences
      for (int i = 0; i < sortedLanguages.length && i < 3; i++) {
        orConditions.add('language.eq.${sortedLanguages[i].key}');
      }

      // Add top 3 course preferences
      for (int i = 0; i < sortedCourses.length && i < 3; i++) {
        orConditions.add('course_id.eq.${sortedCourses[i].key}');
      }

      // Add category-based preferences if we have them
      if (sortedCategories.isNotEmpty) {
        final topCategory = sortedCategories.first.key;
        orConditions.add('course_title.ilike.*$topCategory*');
      }

      // 5. Execute the enhanced query with proper Supabase OR syntax
      print('🔍 [DEBUG] Executing enhanced personalized query');

      String orClause = orConditions.join(',');
      print('🔍 [DEBUG] OR clause: $orClause');

      final response = await Supabase.instance.client
          .from('course_reels')
          .select()
          .or(orClause)
          .order('likes', ascending: false)
          .order('created_at', ascending: false)
          .limit(limit);

      final result =
          (response as List).map((data) => CourseReel.fromJson(data)).toList();

      print(
        '✅ [SUCCESS] Retrieved ${result.length} personalized reels with enhanced algorithm',
      );
      return result;
    } catch (e, stackTrace) {
      print('❌ [ERROR] Error getting personalized reels: $e');
      print('📝 [STACK TRACE] $stackTrace');
      rethrow;
    }
  }

  /// Get trending reels across all courses
  Future<List<CourseReel>> getTrendingReels({int limit = 20}) async {
    try {
      print('🔍 [DEBUG] Getting trending reels with limit: $limit');

      // Validate inputs
      if (limit <= 0) {
        throw Exception('Limit must be greater than 0');
      }

      final response = await Supabase.instance.client
          .from('course_reels')
          .select()
          .order('likes', ascending: false)
          .order('created_at', ascending: false)
          .limit(limit);

      final result =
          (response as List).map((data) => CourseReel.fromJson(data)).toList();

      print('✅ [SUCCESS] Retrieved ${result.length} trending reels');
      return result;
    } catch (e, stackTrace) {
      print('❌ [ERROR] Error getting trending reels: $e');
      print('📝 [STACK TRACE] $stackTrace');
      rethrow;
    }
  }

  /// Get reels for a specific course
  Future<List<CourseReel>> getCourseReels({
    required String courseId,
    String? language,
    int limit = 50,
  }) async {
    try {
      print(
        '🔍 [DEBUG] Getting course reels for courseId: $courseId, language: $language, limit: $limit',
      );

      // Validate inputs
      if (courseId.isEmpty) {
        throw Exception('Course ID is required');
      }

      if (limit <= 0) {
        throw Exception('Limit must be greater than 0');
      }

      // Use the SupabaseService method which handles the query correctly
      final response = await _supabaseService.getCourseReels(
        courseId: courseId,
        language: language,
      );

      final result = <CourseReel>[];
      for (var data in response) {
        result.add(CourseReel.fromJson(data as Map<String, dynamic>));
      }

      print('✅ [SUCCESS] Retrieved ${result.length} course reels');
      return result;
    } catch (e, stackTrace) {
      print('❌ [ERROR] Error getting course reels: $e');
      print('📝 [STACK TRACE] $stackTrace');
      rethrow;
    }
  }
}
