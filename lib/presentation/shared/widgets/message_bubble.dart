import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/theme/whatsapp_palette.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../domain/entities/chat_message.dart';
import 'app_avatar.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final String senderName;
  final String? senderPhotoUrl;

  /// One-to-one chats: hide name/avatar row like WhatsApp direct messages.
  final bool compact;
  final bool showReadTicks;
  final String currentUserId;
  final Future<void> Function(String emoji)? onReactionSelected;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.senderName,
    required this.senderPhotoUrl,
    this.compact = false,
    this.showReadTicks = false,
    this.currentUserId = '',
    this.onReactionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outgoing = isDark ? WhatsAppPalette.darkBubbleOut : WhatsAppPalette.bubbleOutgoing;
    final incoming = isDark ? WhatsAppPalette.darkBubbleIn : WhatsAppPalette.bubbleIncoming;
    final bubbleColor = isMine ? outgoing : incoming;
    final timeColor = isDark ? const Color(0xFF8696A0) : WhatsAppPalette.subtitleGrey;
    final nameColor = isDark ? const Color(0xFF53BDEB) : WhatsAppPalette.tealBar;

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(8),
      topRight: const Radius.circular(8),
      bottomLeft: Radius.circular(isMine ? 8 : 2),
      bottomRight: Radius.circular(isMine ? 2 : 8),
    );

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onReactionSelected == null ? null : () => _openReactionPicker(context),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          constraints: const BoxConstraints(maxWidth: 300),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!compact)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      AppAvatar(
                        name: senderName,
                        photoUrl: senderPhotoUrl,
                        radius: 10,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          senderName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: nameColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      message.imageUrl!,
                      height: 170,
                      width: 250,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              if (message.audioUrl != null && message.audioUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _AudioMessagePlayer(
                    audioUrl: message.audioUrl!,
                    durationMs: message.audioDurationMs,
                  ),
                ),
              if (message.text.isNotEmpty)
                Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.35,
                    color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF111B21),
                  ),
                ),
              if (message.reactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _ReactionChips(
                    reactions: message.reactions,
                    currentUserId: currentUserId,
                  ),
                ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      TimeFormatter.formatChatTime(message.createdAt),
                      style: TextStyle(fontSize: 11, color: timeColor),
                    ),
                    if (isMine && showReadTicks) ...[
                      const SizedBox(width: 4),
                      Text(
                        _tickTextForMessage(),
                        style: TextStyle(
                          fontSize: 11,
                          color: _tickColor(isDark),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _tickTextForMessage() {
    final isRead = message.readBy.length > 1;
    final isDelivered = message.deliveredTo.length > 1;
    if (isRead) return '✓✓';
    if (isDelivered) return '✓✓';
    return '✓';
  }

  Color _tickColor(bool isDark) {
    final isRead = message.readBy.length > 1;
    if (isRead) {
      return const Color(0xFF53BDEB);
    }
    return isDark ? const Color(0xFFB3C0C6) : WhatsAppPalette.subtitleGrey;
  }

  Future<void> _openReactionPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        const options = ['👍', '❤️', '😂', '😢', '🔥', '✖️'];
        return SizedBox(
          height: 96,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: options
                .map(
                  (emoji) => IconButton(
                    onPressed: () => Navigator.pop(sheetContext, emoji),
                    icon: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
    if (selected == null || onReactionSelected == null) return;
    await onReactionSelected!(selected);
  }
}

class _ReactionChips extends StatelessWidget {
  final Map<String, String> reactions;
  final String currentUserId;

  const _ReactionChips({
    required this.reactions,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = <String, int>{};
    for (final emoji in reactions.values) {
      grouped[emoji] = (grouped[emoji] ?? 0) + 1;
    }
    return Wrap(
      spacing: 6,
      children: grouped.entries.map((entry) {
        final mine = reactions[currentUserId] == entry.key;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: mine ? const Color(0x5525D366) : Colors.black.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('${entry.key} ${entry.value}', style: const TextStyle(fontSize: 12)),
        );
      }).toList(),
    );
  }
}

class _AudioMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final int? durationMs;

  const _AudioMessagePlayer({
    required this.audioUrl,
    required this.durationMs,
  });

  @override
  State<_AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<_AudioMessagePlayer> {
  late final AudioPlayer _player;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state.playing);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = ((widget.durationMs ?? 0) / 1000).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () async {
            if (_isPlaying) {
              await _player.pause();
              return;
            }
            await _player.setUrl(widget.audioUrl);
            await _player.play();
          },
          icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
        ),
        const SizedBox(width: 6),
        Text(seconds <= 0 ? 'Audio' : '${seconds}s'),
      ],
    );
  }
}
