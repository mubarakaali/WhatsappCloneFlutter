import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../entities/app_user.dart';

abstract class AuthRepositoryContract {
  Stream<User?> authStateChanges();
  Future<void> signUp({required String email, required String password});
  Future<void> signIn({required String email, required String password});
  Future<void> signOut();
  Stream<AppUser> watchCurrentUserProfile();
  Future<void> updateProfile({required String displayName, File? imageFile});
}
