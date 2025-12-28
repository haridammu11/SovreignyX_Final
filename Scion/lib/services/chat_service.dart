import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat.dart';

class ChatService {
  static const String baseUrl =
      'https://9qcb6b3j-8000.inc1.devtunnels.ms/api/chat/';
  final String? token;

  ChatService({this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Token $token',
  };

  // Get all chat rooms for the user
  Future<List<ChatRoom>> getChatRooms() async {
    final url = Uri.parse('${baseUrl}rooms/');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ChatRoom.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load chat rooms');
    }
  }

  // Get messages for a chat room
  Future<List<Message>> getMessages(int roomId) async {
    final url = Uri.parse('${baseUrl}messages/?room=$roomId');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Message.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load messages');
    }
  }

  // Send a message to a chat room
  Future<Message> sendMessage({
    required int roomId,
    required int senderId,
    required String content,
  }) async {
    final url = Uri.parse('${baseUrl}messages/');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'room': roomId,
        'sender': senderId,
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
        'is_read': false,
      }),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Message.fromJson(data);
    } else {
      throw Exception('Failed to send message');
    }
  }

  // Get private chats for the user
  Future<List<PrivateChat>> getPrivateChats(int userId) async {
    final url = Uri.parse('${baseUrl}private-chats/?user=$userId');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => PrivateChat.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load private chats');
    }
  }

  // Get private messages for a chat
  Future<List<PrivateMessage>> getPrivateMessages(int chatId) async {
    final url = Uri.parse('${baseUrl}private-messages/?chat=$chatId');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => PrivateMessage.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load private messages');
    }
  }

  // Send a private message
  Future<PrivateMessage> sendPrivateMessage({
    required int chatId,
    required int senderId,
    required String content,
  }) async {
    final url = Uri.parse('${baseUrl}private-messages/');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'chat': chatId,
        'sender': senderId,
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
        'is_read': false,
      }),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return PrivateMessage.fromJson(data);
    } else {
      throw Exception('Failed to send private message');
    }
  }

  // Get assignment progress
  Future<List<AssignmentProgress>> getAssignments(int userId) async {
    final url = Uri.parse('${baseUrl}assignments/?user=$userId');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AssignmentProgress.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load assignments');
    }
  }

  // Update assignment progress
  Future<AssignmentProgress> updateAssignmentProgress({
    required int assignmentId,
    String? status,
    double? progressPercentage,
  }) async {
    final url = Uri.parse('${baseUrl}assignments/$assignmentId/');
    final Map<String, dynamic> updateData = {};

    if (status != null) updateData['status'] = status;
    if (progressPercentage != null)
      updateData['progress_percentage'] = progressPercentage;
    updateData['updated_at'] = DateTime.now().toIso8601String();

    final response = await http.patch(
      url,
      headers: _headers,
      body: jsonEncode(updateData),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return AssignmentProgress.fromJson(data);
    } else {
      throw Exception('Failed to update assignment progress');
    }
  }
}
