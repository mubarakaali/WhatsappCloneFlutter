import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/auth_repository_contract.dart';
import 'auth_repository_adapter.dart';
import 'auth_repository_impl.dart';

/// DI provider for auth repository contract.
final authRepositoryProvider = Provider<AuthRepositoryContract>((ref) {
  final source = AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  );
  return AuthRepositoryAdapter(source);
});
