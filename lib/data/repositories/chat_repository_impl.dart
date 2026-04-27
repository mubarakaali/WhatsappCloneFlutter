import 'dart:developer' as developer;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_thread.dart';
import '../../domain/entities/group_thread.dart';
import '../../domain/entities/status_item.dart';
part 'chat_repository_queries.dart';
part 'chat_repository_messages.dart';
part 'chat_repository_reactions.dart';
part 'chat_repository_status.dart';

/// Concrete Firebase implementation.
class ChatRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  ChatRepository({required this.auth, required this.firestore, required this.storage});

  String get _currentUid => auth.currentUser?.uid ?? '';
  String getCurrentUid() => _currentUid;
}
