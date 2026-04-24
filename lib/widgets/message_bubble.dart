import 'package:flutter/material.dart';

import '../core/theme/whatsapp_palette.dart';
import '../core/utils/time_formatter.dart';
import '../models/chat_message.dart';
import 'app_avatar.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final String senderName;
  final String? senderPhotoUrl;

  /// One-to-one chats: hide name/avatar row like WhatsApp direct messages.
  final bool compact;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.senderName,
    required this.senderPhotoUrl,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outgoing = isDark ? WhatsAppPalette.darkBubbleOut : WhatsAppPalette.bubbleOutgoing;
    final incoming = isDark ? WhatsAppPalette.darkBubbleIn : WhatsAppPalette.bubbleIncoming;
    final bubbleColor = isMine ? outgoing : incoming;
    final timeColor = isDark ? const Color(0xFF8696A0) : WhatsAppPalette.subtitleGrey;
    final nameColor = isDark ? const Color(0xFF53BDEB) : WhatsAppPalette.tealBar;

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(8),
      topRight: const Radius.circular(8),
      bottomLeft: Radius.circular(isMine ? 8 : 2),
      bottomRight: Radius.circular(isMine ? 2 : 8),
    );

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!compact)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    AppAvatar(
                      name: senderName,
                      photoUrl: senderPhotoUrl,
                      radius: 10,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        senderName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: nameColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    message.imageUrl!,
                    height: 170,
                    width: 250,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (message.text.isNotEmpty)
              Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF111B21),
                ),
              ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                TimeFormatter.formatChatTime(message.createdAt),
                style: TextStyle(fontSize: 11, color: timeColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
