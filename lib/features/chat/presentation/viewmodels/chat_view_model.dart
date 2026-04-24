import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/chat_message.dart';
import '../../data/chat_repository.dart';

final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, chatId) => ref.watch(chatRepositoryProvider).watchMessages(chatId));
final groupMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, groupId) => ref.watch(chatRepositoryProvider).watchGroupMessages(groupId));
final chatViewModelProvider = Provider<ChatViewModel>((ref) => ChatViewModel(repository: ref.watch(chatRepositoryProvider)));

class ChatViewModel {
  final ChatRepository repository;
  ChatViewModel({required this.repository});

  Future<void> sendText(String chatId, String text) => repository.sendTextMessage(chatId: chatId, text: text);
  Future<void> sendImage(String chatId, File imageFile) => repository.sendImageMessage(chatId: chatId, imageFile: imageFile);
  Future<void> sendGroupText(String groupId, String text) => repository.sendGroupTextMessage(groupId: groupId, text: text);
  Future<void> sendGroupImage(String groupId, File imageFile) => repository.sendGroupImageMessage(groupId: groupId, imageFile: imageFile);
  String currentUid() => repository.getCurrentUid();
}
