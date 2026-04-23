import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/utils/app_logger.dart';
import '../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../widgets/app_avatar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  File? _pickedImage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    AppLogger.info('profile_screen', 'User selected new profile image');
    setState(() => _pickedImage = File(file.path));
  }

  Future<void> _save() async {
    AppLogger.info('profile_screen', 'Update profile tapped with displayName=${_nameController.text.trim()}');
    final error = await ref.read(authViewModelProvider).updateProfile(displayName: _nameController.text.trim(), imageFile: _pickedImage);
    if (!mounted) return;
    if (error != null) {
      AppLogger.error('profile_screen', 'Profile update failed', error);
    } else {
      AppLogger.info('profile_screen', 'Profile updated successfully');
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Profile updated')));
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileState.when(
        data: (user) {
          // Keep existing profile data visible as default form value.
          if (_nameController.text.isEmpty) _nameController.text = user.displayName;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(child: AppAvatar(name: user.displayName, photoUrl: user.photoUrl, radius: 40)),
              if (_pickedImage != null) Padding(padding: const EdgeInsets.only(top: 12), child: Image.file(_pickedImage!, height: 120)),
              TextButton.icon(onPressed: _pickImage, icon: const Icon(Icons.photo), label: const Text('Change photo')),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: user.email,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
              ),
              const SizedBox(height: 12),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Display name')),
              const SizedBox(height: 16),
              FilledButton(onPressed: _save, child: const Text('Update Profile')),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(child: Text('Cannot load profile')),
      ),
    );
  }
}
