import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../features/chat/presentation/viewmodels/chat_list_view_model.dart';

class CreateStatusScreen extends ConsumerStatefulWidget {
  const CreateStatusScreen({super.key});

  @override
  ConsumerState<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends ConsumerState<CreateStatusScreen> {
  final _textController = TextEditingController();
  File? _pickedImage;
  bool _saving = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _pickedImage = File(picked.path));
  }

  Future<void> _saveStatus() async {
    final vm = ref.read(chatListViewModelProvider);
    setState(() => _saving = true);
    try {
      // Beginner note: if an image is selected we create an image status,
      // otherwise we save plain text status.
      if (_pickedImage != null) {
        await vm.createImageStatus(_pickedImage!, text: _textController.text);
      } else {
        await vm.createTextStatus(_textController.text);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create status')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _textController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Status text',
              hintText: 'What\'s on your mind?',
            ),
          ),
          const SizedBox(height: 12),
          if (_pickedImage != null) Image.file(_pickedImage!, height: 180, fit: BoxFit.cover),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo),
            label: const Text('Add image'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _saveStatus,
            child: Text(_saving ? 'Saving...' : 'Post status'),
          ),
        ],
      ),
    );
  }
}
