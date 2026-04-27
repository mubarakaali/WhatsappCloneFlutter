import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/app_user.dart';
import '../../../../domain/repositories/auth_repository_contract.dart';
import '../../../../data/repositories/auth_repository.dart';

final authStateProvider = StreamProvider<User?>((ref) => ref.watch(authRepositoryProvider).authStateChanges());
final authViewModelProvider = Provider<AuthViewModel>((ref) => AuthViewModel(repository: ref.watch(authRepositoryProvider)));
final currentUserProfileProvider = StreamProvider<AppUser>((ref) => ref.watch(authRepositoryProvider).watchCurrentUserProfile());

class AuthViewModel {
  final AuthRepositoryContract repository;
  AuthViewModel({required this.repository});

  Future<String?> signUp(String email, String password) async {
    try {
      await repository.signUp(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await repository.signIn(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut() => repository.signOut();

  Future<String?> updateProfile({required String displayName, File? imageFile}) async {
    try {
      await repository.updateProfile(displayName: displayName, imageFile: imageFile);
      return null;
    } catch (e) {
      return 'Failed to update profile: $e';
    }
  }
}
