import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class YouTubeService {
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';

  Future<List<String>> searchShorts(String query) async {
    if (AppConstants.youtubeApiKey.contains('YOUR_')) {
       // Return demo IDs if key not set (Fallbacks)
       print('YouTube API Key missing. Using demo videos.');
       return [
         'pHWj3C4s9W8', 
         'fT2KhJ8W-Kg', 
         'RefxXQvTv7c', // Python
         'F9UC9DY-vIU', // Dart
       ];
    }
    
    // videoDuration=short (< 4 min). Ideally we want actual Shorts.
    // Searching "#shorts" helps.
    // Strict Mode: Add "tutorial", "learn", "course" to query.
    // And filter by Category ID 27 (Education).
    final refinedQuery = '$query learn programming tutorial course #shorts';
    final q = Uri.encodeComponent(refinedQuery);
    
    // videoCategoryId=27 is 'Education'. safeSearch=strict.
    final url = '$_baseUrl/search?part=id&q=$q&type=video&videoDuration=short&videoCategoryId=27&safeSearch=strict&maxResults=20&key=${AppConstants.youtubeApiKey}';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List;
        return items.map<String>((item) => item['id']['videoId'] as String).toList();
      } else {
        print('YouTube API Error: ${response.body}');
        return [];
      }
    } catch (e) {
      print('YouTube API Exception: $e');
      return [];
    }
  }

  Future<String?> searchLongVideo(String query) async {
    if (AppConstants.youtubeApiKey.contains('YOUR_')) {
       return 'fT2KhJ8W-Kg'; // Demo
    }
    
    // Search for medium/long videos. 
    final refinedQuery = '$query tutorial course';
    final q = Uri.encodeComponent(refinedQuery);
    
    // videoCategoryId=27 (Education) is preferred.
    final url = '$_baseUrl/search?part=id&q=$q&type=video&videoDuration=medium&videoCategoryId=27&safeSearch=strict&maxResults=1&key=${AppConstants.youtubeApiKey}';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List;
        if (items.isNotEmpty) {
           return items[0]['id']['videoId'] as String;
        }
      }
    } catch (e) {
      print('YouTube Long Video Error: $e');
    }
    return null;
  }
}
