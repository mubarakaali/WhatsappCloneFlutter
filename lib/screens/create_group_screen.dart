import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/whatsapp_palette.dart';
import '../features/chat/presentation/viewmodels/chat_list_view_model.dart';
import '../widgets/app_avatar.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _groupNameController = TextEditingController();
  final Set<String> _selectedMembers = <String>{};
  File? _groupIconFile;
  bool _isSaving = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _pickGroupIcon(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;
    setState(() => _groupIconFile = File(picked.path));
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name.')),
      );
      return;
    }

    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(chatListViewModelProvider).createGroup(
            groupName: groupName,
            memberIds: _selectedMembers.toList(),
            iconFile: _groupIconFile,
          );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create group: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersState = ref.watch(membersProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('New group')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Group details',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF8696A0) : WhatsAppPalette.tealBar,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _groupNameController,
            decoration: const InputDecoration(
              labelText: 'Group subject',
              hintText: 'Add a subject for your group',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: isDark ? const Color(0xFF2A3942) : WhatsAppPalette.searchFill,
                backgroundImage: _groupIconFile == null ? null : FileImage(_groupIconFile!),
                child: _groupIconFile == null
                    ? Icon(Icons.group, color: isDark ? const Color(0xFF8696A0) : WhatsAppPalette.subtitleGrey)
                    : null,
              ),
              const SizedBox(width: 12),
              PopupMenuButton<ImageSource>(
                icon: Icon(Icons.add_a_photo_outlined, color: WhatsAppPalette.accentGreen),
                onSelected: _pickGroupIcon,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: ImageSource.gallery,
                    child: Text('Choose from gallery'),
                  ),
                  PopupMenuItem(
                    value: ImageSource.camera,
                    child: Text('Take from camera'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Add members',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF8696A0) : WhatsAppPalette.tealBar,
            ),
          ),
          const SizedBox(height: 8),
          membersState.when(
            data: (members) => Column(
              children: members
                  .map(
                    (member) => CheckboxListTile(
                      value: _selectedMembers.contains(member.id),
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedMembers.add(member.id);
                          } else {
                            _selectedMembers.remove(member.id);
                          }
                        });
                      },
                      secondary: AppAvatar(
                        name: member.displayName,
                        photoUrl: member.photoUrl,
                      ),
                      title: Text(member.displayName),
                      subtitle: Text(member.email),
                    ),
                  )
                  .toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Could not load members.'),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isSaving ? null : _createGroup,
            icon: const Icon(Icons.group_add),
            label: Text(_isSaving ? 'Creating...' : 'Create Group'),
          ),
        ],
      ),
    );
  }
}
