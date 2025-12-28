import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'dart:async';
import 'dart:io';

/// ULTRA-STRICT YouTube Service with aggressive filtering
/// This service FORCES YouTube to return ONLY relevant videos for each course
class YouTubeServiceUltraStrict {
  // Multiple API keys for redundancy
  final List<String> _apiKeys = [
    'AIzaSyDJSU4CNx56jPHYyVrpU32PwAeL8B60H20',
    'AIzaSyDJSU4CNx56jPHYyVrpU32PwAeL8B60H20',
  ];

  int _currentKeyIndex = 0;
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';
  static const int _timeoutSeconds = 15;

  YouTubeServiceUltraStrict() {
    if (_apiKeys.isEmpty) {
      print('🔴 CRITICAL: No YouTube API keys configured!');
    }
  }

  /// ULTRA-STRICT: Map course names to EXACT YouTube search queries
  /// This ensures we get the EXACT videos for each course
  String _buildUltraStrictQuery(String courseTitle, String language) {
    final lowerCourse = courseTitle.toLowerCase().trim();

    // Course-specific query mappings for MAXIMUM accuracy
    final queryMap = {
      'python': {
        'query': 'python programming tutorial for beginners complete course',
        'exclude':
            '-java -javascript -cpp -csharp -php -html -css -web -golang -rust -kotlin -swift -objective-c -ruby -scala -perl -r-programming -matlab',
      },
      'java': {
        'query': 'java programming tutorial for beginners complete course',
        'exclude':
            '-python -javascript -cpp -csharp -php -html -css -web -golang -rust -kotlin -swift -objective-c -ruby -scala -perl',
      },
      'javascript': {
        'query':
            'javascript programming tutorial for beginners complete course',
        'exclude':
            '-python -java -cpp -csharp -php -golang -rust -kotlin -swift -objective-c -ruby -scala -perl -html -css -web-design',
      },
      'c++': {
        'query': 'c++ programming tutorial for beginners complete course',
        'exclude':
            '-python -java -javascript -csharp -php -golang -rust -kotlin -swift -ruby -scala -perl -web',
      },
      'cpp': {
        'query': 'cpp programming tutorial for beginners complete course',
        'exclude':
            '-python -java -javascript -csharp -php -golang -rust -kotlin -swift -ruby -scala -perl -web',
      },
      'c#': {
        'query': 'csharp programming tutorial for beginners complete course',
        'exclude':
            '-python -java -javascript -cpp -php -golang -rust -kotlin -swift -ruby -scala -perl -web',
      },
      'csharp': {
        'query': 'csharp programming tutorial for beginners complete course',
        'exclude':
            '-python -java -javascript -cpp -php -golang -rust -kotlin -swift -ruby -scala -perl -web',
      },
      'php': {
        'query': 'php programming tutorial for beginners complete course',
        'exclude':
            '-python -java -javascript -cpp -csharp -golang -rust -kotlin -swift -ruby -scala -perl -native',
      },
      'ruby': {
        'query': 'ruby programming tutorial for beginners complete course',
        'exclude':
            '-python -java -javascript -cpp -csharp -php -golang -rust -kotlin -swift -scala -perl',
      },
      'go': {
        'query': 'go golang programming tutorial for beginners complete course',
        'exclude':
            '-python -java -javascript -cpp -csharp -php -ruby -rust -kotlin -swift -scala -perl',
      },
      'rust': {
        'query': 'rust programming tutorial for beginners complete course',
        'exclude':
            '-python -java -javascript -cpp -csharp -php -ruby -golang -kotlin -swift -scala -perl',
      },
      'kotlin': {
        'query': 'kotlin programming tutorial for beginners complete course',
        'exclude':
            '-python -java -javascript -cpp -csharp -php -ruby -golang -rust -swift -scala -perl',
      },
      'swift': {
        'query': 'swift programming tutorial for beginners complete course',
        'exclude':
            '-python -java -javascript -cpp -csharp -php -ruby -golang -rust -kotlin -scala -perl -objective-c',
      },
    };

    // Get the specific query for this course, or use generic if not found
    final courseQuery = queryMap[lowerCourse];

    if (courseQuery != null) {
      return '${courseQuery['query']} ${courseQuery['exclude']}';
    }

    // Fallback for unknown courses
    return '$courseTitle programming tutorial for beginners -unrelated -review -comparison';
  }

