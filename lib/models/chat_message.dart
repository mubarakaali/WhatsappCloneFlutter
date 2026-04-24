import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, audio }

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final String? audioUrl;
  final int? audioDurationMs;
  final MessageType type;
  final List<String> deliveredTo;
  final List<String> readBy;
  final Map<String, String> reactions;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.imageUrl,
    required this.audioUrl,
    required this.audioDurationMs,
    required this.type,
    required this.deliveredTo,
    required this.readBy,
    required this.reactions,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    final timestamp = map['createdAt'] as Timestamp?;
    final rawType = map['type'] as String? ?? 'text';
    final messageType = MessageType.values.firstWhere(
      (value) => value.name == rawType,
      orElse: () => MessageType.text,
    );
    final rawReactions = map['reactions'];
    final reactionMap = <String, String>{};
    if (rawReactions is Map) {
      for (final entry in rawReactions.entries) {
        final key = entry.key?.toString() ?? '';
        final value = entry.value?.toString() ?? '';
        if (key.isNotEmpty && value.isNotEmpty) {
          reactionMap[key] = value;
        }
      }
    }
    return ChatMessage(
      id: id,
      senderId: map['senderId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      audioUrl: map['audioUrl'] as String?,
      audioDurationMs: (map['audioDurationMs'] as num?)?.toInt(),
      type: messageType,
      deliveredTo: List<String>.from(map['deliveredTo'] as List? ?? const <String>[]),
      readBy: List<String>.from(map['readBy'] as List? ?? const <String>[]),
      reactions: reactionMap,
      createdAt: timestamp?.toDate() ?? DateTime.now(),
    );
  }
}
