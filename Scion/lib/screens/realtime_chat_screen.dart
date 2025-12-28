import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';
import '../services/websocket_service.dart';

class RealtimeChatScreen extends StatefulWidget {
  final int userId;
  final String? token;
  final int chatRoomId;

  const RealtimeChatScreen({
    super.key,
    required this.userId,
    this.token,
    required this.chatRoomId,
  });

  @override
  State<RealtimeChatScreen> createState() => _RealtimeChatScreenState();
}

class _RealtimeChatScreenState extends State<RealtimeChatScreen> {
  late ChatService _chatService;
  late WebSocketService _websocketService;
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isConnected = false;
  String _errorMessage = '';
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(token: widget.token);
    _websocketService = WebSocketService();
    _loadMessages();
    _connectToWebSocket();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _websocketService.disconnect();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _chatService.getMessages(widget.chatRoomId);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load messages: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _connectToWebSocket() async {
    try {
      await _websocketService.connect(
        token: widget.token,
        onMessageReceived: _handleWebSocketMessage,
        onConnectionClosed: _handleWebSocketDisconnect,
      );

      // Join the chat room
      _websocketService.joinRoom(widget.chatRoomId);

      setState(() {
        _isConnected = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect to real-time chat: $e';
      });
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> message) {
    final messageType = message['type'];

    if (messageType == 'chat_message') {
      final newMessage = Message(
        id: message['id'] ?? 0,
        roomId: message['room_id'],
        senderId: message['sender_id'],
        content: message['content'],
        timestamp: DateTime.parse(message['timestamp']),
        isRead: message['is_read'] ?? false,
      );

      setState(() {
        _messages.add(newMessage);
      });

      _scrollToBottom();
    } else if (messageType == 'user_joined') {
      // Handle user joined notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${message['username']} joined the chat')),
      );
    } else if (messageType == 'user_left') {
      // Handle user left notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${message['username']} left the chat')),
      );
    }
  }

  void _handleWebSocketDisconnect() {
    setState(() {
      _isConnected = false;
    });

    // Try to reconnect
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _connectToWebSocket();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    if (_websocketService.isConnected) {
      // Send via WebSocket for real-time delivery
      _websocketService.sendChatMessage(
        roomId: widget.chatRoomId,
        senderId: widget.userId,
        content: _messageController.text.trim(),
      );

      // Clear the input field
      _messageController.clear();
    } else {
      // Fallback to REST API if WebSocket is not connected
      try {
        final message = await _chatService.sendMessage(
          roomId: widget.chatRoomId,
          senderId: widget.userId,
          content: _messageController.text.trim(),
        );

        setState(() {
          _messages.add(message);
        });

        _scrollToBottom();
        _messageController.clear();
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to send message: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Chat'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          Icon(
            _isConnected ? Icons.circle : Icons.circle_outlined,
            color: _isConnected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadMessages,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Messages list
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isMe = message.senderId == widget.userId;

                        return Align(
                          alignment:
                              isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  isMe
                                      ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                      : Theme.of(
                                        context,
                                      ).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.content,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Message input
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              border: const OutlineInputBorder(),
                              suffixIcon:
                                  _websocketService.isConnected
                                      ? const Icon(
                                        Icons.flash_on,
                                        color: Colors.green,
                                      )
                                      : const Icon(
                                        Icons.flash_off,
                                        color: Colors.red,
                                      ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
