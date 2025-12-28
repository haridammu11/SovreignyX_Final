import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'groq_service.dart';
import 'youtube_service_ultra_strict.dart';
import 'web_scraper_service.dart' as web_scraper;
import '../utils/constants.dart';

/// ULTRA-STRICT AI Course Service
/// Ensures that ONLY correct videos are retrieved for each course
class AICourseServiceUltraStrict {
  final GroqService _aiService;
  final YouTubeServiceUltraStrict _youtubeService;
  final web_scraper.WebScraperService _webScraperService;

  AICourseServiceUltraStrict({required GroqService aiService})
    : _aiService = aiService,
      _youtubeService = YouTubeServiceUltraStrict(),
      _webScraperService = web_scraper.WebScraperService();

  /// Generate course content
  Future<CourseContent> generateCourseContent(String courseTopic) async {
    print('🎓 ULTRA-STRICT: Generating course for: $courseTopic');
    try {
      final prompt = '''
${AppConstants.defaultSystemPrompt}

Create a course structure for "${courseTopic}".

RETURN EXACTLY THIS FORMAT:

## COURSE OVERVIEW
- **Title**: ${courseTopic}
- **Description**: Brief overview
- **Duration**: Self-paced
- **Skill Level**: Beginner/Intermediate/Advanced
- **Prerequisites**: None

## LEARNING OBJECTIVES
1. Understand fundamentals
2. Apply principles
3. Build projects

## COURSE MODULES
1. **Introduction to ${courseTopic}**: Basics (1 hour)
2. **Core Concepts of ${courseTopic}**: Principles (2 hours)
3. **Advanced ${courseTopic}**: Applications (2 hours)

## ASSESSMENT METHODS
- Practical exercises
- Self-assessment quizzes

Return ONLY this structure.
''';

      final response = await _aiService
          .sendMessage(prompt)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('AI timeout'),
          );

      return _parseCourseContent(response, courseTopic);
    } catch (e) {
      print('❌ Error: $e');
      return _createFallbackCourseContent(courseTopic);
    }
  }

  /// ULTRA-STRICT: Search for EXACT course videos
  /// This method uses ULTRA-STRICT filtering to get ONLY the right videos
  Future<List<YouTubeVideoModel>> searchRelevantVideosUltraStrict(
    String topic, {
    String? courseContext,
  }) async {
    print('🔴 ULTRA-STRICT VIDEO SEARCH');
    print('═' * 80);
    print('📝 Topic: $topic');
    if (courseContext != null) {
      print('📚 Course Context: $courseContext');
    }

    try {
      // Extract the EXACT course name
      final baseCourseName = courseContext ?? _extractBaseCourseName(topic);
      print('🎯 Base Course: $baseCourseName');

      // Use ULTRA-STRICT YouTube service
      final youtubeVideos = await _youtubeService.searchVideosUltraStrict(
        baseCourseName,
        language: 'English',
      );

      print(
        '📊 YouTube returned ${youtubeVideos.length} videos (already ULTRA-STRICT filtered)',
      );

      // Convert to our model
      final converted = <YouTubeVideoModel>[];
      for (final video in youtubeVideos) {
        try {
          final model = YouTubeVideoModel(
            id: video.id,
            title: video.title,
            url: video.watchUrl,
            description: video.description,
          );
          converted.add(model);
          print('✅ Added: ${video.title}');
        } catch (e) {
          print('❌ Failed to convert: $e');
        }
      }

      print('✅ FINAL: ${converted.length} videos ready');
      return converted;
    } catch (e, st) {
      print('❌ ERROR: $e');
      print('$st');
      return [];
    }
  }

  String _extractBaseCourseName(String topic) {
    // Extract EXACT course name
    final lowerTopic = topic.toLowerCase();

    // Direct mappings for maximum accuracy
    const courseMap = {
      'python': 'python',
      'java': 'java',
      'javascript': 'javascript',
      'c++': 'c++',
      'cpp': 'cpp',
      'c#': 'c#',
      'csharp': 'csharp',
      'php': 'php',
      'ruby': 'ruby',
      'go': 'go',
      'rust': 'rust',
      'kotlin': 'kotlin',
      'swift': 'swift',
    };

    for (final entry in courseMap.entries) {
      if (lowerTopic.contains(entry.key)) {
        return entry.value;
      }
    }

    return topic;
  }

  CourseContent _parseCourseContent(String content, String topic) {
    final modules = <Module>[];

    modules.add(
      Module(
        title: 'Introduction to $topic',
        description: 'Get started with $topic',
        topics: ['Basics', 'Setup', 'First Program'],
        estimatedTime: '1 hour',
        videos: [],
        resources: [],
      ),
    );

    modules.add(
      Module(
        title: 'Core Concepts',
        description: 'Learn core concepts of $topic',
        topics: ['Variables', 'Functions', 'Classes'],
        estimatedTime: '2 hours',
        videos: [],
        resources: [],
      ),
    );

    modules.add(
      Module(
        title: 'Advanced $topic',
        description: 'Advanced topics and best practices',
        topics: ['Design Patterns', 'Performance', 'Testing'],
        estimatedTime: '2 hours',
        videos: [],
        resources: [],
      ),
    );

    return CourseContent(
      title: topic,
      description: 'Comprehensive $topic course',
      modules: modules,
      additionalResources: AdditionalResources(
        textbooks: [],
        onlineResources: [],
        tools: [],
      ),
    );
  }

  CourseContent _createFallbackCourseContent(String topic) {
    return _parseCourseContent('', topic);
  }
}

// Data models
class CourseContent {
  final String title;
  final String description;
  final List<Module> modules;
  final AdditionalResources additionalResources;

  CourseContent({
    required this.title,
    required this.description,
    required this.modules,
    required this.additionalResources,
  });
}

class Module {
  final String title;
  final String description;
  final List<String> topics;
  final String estimatedTime;
  final List<YouTubeVideoModel> videos;
  final List<String> resources;

  Module({
    required this.title,
    required this.description,
    required this.topics,
    required this.estimatedTime,
    required this.videos,
    required this.resources,
  });
}

class YouTubeVideoModel {
  final String id;
  final String title;
  final String url;
  final String description;

  YouTubeVideoModel({
    required this.id,
    required this.title,
    required this.url,
    required this.description,
  });
}

class AdditionalResources {
  final List<dynamic> textbooks;
  final List<dynamic> onlineResources;
  final List<String> tools;

  AdditionalResources({
    required this.textbooks,
    required this.onlineResources,
    required this.tools,
  });
}