  /// Search for videos with ULTRA-STRICT filtering
  Future<List<YouTubeVideo>> searchVideosUltraStrict(
    String courseTitle, {
    String? language,
  }) async {
    print('🔴 ULTRA-STRICT VIDEO SEARCH');
    print('═' * 80);
    print('📚 Course: $courseTitle');
    print('🌍 Language: ${language ?? "English"}');

    if (_apiKeys.isEmpty) {
      return _getFallbackVideos(courseTitle);
    }

    try {
      // Build ULTRA-STRICT query based on course type
      final strictQuery = _buildUltraStrictQuery(
        courseTitle,
        language ?? 'English',
      );
      print('🔍 QUERY: $strictQuery');

      final apiKey = _getCurrentApiKey();
      final url = Uri.parse(
        '$_baseUrl/search'
        '?part=snippet,contentDetails'
        '&q=${Uri.encodeQueryComponent(strictQuery)}'
        '&type=video'
        '&videoDuration=short'
        '&maxResults=100'
        '&relevanceLanguage=${language ?? "en"}'
        '&key=$apiKey',
      );

      print(
        '🌐 API Request: ${url.toString().substring(0, min(100, url.toString().length))}...',
      );

      final response = await http
          .get(url)
          .timeout(Duration(seconds: _timeoutSeconds));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final videos = _parseVideoData(data);
        print('✅ Got ${videos.length} videos from YouTube API');

        // ULTRA-STRICT filtering
        final filtered = _ultraStrictFilter(videos, courseTitle);
        print('✅ After ULTRA-STRICT filtering: ${filtered.length} videos');

        return filtered;
      } else {
        print('❌ YouTube API error: ${response.statusCode}');
        return _getFallbackVideos(courseTitle);
      }
    } catch (e) {
      print('❌ Error: $e');
      return _getFallbackVideos(courseTitle);
    }
  }

  /// ULTRA-STRICT filtering - multiple validation layers
  List<YouTubeVideo> _ultraStrictFilter(
    List<YouTubeVideo> videos,
    String courseTitle,
  ) {
    print('🔍 Applying ULTRA-STRICT filters...');

    final filtered = <YouTubeVideo>[];

    for (final video in videos) {
      // FILTER 1: MUST contain exact course name
      if (!_containsCourseKeyword(video.title, courseTitle)) {
        print('❌ REJECTED: No course keyword in "${video.title}"');
        continue;
      }

      // FILTER 2: MUST be educational
      if (!_isEducationalContent(video.title, video.description)) {
        print('❌ REJECTED: Not educational "${video.title}"');
        continue;
      }

      // FILTER 3: MUST NOT contain other programming language keywords
      if (_containsOtherLanguageKeywords(video.title, courseTitle)) {
        print('❌ REJECTED: Contains other language keyword "${video.title}"');
        continue;
      }

      // FILTER 4: MUST be reasonable duration
      if (video.duration != null) {
        final seconds = _parseDurationSeconds(video.duration!);
        if (seconds != null && (seconds < 120 || seconds > 3600)) {
          print('❌ REJECTED: Bad duration (${seconds}s) "${video.title}"');
          continue;
        }
      }

      // FILTER 5: MUST NOT be review/reaction/unboxing
      if (_isNonEducational(video.title)) {
        print('❌ REJECTED: Non-educational "${video.title}"');
        continue;
      }

      print('✅ ACCEPTED: "${video.title}"');
      filtered.add(video);
    }

    return filtered;
  }

  /// Check if video contains course keyword
  bool _containsCourseKeyword(String title, String courseTitle) {
    final lowerTitle = title.toLowerCase();
    final lowerCourse = courseTitle.toLowerCase();

    // Exact keyword mappings
    final keywords = {
      'python': ['python'],
      'java': ['java', 'jvm'],
      'javascript': ['javascript', 'js', 'nodejs', 'node.js'],
      'c++': ['c++', 'cpp'],
      'c#': ['c#', 'csharp', 'dotnet'],
      'php': ['php'],
      'ruby': ['ruby', 'rails'],
      'go': ['go', 'golang'],
      'rust': ['rust'],
      'kotlin': ['kotlin'],
      'swift': ['swift'],
    };

    final courseKeywords = keywords[lowerCourse] ?? [lowerCourse];

    for (final keyword in courseKeywords) {
      if (lowerTitle.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  /// Check if content is educational
  bool _isEducationalContent(String title, String? description) {
    final lowerTitle = title.toLowerCase();
    final lowerDesc = (description ?? '').toLowerCase();

    final educationalKeywords = [
      'tutorial',
      'course',
      'learn',
      'introduction',
      'basics',
      'beginner',
      'fundamentals',
      'programming',
      'how to',
      'guide',
      'lesson',
    ];

    for (final keyword in educationalKeywords) {
      if (lowerTitle.contains(keyword) || lowerDesc.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  /// Check if title contains other language keywords (indicate wrong course)
  bool _containsOtherLanguageKeywords(String title, String courseTitle) {
    final lowerTitle = title.toLowerCase();
    final lowerCourse = courseTitle.toLowerCase();

    // Map of languages to their keywords
    final languageKeywords = {
      'python': ['java', 'cpp', 'c++', 'csharp', 'php', 'ruby', 'go', 'rust'],
      'java': ['python', 'cpp', 'c++', 'csharp', 'php', 'ruby', 'go', 'rust'],
      'javascript': ['python', 'java', 'cpp', 'c++', 'csharp', 'php', 'ruby'],
      'c++': ['python', 'java', 'javascript', 'csharp', 'php', 'ruby'],
      'c#': ['python', 'java', 'javascript', 'cpp', 'c++', 'php', 'ruby'],
      'php': ['python', 'java', 'javascript', 'cpp', 'c++', 'csharp', 'ruby'],
      'ruby': ['python', 'java', 'javascript', 'cpp', 'c++', 'csharp', 'php'],
      'go': ['python', 'java', 'javascript', 'cpp', 'c++', 'csharp', 'php'],
      'rust': ['python', 'java', 'javascript', 'cpp', 'c++', 'csharp', 'php'],
    };

    final excludedKeywords = languageKeywords[lowerCourse] ?? [];

    // Strong exclusions for web technologies when course is programming language
    if (!lowerCourse.contains('javascript')) {
      excludedKeywords.addAll(['html', 'css', 'react', 'angular', 'vue']);
    }

    for (final keyword in excludedKeywords) {
      if (lowerTitle.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  /// Check if content is non-educational
  bool _isNonEducational(String title) {
    final lowerTitle = title.toLowerCase();

    final nonEducationalKeywords = [
      'review',
      'unboxing',
      'reaction',
      'commentary',
      'vlog',
      'podcast',
      'interview',
      'music',
      'movie',
      'trailer',
      'comparison',
      'vs ',
      'sponsored',
      'merchandise',
      'giveaway',
    ];

    for (final keyword in nonEducationalKeywords) {
      if (lowerTitle.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  /// Parse duration string to seconds
  int? _parseDurationSeconds(String duration) {
    try {
      final regExp = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
      final match = regExp.firstMatch(duration);
      if (match == null) return null;

      final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
      final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
      final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;

      return hours * 3600 + minutes * 60 + seconds;
    } catch (e) {
      return null;
    }
  }

  String _getCurrentApiKey() {
    final key = _apiKeys[_currentKeyIndex];
    _currentKeyIndex = (_currentKeyIndex + 1) % _apiKeys.length;
    return key;
  }

  List<YouTubeVideo> _parseVideoData(Map<String, dynamic> data) {
    final videos = <YouTubeVideo>[];
    if (data['items'] != null) {
      for (final item in data['items']) {
        try {
          final snippet = item['snippet'];
          final video = YouTubeVideo(
            id: item['id']['videoId'] ?? '',
            title: snippet['title'] ?? '',
            description: snippet['description'] ?? '',
            thumbnailUrl: snippet['thumbnails']?['medium']?['url'] ?? '',
            channelTitle: snippet['channelTitle'] ?? '',
            publishedAt: snippet['publishedAt'] ?? '',
            duration: item['contentDetails']?['duration'],
          );
          videos.add(video);
        } catch (e) {
          // Skip malformed videos
        }
      }
    }
    return videos;
  }

  List<YouTubeVideo> _getFallbackVideos(String courseTitle) {
    print('⚠️ Using fallback videos for: $courseTitle');
    return [];
  }
}

class YouTubeVideo {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String channelTitle;
  final String publishedAt;
  final String? duration;

  YouTubeVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.publishedAt,
    this.duration,
  });

  String get watchUrl => 'https://www.youtube.com/watch?v=$id';
  String get embedUrl => 'https://www.youtube.com/embed/$id';
}
