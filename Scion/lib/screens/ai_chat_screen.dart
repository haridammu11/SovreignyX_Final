import 'package:flutter/material.dart';
import 'dart:math';
import '../widgets/chat_message_widget.dart';
import '../services/ai_chat_service.dart';
import '../services/groq_service.dart';
import '../utils/constants.dart';

class AIChatScreen extends StatefulWidget {
  final String? apiKey;
  final int userId;

  const AIChatScreen({super.key, this.apiKey, required this.userId});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen>
    with TickerProviderStateMixin {
  late AIChatService _chatService;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _sendButtonController;
  bool _isSending = false;
  bool _showApiKeyInput = false;
  String? _currentApiKey;

  @override
  void initState() {
    super.initState();
    print('=== AI CHAT SCREEN INIT ===');
    _currentApiKey = widget.apiKey;
    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initializeChatService();
  }

  void _initializeChatService() {
    print('Initializing chat service...');
    try {
      final apiKey = _currentApiKey ?? AppConstants.groqApiKey;
      print('Using API key length: ${apiKey.length}');
      print(
        'API key starts with: ${apiKey.substring(0, min(10, apiKey.length))}...',
      );
      print('API key is empty: ${apiKey.isEmpty}');
      print('API key starts with gsk_: ${apiKey.startsWith('gsk_')}');

      if (apiKey.isEmpty || !apiKey.startsWith('gsk_')) {
        print('WARNING: Using invalid API key format');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please set a valid Groq API key (must start with gsk_)',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }

      final aiService = GroqService(apiKey: apiKey);
      _chatService = AIChatService(aiService: aiService);
      print('Chat service initialized successfully');
    } catch (e, stackTrace) {
      print('Error initializing AI service: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error initializing AI service: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    print('Disposing AI chat screen...');
    _textController.dispose();
    _apiKeyController.dispose();
    _scrollController.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  void _setApiKey() {
    print('Setting new API key...');
    final newApiKey = _apiKeyController.text.trim();

    if (newApiKey.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Please enter a valid API key'),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _currentApiKey = newApiKey;
      _showApiKeyInput = false;
      _initializeChatService();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('API key updated successfully'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    print('Sending message...');
    if (_textController.text.trim().isEmpty || _isSending) {
      print('Message is empty or already sending');
      return;
    }

    final message = _textController.text.trim();
    print('Message content length: ${message.length}');
    _textController.clear();
    _sendButtonController.forward().then(
      (_) => _sendButtonController.reverse(),
    );

    setState(() {
      _isSending = true;
    });

    try {
      print('Calling chat service to send message...');
      await _chatService.sendMessageToAI(message);
      print('Message sent successfully');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e, stackTrace) {
      print('=== AI CHAT SCREEN ERROR ===');
      print('Error sending message: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.length > 200) {
          errorMessage = '${errorMessage.substring(0, 200)}...';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $errorMessage')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building AI chat screen...');
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.blue.shade400],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Always here to help',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
                ),
              ],
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
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_showApiKeyInput ? Icons.close : Icons.settings),
            onPressed: () {
              setState(() {
                _showApiKeyInput = !_showApiKeyInput;
              });
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.03),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 100),

            // API Key input
            if (_showApiKeyInput)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'API Key Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _apiKeyController,
                            decoration: InputDecoration(
                              hintText: 'Enter your Groq API key',
                              prefixIcon: const Icon(Icons.key),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            obscureText: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _setApiKey,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Set'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Chat messages
            Expanded(
              child:
                  _chatService.messages.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.purple.shade100,
                                    Colors.blue.shade100,
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Start a conversation',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ask me anything!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount:
                            _chatService.messages.length + (_isSending ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _chatService.messages.length &&
                              _isSending) {
                            return _buildTypingIndicator();
                          }
                          final message = _chatService.messages[index];
                          return ChatMessageWidget(message: message);
                        },
                      ),
            ),

            // Input area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: 'Ask me anything...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            prefixIcon: Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.grey[400],
                            ),
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ScaleTransition(
                      scale: Tween<double>(begin: 1.0, end: 0.8).animate(
                        CurvedAnimation(
                          parent: _sendButtonController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                _isSending
                                    ? [Colors.grey, Colors.grey.shade400]
                                    : [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.secondary,
                                    ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _isSending ? null : _sendMessage,
                          icon:
                              _isSending
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                  ),
                          tooltip: 'Send message',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade100, Colors.blue.shade100],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        final delay = index * 0.2;
        final animValue = ((value - delay) * 5).clamp(0.0, 1.0);
        final scale = 0.5 + (sin(animValue * pi) * 0.5);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted && _isSending) {
          setState(() {});
        }
      },
    );
  }
}
