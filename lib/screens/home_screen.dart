import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/app_logger.dart';
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
  final _searchController = TextEditingController();
  String _query = '';
  bool _hasShownUserNotFound = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch() {
    final normalized = _searchController.text.trim().toLowerCase();
    AppLogger.info('home_screen', 'Search button pressed. query="$normalized"');
    setState(() {
      _query = normalized;
      _hasShownUserNotFound = false;
    });
  }

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
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search members or chats',
                suffixIcon: IconButton(
                  onPressed: _applySearch,
                  icon: const Icon(Icons.search),
                  tooltip: 'Search',
                ),
              ),
              onChanged: (value) {
                final normalized = value.toLowerCase();
                AppLogger.info('home_screen', 'Search field changed. raw="$value", normalized="$normalized"');
              },
              onSubmitted: (_) => _applySearch(),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                final members = membersState.valueOrNull ?? const <AppUser>[];
                final chats = chatsState.valueOrNull ?? const <ChatThread>[];

                final isLoading = membersState.isLoading && chatsState.isLoading;
                if (isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredMembers = members.where((m) => m.displayName.toLowerCase().contains(_query) || m.email.toLowerCase().contains(_query)).toList();
                final filteredChats = chats.where((c) => c.lastMessage.toLowerCase().contains(_query)).toList();
                final canEvaluateNotFound = membersState.hasValue || chatsState.hasValue;
                final showNotFound = canEvaluateNotFound && _query.trim().isNotEmpty && filteredMembers.isEmpty && filteredChats.isEmpty;

                AppLogger.info(
                  'home_screen',
                  'Search stats query="$_query", membersTotal=${members.length}, chatsTotal=${chats.length}, '
                  'filteredMembers=${filteredMembers.length}, filteredChats=${filteredChats.length}, '
                  'showNotFound=$showNotFound, hasShown=$_hasShownUserNotFound',
                );

                if (showNotFound && !_hasShownUserNotFound) {
                  _hasShownUserNotFound = true;
                  AppLogger.info('home_screen', 'Snackbar trigger: User not found');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User not found')),
                    );
                  });
                } else if (!showNotFound) {
                  if (_hasShownUserNotFound) {
                    AppLogger.info('home_screen', 'Reset user-not-found snackbar state');
                  }
                  _hasShownUserNotFound = false;
                }

                return ListView(
                  children: [
                    if (membersState.hasError)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text('Could not load some members right now.'),
                      ),
                    if (chatsState.hasError)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Text('Could not load some chats right now.'),
                      ),
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
                  ],
                );
              },
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
