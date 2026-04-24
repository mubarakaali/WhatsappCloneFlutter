import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/whatsapp_palette.dart';

class WhatsAppInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final void Function(ImageSource source) onPickImage;

  const WhatsAppInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = isDark ? const Color(0xFF202C33) : WhatsAppPalette.inputBarGrey;
    final fieldFill = isDark ? const Color(0xFF2A3942) : Colors.white;
    final iconColor = isDark ? const Color(0xFF8696A0) : WhatsAppPalette.subtitleGrey;

    return Material(
      color: barColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PopupMenuButton<ImageSource>(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.add, color: iconColor, size: 28),
                onSelected: onPickImage,
                itemBuilder: (context) => const [
                  PopupMenuItem(value: ImageSource.gallery, child: Text('Gallery')),
                  PopupMenuItem(value: ImageSource.camera, child: Text('Camera')),
                ],
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: fieldFill,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_emotions_outlined, color: iconColor, size: 24),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          minLines: 1,
                          maxLines: 6,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Message',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Material(
                color: WhatsAppPalette.accentGreen,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onSend,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
