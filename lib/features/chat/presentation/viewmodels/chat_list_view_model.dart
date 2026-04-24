import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/app_user.dart';
import '../../../../models/chat_thread.dart';
import '../../../../models/group_thread.dart';
import '../../../../models/status_item.dart';
import '../../data/chat_repository.dart';

final chatsProvider = StreamProvider<List<ChatThread>>((ref) => ref.watch(chatRepositoryProvider).watchUserChats());
final groupsProvider = StreamProvider<List<GroupThread>>((ref) => ref.watch(chatRepositoryProvider).watchUserGroups());
final membersProvider = StreamProvider<List<AppUser>>((ref) => ref.watch(chatRepositoryProvider).watchAllUsers());
final statusesProvider = StreamProvider<List<StatusItem>>((ref) => ref.watch(chatRepositoryProvider).watchStatuses());
final chatListViewModelProvider = Provider<ChatListViewModel>((ref) => ChatListViewModel(repository: ref.watch(chatRepositoryProvider)));

class ChatListViewModel {
  final ChatRepository repository;
  ChatListViewModel({required this.repository});

  Future<String> startChatWith(String otherUserId) => repository.ensureChatWith(otherUserId);
  Future<String> createGroup({
    required String groupName,
    required List<String> memberIds,
    File? iconFile,
  }) =>
      repository.createGroup(groupName: groupName, memberIds: memberIds, iconFile: iconFile);
  Future<void> createTextStatus(String text) => repository.createTextStatus(text);
  Future<void> createImageStatus(File imageFile, {String text = ''}) => repository.createImageStatus(imageFile, text: text);
  Future<AppUser?> userById(String uid) => repository.getUserById(uid);
  String currentUid() => repository.getCurrentUid();
}