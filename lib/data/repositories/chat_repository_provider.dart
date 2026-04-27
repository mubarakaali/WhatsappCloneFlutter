import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/chat_repository_contract.dart';
import 'chat_repository_adapter.dart';
import 'chat_repository_impl.dart';

/// DI provider for chat repository contract.
final chatRepositoryProvider = Provider<ChatRepositoryContract>((ref) {
  final source = ChatRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  );
  return ChatRepositoryAdapter(source);
});
