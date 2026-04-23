import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/time_formatter.dart';
import '../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../features/chat/presentation/viewmodels/chat_list_view_model.dart';
import '../models/app_user.dart';
import '../models/chat_thread.dart';
import '../widgets/app_avatar.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final chatsState = ref.watch(chatsProvider);
    final membersState = ref.watch(membersProvider);
    final vm = ref.watch(chatListViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Chat'),
        actions: [
          IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())), icon: const Icon(Icons.person_outline)),
          IconButton(onPressed: () => ref.read(authViewModelProvider).signOut(), icon: const Icon(Icons.logout)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search members or chats'),
              onChanged: (value) => setState(() => _query = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: membersState.when(
              data: (members) => chatsState.when(
                data: (chats) {
                  final filteredMembers = members.where((m) => m.displayName.toLowerCase().contains(_query) || m.email.toLowerCase().contains(_query)).toList();
                  final filteredChats = chats.where((c) => c.lastMessage.toLowerCase().contains(_query)).toList();
                  return ListView(children: [
                    if (filteredMembers.isNotEmpty) const _Header('Start new chat'),
                    ...filteredMembers.map((member) => ListTile(
                          leading: AppAvatar(name: member.displayName, photoUrl: member.photoUrl),
                          title: Text(member.displayName),
                          subtitle: Text(member.email),
                          onTap: () async {
                            // Create (or reuse) chat document before opening the room.
                            final chatId = await vm.startChatWith(member.id);
                            if (!context.mounted) return;
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId, contactName: member.displayName, contactPhotoUrl: member.photoUrl)));
                          },
                        )),
                    if (filteredChats.isNotEmpty) const _Header('Existing chats'),
                    ...filteredChats.map((chat) => _ChatTile(chat: chat)),
                  ]);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => const Center(child: Text('Cannot load chats')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => const Center(child: Text('Cannot load users')),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

class _ChatTile extends ConsumerWidget {
  final ChatThread chat;
  const _ChatTile({required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(chatListViewModelProvider);
    final myId = vm.currentUid();
    final otherId = chat.participants.firstWhere((id) => id != myId, orElse: () => myId);

    return FutureBuilder<AppUser?>(
      future: vm.userById(otherId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final name = user?.displayName ?? 'Chat';
        return ListTile(
          leading: AppAvatar(name: name, photoUrl: user?.photoUrl),
          title: Text(name),
          subtitle: Text(chat.lastMessage),
          trailing: Text(TimeFormatter.formatChatTime(chat.lastMessageTime)),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatId: chat.id, contactName: name, contactPhotoUrl: user?.photoUrl))),
        );
      },
    );
  }
}
