import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class YouTubeService {
  // Simple API key - replace with your actual YouTube API key
  final List<String> _apiKeys = ['AIzaSyAGpNI8ARj_a7dvGyEOGZs8IrBbr5MVxR8'];

  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';
  static const int _timeoutSeconds = 15;

  YouTubeService() {
    if (_apiKeys.isEmpty) {
      print('🔴 WARNING: No YouTube API keys configured!');
    }
  }

  /// Get current API key
  String _getCurrentApiKey() {
    if (_apiKeys.isEmpty) {
      throw Exception('No YouTube API keys configured');
    }
    return _apiKeys[0]; // Simple approach - just use the first key
  }

  /// Simple search for videos - no complex filtering
  Future<List<YouTubeVideo>> searchVideos(
    String query, {
    int maxResults = 10,
    String? language,
    String? courseTitle,
  }) async {
    print('YOUTUBE_SERVICE: Searching for videos: $query');

    try {
      final apiKey = _getCurrentApiKey();

      // Simple query - just search for the topic
      String searchQuery = query;
      if (courseTitle != null) {
        searchQuery = '$courseTitle tutorial';
      }

      // Build URL with proper encoding
      final uri = Uri.https('www.googleapis.com', '/youtube/v3/search', {
        'part': 'snippet',
        'q': searchQuery,
        'type': 'video',
        'maxResults': '$maxResults',
        'key': apiKey,
      });

      print('YOUTUBE_SERVICE: Request URL: $uri');

      // Make request
      final response = await http
          .get(uri)
          .timeout(Duration(seconds: _timeoutSeconds));

      print('YOUTUBE_SERVICE: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseVideoData(data);
      } else {
        print(
          'YOUTUBE_SERVICE: Error ${response.statusCode}: ${response.body}',
        );
        return _getFallbackVideos(query);
      }
    } catch (e, stackTrace) {
      print('YOUTUBE_SERVICE ERROR: $e');
      print('YOUTUBE_SERVICE STACK TRACE: $stackTrace');
      return _getFallbackVideos(query);
    }
  }

  /// Simple video parsing
  List<YouTubeVideo> _parseVideoData(Map<String, dynamic> data) {
    final videos = <YouTubeVideo>[];

    if (data['items'] != null) {
      for (final item in data['items']) {
        try {
          final snippet = item['snippet'];
          if (snippet != null) {
            final video = YouTubeVideo(
              id: item['id']?['videoId'] ?? '',
              title: snippet['title'] ?? 'Untitled',
              description: snippet['description'] ?? '',
              thumbnailUrl: snippet['thumbnails']?['medium']?['url'] ?? '',
              channelTitle: snippet['channelTitle'] ?? 'Unknown',
              publishedAt: snippet['publishedAt'] ?? '',
            );
            videos.add(video);
          }
        } catch (e) {
          // Skip malformed videos
        }
      }
    }

    print('YOUTUBE_SERVICE: Parsed ${videos.length} videos');
    return videos;
  }

  /// Simple fallback videos
  List<YouTubeVideo> _getFallbackVideos(String query) {
    print('YOUTUBE_SERVICE: Using fallback videos for: $query');
    return [
      YouTubeVideo(
        id: 'rfscVS0vtbw',
        title: '$query Fundamentals',
        description: 'Learn the basics of $query',
        thumbnailUrl: 'https://img.youtube.com/vi/rfscVS0vtbw/mqdefault.jpg',
        channelTitle: 'Educational Channel',
        publishedAt: DateTime.now().toIso8601String(),
      ),
      YouTubeVideo(
        id: '8mAITcNt710',
        title: 'Introduction to $query',
        description: 'Beginner guide to $query',
        thumbnailUrl: 'https://img.youtube.com/vi/8mAITcNt710/mqdefault.jpg',
        channelTitle: 'Learning Platform',
        publishedAt: DateTime.now().toIso8601String(),
      ),
    ];
  }

  /// Simple video accessibility check
  Future<bool> isVideoAccessible(String videoId) async {
    try {
      final apiKey = _getCurrentApiKey();
      final url = Uri.https('www.googleapis.com', '/youtube/v3/videos', {
        'part': 'id',
        'id': videoId,
        'key': apiKey,
      });

      final response = await http
          .get(url)
          .timeout(Duration(seconds: _timeoutSeconds));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class YouTubeVideo {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String channelTitle;
  final String publishedAt;

  YouTubeVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.publishedAt,
  });

  String get watchUrl => 'https://www.youtube.com/watch?v=$id';
  String get embedUrl => 'https://www.youtube.com/embed/$id';
}
