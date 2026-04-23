import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../../../models/app_user.dart';
import '../../../models/chat_message.dart';
import '../../../models/chat_thread.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository(
      auth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
      storage: FirebaseStorage.instance,
    ));

class ChatRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  ChatRepository({required this.auth, required this.firestore, required this.storage});

  String get _currentUid => auth.currentUser?.uid ?? '';

  Stream<List<ChatThread>> watchUserChats() => firestore
      .collection(AppConstants.chatsCollection)
      .where('participants', arrayContains: _currentUid)
      .orderBy('lastMessageTime', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => ChatThread.fromMap(doc.id, doc.data())).toList());

  Stream<List<AppUser>> watchAllUsers() => firestore.collection(AppConstants.usersCollection).snapshots().map((snapshot) => snapshot.docs
      .map((doc) => AppUser.fromMap(doc.id, doc.data()))
      .where((user) => user.id != _currentUid)
      .toList());

  Future<AppUser?> getUserById(String uid) async {
    final doc = await firestore.collection(AppConstants.usersCollection).doc(uid).get();
    final data = doc.data();
    if (data == null) return null;
    return AppUser.fromMap(doc.id, data);
  }

  String buildChatId(String userA, String userB) {
    final sorted = [userA, userB]..sort();
    return sorted.join('_');
  }

  Future<String> ensureChatWith(String otherUserId) async {
    final chatId = buildChatId(_currentUid, otherUserId);
    final chatRef = firestore.collection(AppConstants.chatsCollection).doc(chatId);
    final snapshot = await chatRef.get();
    AppLogger.info('chat_repository', 'Ensuring chat exists for chatId=$chatId');

    // Create chat thread only once; next opens reuse same thread.
    if (!snapshot.exists) {
      await chatRef.set({
        'participants': [_currentUid, otherUserId],
        'lastMessage': 'Say hello',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
      AppLogger.info('chat_repository', 'Created new chat thread chatId=$chatId');
    }

    return chatId;
  }

  Stream<List<ChatMessage>> watchMessages(String chatId) => firestore
      .collection(AppConstants.chatsCollection)
      .doc(chatId)
      .collection(AppConstants.messagesSubCollection)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => ChatMessage.fromMap(doc.id, doc.data())).toList());

  Future<void> sendTextMessage({required String chatId, required String text}) async {
    if (text.trim().isEmpty) return;
    AppLogger.info('chat_repository', 'Sending text message to chatId=$chatId');

    final ref = firestore.collection(AppConstants.chatsCollection).doc(chatId).collection(AppConstants.messagesSubCollection).doc();
    await ref.set({
      'senderId': _currentUid,
      'text': text.trim(),
      'imageUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _updateThread(chatId, text.trim());
    AppLogger.info('chat_repository', 'Text message sent and thread preview updated for chatId=$chatId');
  }

  Future<void> sendImageMessage({required String chatId, required File imageFile}) async {
    // Upload image first, then save only its URL inside message document.
    AppLogger.info('chat_repository', 'Uploading image message for chatId=$chatId');
    final imageRef = storage.ref('chat_images/$chatId/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await imageRef.putFile(imageFile);
    final imageUrl = await imageRef.getDownloadURL();

    final ref = firestore.collection(AppConstants.chatsCollection).doc(chatId).collection(AppConstants.messagesSubCollection).doc();
    await ref.set({
      'senderId': _currentUid,
      'text': '',
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _updateThread(chatId, 'Image');
    AppLogger.info('chat_repository', 'Image message sent and thread preview updated for chatId=$chatId');
  }

  Future<void> _updateThread(String chatId, String preview) => firestore.collection(AppConstants.chatsCollection).doc(chatId).set({
        'lastMessage': preview,
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  String getCurrentUid() => _currentUid;
}
