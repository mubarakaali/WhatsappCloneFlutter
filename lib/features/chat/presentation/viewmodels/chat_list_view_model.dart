import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/app_user.dart';
import '../../../../models/chat_thread.dart';
import '../../data/chat_repository.dart';

final chatsProvider = StreamProvider<List<ChatThread>>((ref) => ref.watch(chatRepositoryProvider).watchUserChats());
final membersProvider = StreamProvider<List<AppUser>>((ref) => ref.watch(chatRepositoryProvider).watchAllUsers());
final chatListViewModelProvider = Provider<ChatListViewModel>((ref) => ChatListViewModel(repository: ref.watch(chatRepositoryProvider)));

class ChatListViewModel {
  final ChatRepository repository;
  ChatListViewModel({required this.repository});

  Future<String> startChatWith(String otherUserId) => repository.ensureChatWith(otherUserId);
  Future<AppUser?> userById(String uid) => repository.getUserById(uid);
  String currentUid() => repository.getCurrentUid();
}
