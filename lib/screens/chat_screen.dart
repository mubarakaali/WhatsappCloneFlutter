import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/utils/app_logger.dart';
import '../features/chat/presentation/viewmodels/chat_list_view_model.dart';
import '../features/chat/presentation/viewmodels/chat_view_model.dart';
import '../models/app_user.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String contactName;
  final String? contactPhotoUrl;

  const ChatScreen({super.key, required this.chatId, required this.contactName, required this.contactPhotoUrl});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    AppLogger.info('chat_screen', 'Sending text to chatId=${widget.chatId}');
    await ref.read(chatViewModelProvider).sendText(widget.chatId, _messageController.text);
    _messageController.clear();
  }

  Future<void> _sendImage(ImageSource source) async {
    AppLogger.info('chat_screen', 'Image picker opened for source=$source');
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;
    AppLogger.info('chat_screen', 'Image selected and sending to chatId=${widget.chatId}');
    await ref.read(chatViewModelProvider).sendImage(widget.chatId, File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(chatMessagesProvider(widget.chatId));
    final myUid = ref.watch(chatViewModelProvider).currentUid();

    return Scaffold(
      appBar: AppBar(title: Text(widget.contactName)),
      body: Column(
        children: [
          Expanded(
            child: messagesState.when(
              data: (messages) => ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMine = message.senderId == myUid;
                  return FutureBuilder<AppUser?>(
                    future: ref.read(chatListViewModelProvider).userById(message.senderId),
                    builder: (context, snapshot) => MessageBubble(message: message, isMine: isMine, senderName: snapshot.data?.displayName ?? (isMine ? 'You' : widget.contactName)),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => const Center(child: Text('Cannot load messages')),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Row(
                children: [
                  PopupMenuButton<ImageSource>(
                    icon: const Icon(Icons.add_circle_outline),
                    onSelected: _sendImage,
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: ImageSource.gallery, child: Text('Gallery')),
                      PopupMenuItem(value: ImageSource.camera, child: Text('Camera')),
                    ],
                  ),
                  Expanded(child: TextField(controller: _messageController, decoration: const InputDecoration(hintText: 'Type a message...'))),
                  IconButton(onPressed: _sendText, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
