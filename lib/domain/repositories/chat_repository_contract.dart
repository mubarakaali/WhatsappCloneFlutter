import 'dart:io';

import '../entities/app_user.dart';
import '../entities/chat_message.dart';
import '../entities/chat_thread.dart';
import '../entities/group_thread.dart';
import '../entities/status_item.dart';

/// Contract for chat data operations used by presentation layer.
///

abstract class ChatRepositoryContract {
  Stream<List<ChatThread>> watchUserChats();
  Stream<List<GroupThread>> watchUserGroups();
  Stream<List<AppUser>> watchAllUsers();
  Future<AppUser?> getUserById(String uid);

  Future<String> createGroup({
    required String groupName,
    required List<String> memberIds,
    File? iconFile,
  });

  Future<String> ensureChatWith(String otherUserId);
  Stream<List<ChatMessage>> watchMessages(String chatId);
  Stream<List<ChatMessage>> watchGroupMessages(String groupId);

  Future<void> sendTextMessage({required String chatId, required String text});
  Future<void> sendImageMessage({required String chatId, required File imageFile});
  Future<void> sendAudioMessage({
    required String chatId,
    required File audioFile,
    required int durationMs,
  });

  Future<void> sendGroupTextMessage({
    required String groupId,
    required String text,
  });
  Future<void> sendGroupImageMessage({
    required String groupId,
    required File imageFile,
  });
  Future<void> sendGroupAudioMessage({
    required String groupId,
    required File audioFile,
    required int durationMs,
  });

  Future<void> markChatAsRead(String chatId);

  Future<void> setMessageReaction({
    required String chatId,
    required String messageId,
    required String emoji,
  });
  Future<void> removeMessageReaction({
    required String chatId,
    required String messageId,
  });
  Future<void> setGroupMessageReaction({
    required String groupId,
    required String messageId,
    required String emoji,
  });
  Future<void> removeGroupMessageReaction({
    required String groupId,
    required String messageId,
  });

  Stream<List<StatusItem>> watchStatuses();
  Future<void> createTextStatus(String text);
  Future<void> createImageStatus(File imageFile, {String text = ''});

  String getCurrentUid();
}
