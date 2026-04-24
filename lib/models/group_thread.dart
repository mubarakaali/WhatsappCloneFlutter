import 'package:cloud_firestore/cloud_firestore.dart';

class GroupThread {
  final String id;
  final String name;
  final String? iconUrl;
  final List<String> members;
  final String lastMessage;
  final DateTime lastMessageTime;

  const GroupThread({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.members,
    required this.lastMessage,
    required this.lastMessageTime,
  });

  factory GroupThread.fromMap(String id, Map<String, dynamic> map) {
    final timestamp = map['lastMessageTime'] as Timestamp?;
    final rawMembers = map['members'];
    final members = rawMembers is List
        ? rawMembers.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList()
        : const <String>[];

    return GroupThread(
      id: id,
      name: map['name'] as String? ?? 'Group',
      iconUrl: map['iconUrl'] as String?,
      members: members,
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageTime: timestamp?.toDate() ?? DateTime.now(),
    );
  }
}
