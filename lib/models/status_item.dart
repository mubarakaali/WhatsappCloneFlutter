import 'package:cloud_firestore/cloud_firestore.dart';

enum StatusType { text, image }

class StatusItem {
  final String id;
  final String userId;
  final StatusType type;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime expiresAt;

  const StatusItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.text,
    required this.imageUrl,
    required this.createdAt,
    required this.expiresAt,
  });

  factory StatusItem.fromMap(String id, Map<String, dynamic> map) {
    final createdTimestamp = map['createdAt'] as Timestamp?;
    final expiresTimestamp = map['expiresAt'] as Timestamp?;
    final rawType = map['type'] as String? ?? 'text';
    final statusType = StatusType.values.firstWhere(
      (value) => value.name == rawType,
      orElse: () => StatusType.text,
    );
    return StatusItem(
      id: id,
      userId: map['userId'] as String? ?? '',
      type: statusType,
      text: map['text'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      createdAt: createdTimestamp?.toDate() ?? DateTime.now(),
      expiresAt: expiresTimestamp?.toDate() ?? DateTime.now().add(const Duration(hours: 24)),
    );
  }
}
