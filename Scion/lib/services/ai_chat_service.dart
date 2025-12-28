import 'dart:async';
import 'dart:math';
import '../models/chat_message.dart';
import 'groq_service.dart';

class AIChatService {
  final GroqService _aiService;
  final List<ChatMessage> _messages = [];

  AIChatService({required GroqService aiService}) : _aiService = aiService;

  // Get all messages
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  // Generate a simple ID
  String _generateId() {
    return Random().nextInt(1000000).toString();
  }

  // Add a user message
  void addUserMessage(String content) {
    print('Adding user message: $content');
    final message = ChatMessage(
      id: _generateId(),
      content: content,
      type: MessageType.user,
      timestamp: DateTime.now(),
    );

    _messages.add(message);
    print('User message added. Total messages: ${_messages.length}');
  }

  // Add an AI message
  void addAiMessage(String content) {
    print('Adding AI message (length: ${content.length})');
    final message = ChatMessage(
      id: _generateId(),
      content: content,
      type: MessageType.ai,
      timestamp: DateTime.now(),
    );

    _messages.add(message);
    print('AI message added. Total messages: ${_messages.length}');
  }

  // Clear all messages
  void clearMessages() {
    print('Clearing all messages');
    _messages.clear();
    print('Messages cleared. Total messages: ${_messages.length}');
  }

  // Get message history in the format expected by the Groq service
  List<Map<String, dynamic>> _getMessageHistory() {
    print('Getting message history for ${_messages.length} messages');
    final history = <Map<String, dynamic>>[];

    // Convert chat messages to Groq service format, but only include complete exchanges
    // (user message followed by AI response)
    for (int i = 0; i < _messages.length; i++) {
      final message = _messages[i];

      // Only include messages that form complete exchanges
      // Skip the most recent user message as it hasn't been responded to yet
      if (message.type == MessageType.user && i < _messages.length - 1) {
        // Check if next message is an AI response
        if (_messages[i + 1].type == MessageType.ai) {
          // Add both user and AI messages as a pair
          history.add({'role': 'user', 'content': message.content});
          history.add({
            'role': 'assistant',
            'content': _messages[i + 1].content,
          });
          i++; // Skip the next message as we've already processed it
        }
      }
    }

    print('Message history prepared with ${history.length} entries');
    return history;
  }

  // Send a message to the AI and get a response
  Future<String> sendMessageToAI(String message) async {
    print('=== AI CHAT SERVICE DEBUG INFO ===');
    print('Sending message to AI: $message (length: ${message.length})');

    try {
      // Add the user message to the conversation
      addUserMessage(message);

      // Get the message history (excluding the most recent user message)
      final history = _getMessageHistory();
      print('Retrieved history with ${history.length} entries');

      // Send the message to the AI service
      print('Calling AI service...');
      final aiResponse = await _aiService.sendMessage(
        message,
        history: history,
      );
      print('Received AI response (length: ${aiResponse.length})');

      // Add the AI response to the conversation
      addAiMessage(aiResponse);

      return aiResponse;
    } catch (e, stackTrace) {
      print('=== AI CHAT SERVICE ERROR ===');
      print('Error in sendMessageToAI: $e');
      print('Stack trace: $stackTrace');

      // Add an error message to the conversation
      final errorMessage =
          'Sorry, I encountered an error: ${e.toString().substring(0, min(e.toString().length, 200))}';
      addAiMessage(errorMessage);
      rethrow;
    }
  }

  // Send a message to the AI with streaming response
  Stream<String> streamMessageToAI(String message) async* {
    print('Streaming message to AI: $message (length: ${message.length})');

    try {
      // Add the user message to the conversation
      addUserMessage(message);

      // Get the message history (excluding the most recent user message)
      final history = _getMessageHistory();

      // Send the message to the AI service
      print('Calling AI service for streaming...');
      final stream = await _aiService.streamMessage(message, history: history);

      // Collect the full response as it comes in
      final StringBuffer buffer = StringBuffer();

      await for (final chunk in stream) {
        buffer.write(chunk);
        yield chunk;
      }

      // Add the complete AI response to the conversation
      addAiMessage(buffer.toString());
    } catch (e, stackTrace) {
      print('=== AI CHAT SERVICE STREAM ERROR ===');
      print('Error in streamMessageToAI: $e');
      print('Stack trace: $stackTrace');

      // Add an error message to the conversation
      final errorMessage =
          'Sorry, I encountered an error: ${e.toString().substring(0, min(e.toString().length, 200))}';
      addAiMessage(errorMessage);
      yield errorMessage;
    }
  }
}
