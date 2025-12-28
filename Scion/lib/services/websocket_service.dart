import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static const String baseUrl =
      'wss://9qcb6b3j-8000.inc1.devtunnels.ms/ws'; // WebSocket endpoint
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Function(Map<String, dynamic>)? _onMessageReceived;
  Function()? _onConnectionClosed;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  // Connect to WebSocket server
  Future<void> connect({
    String? token,
    Function(Map<String, dynamic>)? onMessageReceived,
    Function()? onConnectionClosed,
  }) async {
    try {
      _onMessageReceived = onMessageReceived;
      _onConnectionClosed = onConnectionClosed;

      // Construct WebSocket URL with token if provided
      final url = token != null ? '$baseUrl?token=$token' : baseUrl;

      _channel = WebSocketChannel.connect(Uri.parse(url));

      // Listen for messages
      _subscription = _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            _onMessageReceived?.call(data);
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _handleDisconnection();
        },
        onDone: () {
          print('WebSocket connection closed');
          _handleDisconnection();
        },
      );

      _isConnected = true;
      print('WebSocket connected successfully');
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
      _isConnected = false;
    }
  }

  // Send a message through WebSocket
  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        final jsonMessage = jsonEncode(message);
        _channel!.sink.add(jsonMessage);
      } catch (e) {
        print('Error sending WebSocket message: $e');
      }
    } else {
      print('WebSocket is not connected');
    }
  }

  // Join a chat room
  void joinRoom(int roomId) {
    sendMessage({'type': 'join_room', 'room_id': roomId});
  }

  // Leave a chat room
  void leaveRoom(int roomId) {
    sendMessage({'type': 'leave_room', 'room_id': roomId});
  }

  // Send a chat message
  void sendChatMessage({
    required int roomId,
    required int senderId,
    required String content,
  }) {
    sendMessage({
      'type': 'chat_message',
      'room_id': roomId,
      'sender_id': senderId,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Send typing indicator
  void sendTypingIndicator({required int roomId, required int userId}) {
    sendMessage({'type': 'typing', 'room_id': roomId, 'user_id': userId});
  }

  // Request real-time updates for a course
  void subscribeToCourseUpdates(int courseId) {
    sendMessage({'type': 'subscribe_course', 'course_id': courseId});
  }

  // Unsubscribe from course updates
  void unsubscribeFromCourseUpdates(int courseId) {
    sendMessage({'type': 'unsubscribe_course', 'course_id': courseId});
  }

  // Handle disconnection
  void _handleDisconnection() {
    _isConnected = false;
    _onConnectionClosed?.call();
  }

  // Disconnect from WebSocket
  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    print('WebSocket disconnected');
  }

  // Reconnect to WebSocket
  Future<void> reconnect({String? token}) async {
    disconnect();
    await Future.delayed(
      const Duration(seconds: 2),
    ); // Wait before reconnecting
    await connect(token: token);
  }
}
