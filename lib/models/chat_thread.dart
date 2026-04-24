import 'package:cloud_firestore/cloud_firestore.dart';

class ChatThread {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCounts;

  const ChatThread({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCounts,
  });

  factory ChatThread.fromMap(String id, Map<String, dynamic> map) {
    final timestamp = map['lastMessageTime'] as Timestamp?;
    final rawUnread = map['unreadCounts'];
    final unreadCounts = <String, int>{};
    if (rawUnread is Map) {
      for (final entry in rawUnread.entries) {
        final key = entry.key?.toString() ?? '';
        if (key.isEmpty) continue;
        unreadCounts[key] = (entry.value as num?)?.toInt() ?? 0;
      }
    }
    return ChatThread(
      id: id,
      participants: List<String>.from(map['participants'] as List? ?? const <String>[]),
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageTime: timestamp?.toDate() ?? DateTime.now(),
      unreadCounts: unreadCounts,
    );
  }
}
