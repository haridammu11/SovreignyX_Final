import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    // Determine alignment and colors based on message type
    final isUser = message.type == MessageType.user;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color =
        isUser
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.secondary;
    final textColor =
        isUser
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSecondary;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.content, style: TextStyle(color: textColor)),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
