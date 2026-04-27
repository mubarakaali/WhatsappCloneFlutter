import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/whatsapp_palette.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../../../shared/widgets/app_avatar.dart';

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
    final error = await ref.read(authViewModelProvider).updateProfile(
          displayName: _nameController.text.trim(),
          imageFile: _pickedImage,
        );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionBg = isDark ? const Color(0xFF1F2C34) : Colors.white;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileState.when(
        data: (user) {
          if (_nameController.text.isEmpty) _nameController.text = user.displayName;
          return ListView(
            children: [
              Container(
                width: double.infinity,
                color: isDark ? WhatsAppPalette.darkAppBar : WhatsAppPalette.tealBar,
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Center(
                            child: AppAvatar(name: user.displayName, photoUrl: user.photoUrl, radius: 48),
                          ),
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Material(
                              color: WhatsAppPalette.accentGreen,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _pickImage,
                                child: const Padding(
                                  padding: EdgeInsets.all(7),
                                  child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_pickedImage != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_pickedImage!, height: 100),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Material(
                color: sectionBg,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Email'),
                      subtitle: Text(user.email),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Display name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(child: Text('Cannot load profile')),
      ),
    );
  }
}
