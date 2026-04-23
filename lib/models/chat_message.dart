import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;

  const ChatMessage({required this.id, required this.senderId, required this.text, required this.imageUrl, required this.createdAt});

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    final timestamp = map['createdAt'] as Timestamp?;
    return ChatMessage(
      id: id,
      senderId: map['senderId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      createdAt: timestamp?.toDate() ?? DateTime.now(),
    );
  }
}
