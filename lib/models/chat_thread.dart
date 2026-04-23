import 'package:cloud_firestore/cloud_firestore.dart';

class ChatThread {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;

  const ChatThread({required this.id, required this.participants, required this.lastMessage, required this.lastMessageTime});

  factory ChatThread.fromMap(String id, Map<String, dynamic> map) {
    final timestamp = map['lastMessageTime'] as Timestamp?;
    return ChatThread(
      id: id,
      participants: List<String>.from(map['participants'] as List? ?? const <String>[]),
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageTime: timestamp?.toDate() ?? DateTime.now(),
    );
  }
}
