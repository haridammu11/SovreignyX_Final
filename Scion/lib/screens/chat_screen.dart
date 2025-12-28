import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final int userId;
  final String? token;

  const ChatScreen({super.key, required this.userId, this.token});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late ChatService _chatService;
  List<PrivateChat> _chats = [];
  List<PrivateMessage> _messages = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int? _selectedChatId;
  final TextEditingController _messageController = TextEditingController();
  late AnimationController _messageAnimationController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(token: widget.token);
    _messageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadChats();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChats() async {
    try {
      final chats = await _chatService.getPrivateChats(widget.userId);
      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load chats: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMessages(int chatId) async {
    try {
      final messages = await _chatService.getPrivateMessages(chatId);
      setState(() {
        _messages = messages;
        _selectedChatId = chatId;
      });
      _messageAnimationController.forward(from: 0);

      // Scroll to bottom after loading messages
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load messages: $e';
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _selectedChatId == null)
      return;

    try {
      await _chatService.sendPrivateMessage(
        chatId: _selectedChatId!,
        senderId: widget.userId,
        content: _messageController.text.trim(),
      );

      _messageController.clear();
      _loadMessages(_selectedChatId!);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send message: $e';
      });
    }
  }

  Color _getUserColor(int userId) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.teal,
    ];
    return colors[userId % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.purple.shade400],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Messages',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Colors.blue.shade600,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade100, Colors.orange.shade100],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _loadChats,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : Row(
                children: [
                  // Chats list sidebar
                  Container(
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(
                        right: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Conversations',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.2),
                                      Theme.of(
                                        context,
                                      ).colorScheme.secondary.withOpacity(0.2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_chats.length}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child:
                              _chats.isEmpty
                                  ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.chat_bubble_outline,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No conversations yet',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  : ListView.builder(
                                    itemCount: _chats.length,
                                    itemBuilder: (context, index) {
                                      final chat = _chats[index];
                                      final otherUserId =
                                          chat.user1Id == widget.userId
                                              ? chat.user2Id
                                              : chat.user1Id;
                                      final isSelected =
                                          _selectedChatId == chat.id;

                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient:
                                              isSelected
                                                  ? LinearGradient(
                                                    colors: [
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .primary
                                                          .withOpacity(0.1),
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .secondary
                                                          .withOpacity(0.1),
                                                    ],
                                                  )
                                                  : null,
                                          color:
                                              isSelected ? null : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border:
                                              isSelected
                                                  ? Border.all(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withOpacity(0.3),
                                                    width: 2,
                                                  )
                                                  : null,
                                        ),
                                        child: ListTile(
                                          leading: Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  _getUserColor(otherUserId),
                                                  _getUserColor(
                                                    otherUserId,
                                                  ).withOpacity(0.7),
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                'U${otherUserId.toString().substring(0, 1)}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            'User $otherUserId',
                                            style: TextStyle(
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Tap to view messages',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          onTap: () => _loadMessages(chat.id),
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  ),
                  // Messages area
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[50]!, Colors.white],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Messages list
                          Expanded(
                            child:
                                _selectedChatId == null
                                    ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(24),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.blue.shade100,
                                                  Colors.purple.shade100,
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.forum,
                                              size: 64,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          const Text(
                                            'Select a conversation',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Choose a chat from the sidebar to start messaging',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    : FadeTransition(
                                      opacity: _messageAnimationController,
                                      child: ListView.builder(
                                        controller: _scrollController,
                                        padding: const EdgeInsets.all(16),
                                        itemCount: _messages.length,
                                        itemBuilder: (context, index) {
                                          final message = _messages[index];
                                          final isMe =
                                              message.senderId == widget.userId;

                                          return Align(
                                            alignment:
                                                isMe
                                                    ? Alignment.centerRight
                                                    : Alignment.centerLeft,
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              constraints: BoxConstraints(
                                                maxWidth:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.width *
                                                    0.6,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    isMe
                                                        ? CrossAxisAlignment.end
                                                        : CrossAxisAlignment
                                                            .start,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      gradient:
                                                          isMe
                                                              ? LinearGradient(
                                                                colors: [
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .primary,
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .secondary,
                                                                ],
                                                              )
                                                              : null,
                                                      color:
                                                          isMe
                                                              ? null
                                                              : Colors
                                                                  .grey[200],
                                                      borderRadius: BorderRadius.only(
                                                        topLeft:
                                                            const Radius.circular(
                                                              16,
                                                            ),
                                                        topRight:
                                                            const Radius.circular(
                                                              16,
                                                            ),
                                                        bottomLeft:
                                                            Radius.circular(
                                                              isMe ? 16 : 4,
                                                            ),
                                                        bottomRight:
                                                            Radius.circular(
                                                              isMe ? 4 : 16,
                                                            ),
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color:
                                                              isMe
                                                                  ? Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .primary
                                                                      .withOpacity(
                                                                        0.3,
                                                                      )
                                                                  : Colors.black
                                                                      .withOpacity(
                                                                        0.05,
                                                                      ),
                                                          blurRadius: 8,
                                                          offset: const Offset(
                                                            0,
                                                            2,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      message.content,
                                                      style: TextStyle(
                                                        color:
                                                            isMe
                                                                ? Colors.white
                                                                : Colors
                                                                    .black87,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    message.timestamp
                                                        .toString()
                                                        .substring(11, 16),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[500],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                          ),
                          // Message input
                          if (_selectedChatId != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, -2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: TextField(
                                        controller: _messageController,
                                        decoration: InputDecoration(
                                          hintText: 'Type a message...',
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 12,
                                              ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              Icons.emoji_emotions_outlined,
                                              color: Colors.grey[600],
                                            ),
                                            onPressed: () {},
                                          ),
                                        ),
                                        onSubmitted: (_) => _sendMessage(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.primary,
                                          Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.send,
                                        color: Colors.white,
                                      ),
                                      onPressed: _sendMessage,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
