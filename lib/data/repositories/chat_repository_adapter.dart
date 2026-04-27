import 'dart:io';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_thread.dart';
import '../../domain/entities/group_thread.dart';
import '../../domain/entities/status_item.dart';
import '../../domain/repositories/chat_repository_contract.dart';
import 'chat_repository_impl.dart';

/// Adapter exposing [ChatRepository] via [ChatRepositoryContract].
class ChatRepositoryAdapter implements ChatRepositoryContract {
  final ChatRepository _source;

  ChatRepositoryAdapter(this._source);

  @override
  Future<String> createGroup({required String groupName, required List<String> memberIds, File? iconFile}) =>
      _source.createGroup(groupName: groupName, memberIds: memberIds, iconFile: iconFile);

  @override
  Future<void> createImageStatus(File imageFile, {String text = ''}) => _source.createImageStatus(imageFile, text: text);

  @override
  Future<void> createTextStatus(String text) => _source.createTextStatus(text);

  @override
  Future<String> ensureChatWith(String otherUserId) => _source.ensureChatWith(otherUserId);

  @override
  String getCurrentUid() => _source.getCurrentUid();

  @override
  Future<AppUser?> getUserById(String uid) => _source.getUserById(uid);

  @override
  Future<void> markChatAsRead(String chatId) => _source.markChatAsRead(chatId);

  @override
  Future<void> removeGroupMessageReaction({required String groupId, required String messageId}) =>
      _source.removeGroupMessageReaction(groupId: groupId, messageId: messageId);

  @override
  Future<void> removeMessageReaction({required String chatId, required String messageId}) =>
      _source.removeMessageReaction(chatId: chatId, messageId: messageId);

  @override
  Future<void> sendAudioMessage({required String chatId, required File audioFile, required int durationMs}) =>
      _source.sendAudioMessage(chatId: chatId, audioFile: audioFile, durationMs: durationMs);

  @override
  Future<void> sendGroupAudioMessage({required String groupId, required File audioFile, required int durationMs}) =>
      _source.sendGroupAudioMessage(groupId: groupId, audioFile: audioFile, durationMs: durationMs);

  @override
  Future<void> sendGroupImageMessage({required String groupId, required File imageFile}) =>
      _source.sendGroupImageMessage(groupId: groupId, imageFile: imageFile);

  @override
  Future<void> sendGroupTextMessage({required String groupId, required String text}) =>
      _source.sendGroupTextMessage(groupId: groupId, text: text);

  @override
  Future<void> sendImageMessage({required String chatId, required File imageFile}) =>
      _source.sendImageMessage(chatId: chatId, imageFile: imageFile);

  @override
  Future<void> sendTextMessage({required String chatId, required String text}) =>
      _source.sendTextMessage(chatId: chatId, text: text);

  @override
  Future<void> setGroupMessageReaction({required String groupId, required String messageId, required String emoji}) =>
      _source.setGroupMessageReaction(groupId: groupId, messageId: messageId, emoji: emoji);

  @override
  Future<void> setMessageReaction({required String chatId, required String messageId, required String emoji}) =>
      _source.setMessageReaction(chatId: chatId, messageId: messageId, emoji: emoji);

  @override
  Stream<List<AppUser>> watchAllUsers() => _source.watchAllUsers();

  @override
  Stream<List<ChatMessage>> watchGroupMessages(String groupId) => _source.watchGroupMessages(groupId);

  @override
  Stream<List<GroupThread>> watchUserGroups() => _source.watchUserGroups();

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) => _source.watchMessages(chatId);

  @override
  Stream<List<StatusItem>> watchStatuses() => _source.watchStatuses();

  @override
  Stream<List<ChatThread>> watchUserChats() => _source.watchUserChats();
}
