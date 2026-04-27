import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/whatsapp_palette.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../features/chat/presentation/viewmodels/chat_list_view_model.dart';
import '../../../../features/chat/presentation/viewmodels/chat_view_model.dart';
import '../../../../features/chat/presentation/utils/hold_to_record_controller.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/message_bubble.dart';
import '../../../shared/widgets/whatsapp_input_bar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String contactName;
  final String? contactPhotoUrl;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.contactName,
    required this.contactPhotoUrl,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final HoldToRecordController _recordController = HoldToRecordController();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatViewModelProvider).markChatRead(widget.chatId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _recordController.dispose();
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

  Future<void> _startRecording() async {
    await _recordController.start(filePrefix: 'audio');
    if (!mounted) return;
    setState(() => _isRecording = _recordController.isRecording);
  }

  Future<void> _stopRecordingAndSend() async {
    if (!_recordController.isRecording) return;
    final clip = await _recordController.stop();
    if (!mounted) return;
    setState(() => _isRecording = _recordController.isRecording);
    if (clip == null) return;
    await ref.read(chatViewModelProvider).sendAudio(widget.chatId, clip.file, clip.durationMs);
  }

  Future<void> _reactToMessage(String messageId, String emoji) async {
    if (emoji == '✖️') {
      await ref.read(chatViewModelProvider).removeReaction(widget.chatId, messageId);
      return;
    }
    await ref.read(chatViewModelProvider).reactToMessage(widget.chatId, messageId, emoji);
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(chatMessagesProvider(widget.chatId));
    final myUid = ref.watch(chatViewModelProvider).currentUid();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatBg = isDark ? WhatsAppPalette.darkChatBg : WhatsAppPalette.chatBackground;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leadingWidth: 32,
        title: Row(
          children: [
            AppAvatar(
              name: widget.contactName,
              photoUrl: widget.contactPhotoUrl,
              radius: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.contactName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
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
                      builder: (context, snapshot) => MessageBubble(
                        message: message,
                        isMine: isMine,
                        compact: true,
                        showReadTicks: true,
                        currentUserId: myUid,
                        senderName: snapshot.data?.displayName ?? (isMine ? 'You' : widget.contactName),
                        senderPhotoUrl: snapshot.data?.photoUrl,
                        onReactionSelected: (emoji) => _reactToMessage(message.id, emoji),
                      ),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => const Center(child: Text('Cannot load messages')),
              ),
            ),
            WhatsAppInputBar(
              controller: _messageController,
              onSend: _sendText,
              onPickImage: _sendImage,
              onStartRecording: _startRecording,
              onStopRecording: _stopRecordingAndSend,
              isRecording: _isRecording,
            ),
          ],
        ),
      ),
    );
  }
}
