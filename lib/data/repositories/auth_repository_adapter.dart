import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository_contract.dart';
import 'auth_repository_impl.dart';

/// Adapter exposing [AuthRepository] via [AuthRepositoryContract].
class AuthRepositoryAdapter implements AuthRepositoryContract {
  final AuthRepository _source;
  AuthRepositoryAdapter(this._source);

  @override
  Stream<User?> authStateChanges() => _source.authStateChanges();

  @override
  Future<void> signIn({required String email, required String password}) => _source.signIn(email: email, password: password);

  @override
  Future<void> signOut() => _source.signOut();

  @override
  Future<void> signUp({required String email, required String password}) => _source.signUp(email: email, password: password);

  @override
  Future<void> updateProfile({required String displayName, File? imageFile}) =>
      _source.updateProfile(displayName: displayName, imageFile: imageFile);

  @override
  Stream<AppUser> watchCurrentUserProfile() => _source.watchCurrentUserProfile();
}
