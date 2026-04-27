import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/chat_message.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../domain/repositories/chat_repository_contract.dart';

final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, chatId) => ref.watch(chatRepositoryProvider).watchMessages(chatId));
final groupMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, groupId) => ref.watch(chatRepositoryProvider).watchGroupMessages(groupId));
final chatViewModelProvider = Provider<ChatViewModel>((ref) => ChatViewModel(repository: ref.watch(chatRepositoryProvider)));

/// ViewModel for conversation-level user actions.
///
/// Keeps UI widgets thin by exposing intent-based methods.
class ChatViewModel {
  final ChatRepositoryContract repository;
  ChatViewModel({required this.repository});

  Future<void> sendText(String chatId, String text) => repository.sendTextMessage(chatId: chatId, text: text);
  Future<void> sendImage(String chatId, File imageFile) => repository.sendImageMessage(chatId: chatId, imageFile: imageFile);
  Future<void> sendAudio(String chatId, File audioFile, int durationMs) =>
      repository.sendAudioMessage(chatId: chatId, audioFile: audioFile, durationMs: durationMs);
  Future<void> sendGroupText(String groupId, String text) => repository.sendGroupTextMessage(groupId: groupId, text: text);
  Future<void> sendGroupImage(String groupId, File imageFile) => repository.sendGroupImageMessage(groupId: groupId, imageFile: imageFile);
  Future<void> sendGroupAudio(String groupId, File audioFile, int durationMs) =>
      repository.sendGroupAudioMessage(groupId: groupId, audioFile: audioFile, durationMs: durationMs);
  Future<void> markChatRead(String chatId) => repository.markChatAsRead(chatId);
  Future<void> reactToMessage(String chatId, String messageId, String emoji) =>
      repository.setMessageReaction(chatId: chatId, messageId: messageId, emoji: emoji);
  Future<void> removeReaction(String chatId, String messageId) =>
      repository.removeMessageReaction(chatId: chatId, messageId: messageId);
  Future<void> reactToGroupMessage(String groupId, String messageId, String emoji) =>
      repository.setGroupMessageReaction(groupId: groupId, messageId: messageId, emoji: emoji);
  Future<void> removeGroupReaction(String groupId, String messageId) =>
      repository.removeGroupMessageReaction(groupId: groupId, messageId: messageId);
  String currentUid() => repository.getCurrentUid();
}
