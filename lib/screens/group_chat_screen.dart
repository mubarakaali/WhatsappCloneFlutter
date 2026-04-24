import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/whatsapp_palette.dart';
import '../features/chat/presentation/viewmodels/chat_list_view_model.dart';
import '../features/chat/presentation/viewmodels/chat_view_model.dart';
import '../models/app_user.dart';
import '../widgets/message_bubble.dart';
import '../widgets/whatsapp_input_bar.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    await ref.read(chatViewModelProvider).sendGroupText(widget.groupId, _messageController.text);
    _messageController.clear();
  }

  Future<void> _sendImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;
    await ref.read(chatViewModelProvider).sendGroupImage(widget.groupId, File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(groupMessagesProvider(widget.groupId));
    final myUid = ref.watch(chatViewModelProvider).currentUid();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatBg = isDark ? WhatsAppPalette.darkChatBg : WhatsAppPalette.chatBackground;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.videocam_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.call_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: Container(
        color: chatBg,
        child: Column(
          children: [
            Expanded(
              child: messagesState.when(
                data: (messages) => ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderId == myUid;
                    return FutureBuilder<AppUser?>(
                      future: ref.read(chatListViewModelProvider).userById(message.senderId),
                      builder: (context, snapshot) {
                        final sender = snapshot.data;
                        return MessageBubble(
                          message: message,
                          isMine: isMine,
                          compact: false,
                          senderName: sender?.displayName ?? (isMine ? 'You' : 'Member'),
                          senderPhotoUrl: sender?.photoUrl,
                        );
                      },
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => const Center(child: Text('Could not load group messages.')),
              ),
            ),
            WhatsAppInputBar(
              controller: _messageController,
              onSend: _sendText,
              onPickImage: _sendImage,
            ),
          ],
        ),
      ),
    );
  }
}
