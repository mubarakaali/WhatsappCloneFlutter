import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/whatsapp_palette.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/time_formatter.dart';
import '../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../features/chat/presentation/viewmodels/chat_list_view_model.dart';
import '../models/app_user.dart';
import '../models/chat_thread.dart';
import '../models/group_thread.dart';
import '../widgets/app_avatar.dart';
import 'chat_screen.dart';
import 'create_group_screen.dart';
import 'group_chat_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _query = '';
  bool _hasShownUserNotFound = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Chat'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'CHATS'),
            Tab(text: 'GROUPS'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.camera_alt_outlined),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              } else if (value == 'logout') {
                ref.read(authViewModelProvider).signOut();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.person_outline),
                  title: Text('Profile'),
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout),
                  title: Text('Log out'),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                );
              },
              child: const Icon(Icons.group_add),
            )
          : FloatingActionButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Search for a contact above to start a chat.')),
                );
              },
              child: const Icon(Icons.chat),
            ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ChatsTab(
            searchController: _searchController,
            query: _query,
            hasShownUserNotFound: _hasShownUserNotFound,
            isDark: isDark,
            onSearchChanged: (value) {
              AppLogger.info(
                'home_screen',
                'Search field changed. raw="$value"',
              );
            },
            onSearchApply: _applySearch,
            onUpdateNotFoundShown: (value) {
              _hasShownUserNotFound = value;
            },
          ),
          _GroupsTab(isDark: isDark),
        ],
      ),
    );
  }
}

class _ChatsTab extends ConsumerWidget {
  final TextEditingController searchController;
  final String query;
  final bool hasShownUserNotFound;
  final bool isDark;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchApply;
  final ValueChanged<bool> onUpdateNotFoundShown;

  const _ChatsTab({
    required this.searchController,
    required this.query,
    required this.hasShownUserNotFound,
    required this.isDark,
    required this.onSearchChanged,
    required this.onSearchApply,
    required this.onUpdateNotFoundShown,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsState = ref.watch(chatsProvider);
    final membersState = ref.watch(membersProvider);
    final vm = ref.watch(chatListViewModelProvider);
    final searchFill = isDark ? const Color(0xFF2A3942) : WhatsAppPalette.searchFill;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
          child: Material(
            color: searchFill,
            borderRadius: BorderRadius.circular(20),
            child: TextField(
              controller: searchController,
              style: TextStyle(
                color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF111B21),
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search name or message…',
                hintStyle: TextStyle(
                  color: isDark ? const Color(0xFF8696A0) : WhatsAppPalette.subtitleGrey,
                ),
                prefixIcon: Icon(Icons.search, color: isDark ? const Color(0xFF8696A0) : WhatsAppPalette.subtitleGrey),
                suffixIcon: IconButton(
                  onPressed: onSearchApply,
                  icon: Icon(Icons.arrow_forward, color: isDark ? const Color(0xFF8696A0) : WhatsAppPalette.tealBar),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => onSearchChanged(v),
              onSubmitted: (_) => onSearchApply(),
            ),
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              final members = membersState.valueOrNull ?? const <AppUser>[];
              final chats = chatsState.valueOrNull ?? const <ChatThread>[];

              final isLoading = membersState.isLoading && chatsState.isLoading;
              if (isLoading) return const Center(child: CircularProgressIndicator());

              final filteredMembers = members
                  .where((m) =>
                      m.displayName.toLowerCase().contains(query) ||
                      m.email.toLowerCase().contains(query))
                  .toList();
              final filteredChats =
                  chats.where((c) => c.lastMessage.toLowerCase().contains(query)).toList();
              final canEvaluateNotFound = membersState.hasValue || chatsState.hasValue;
              final showNotFound = canEvaluateNotFound &&
                  query.trim().isNotEmpty &&
                  filteredMembers.isEmpty &&
                  filteredChats.isEmpty;

              if (showNotFound && !hasShownUserNotFound) {
                onUpdateNotFoundShown(true);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User not found')),
                  );
                });
              } else if (!showNotFound && hasShownUserNotFound) {
                onUpdateNotFoundShown(false);
              }

              return ListView(
                children: [
                  if (filteredMembers.isNotEmpty) _WaSectionHeader('Contacts on Smart Chat', isDark: isDark),
                  ...filteredMembers.map(
                    (member) => _WaChatRow(
                      leading: AppAvatar(name: member.displayName, photoUrl: member.photoUrl, radius: 26),
                      title: member.displayName,
                      subtitle: member.email,
                      trailing: null,
                      isDark: isDark,
                      onTap: () async {
                        final chatId = await vm.startChatWith(member.id);
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              chatId: chatId,
                              contactName: member.displayName,
                              contactPhotoUrl: member.photoUrl,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (filteredChats.isNotEmpty) _WaSectionHeader('Recent chats', isDark: isDark),
                  ...filteredChats.map((chat) => _ChatTile(chat: chat, isDark: isDark)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GroupsTab extends ConsumerWidget {
  final bool isDark;

  const _GroupsTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsState = ref.watch(groupsProvider);

    return groupsState.when(
      data: (groups) {
        if (groups.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.groups_2_outlined,
                    size: 72,
                    color: isDark ? const Color(0xFF8696A0) : WhatsAppPalette.subtitleGrey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No groups yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF111B21),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the green button to create a group.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF8696A0) : WhatsAppPalette.subtitleGrey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView(
          children: groups.map((group) => _GroupTile(group: group, isDark: isDark)).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Could not load groups.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _WaSectionHeader extends StatelessWidget {
  final String text;
  final bool isDark;

  const _WaSectionHeader(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: isDark ? const Color(0xFF8696A0) : WhatsAppPalette.tealBar,
        ),
      ),
    );
  }
}

class _WaChatRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final String? trailing;
  final bool isDark;
  final VoidCallback onTap;

  const _WaChatRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF111B21),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? const Color(0xFF8696A0) : WhatsAppPalette.subtitleGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF8696A0) : WhatsAppPalette.subtitleGrey,
                    ),
                  ),
              ],
            ),
          ),
          Divider(
            height: 1,
            indent: 68,
            color: isDark ? const Color(0xFF2A3942) : WhatsAppPalette.divider,
          ),
        ],
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final GroupThread group;
  final bool isDark;

  const _GroupTile({required this.group, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _WaChatRow(
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: isDark ? const Color(0xFF2A3942) : WhatsAppPalette.searchFill,
        backgroundImage: group.iconUrl == null ? null : NetworkImage(group.iconUrl!),
        child: group.iconUrl == null
            ? Icon(Icons.group, color: isDark ? const Color(0xFF8696A0) : WhatsAppPalette.subtitleGrey)
            : null,
      ),
      title: group.name,
      subtitle: group.lastMessage,
      trailing: TimeFormatter.formatChatTime(group.lastMessageTime),
      isDark: isDark,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupChatScreen(
              groupId: group.id,
              groupName: group.name,
            ),
          ),
        );
      },
    );
  }
}

class _ChatTile extends ConsumerWidget {
  final ChatThread chat;
  final bool isDark;

  const _ChatTile({required this.chat, required this.isDark});

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
        return _WaChatRow(
          leading: AppAvatar(name: name, photoUrl: user?.photoUrl, radius: 26),
          title: name,
          subtitle: chat.lastMessage,
          trailing: TimeFormatter.formatChatTime(chat.lastMessageTime),
          isDark: isDark,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatId: chat.id,
                contactName: name,
                contactPhotoUrl: user?.photoUrl,
              ),
            ),
          ),
        );
      },
    );
  }
}
