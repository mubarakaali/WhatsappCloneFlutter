import 'package:flutter/material.dart';

import '../core/utils/time_formatter.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final String senderName;

  const MessageBubble({super.key, required this.message, required this.isMine, required this.senderName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isMine ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(senderName, style: theme.textTheme.labelSmall),
            if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(message.imageUrl!, height: 170, width: 170, fit: BoxFit.cover),
                ),
              ),
            if (message.text.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(message.text)),
            const SizedBox(height: 4),
            Align(alignment: Alignment.centerRight, child: Text(TimeFormatter.formatChatTime(message.createdAt), style: theme.textTheme.labelSmall)),
          ],
        ),
      ),
    );
  }
}
