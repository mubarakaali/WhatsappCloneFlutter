import 'dart:developer' as developer;
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
import '../../../models/group_thread.dart';

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

  Stream<List<GroupThread>> watchUserGroups() => auth.authStateChanges().asyncExpand((user) {
        if (user == null || user.uid.isEmpty) {
          return Stream.value(const <GroupThread>[]);
        }
        return _watchUserGroupsForUid(user.uid);
      });

  Stream<List<GroupThread>> _watchUserGroupsForUid(String uid) => firestore
      .collection(AppConstants.groupsCollection)
      .where('members', arrayContains: uid)
      .snapshots()
      .map((snapshot) {
        final list = <GroupThread>[];
        for (final doc in snapshot.docs) {
          try {
            list.add(GroupThread.fromMap(doc.id, doc.data()));
          } catch (e, st) {
            AppLogger.error('chat_repository', 'Skipping invalid group doc id=${doc.id}', e);
            developer.log('group doc parse', error: e, stackTrace: st);
          }
        }
        list.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        return list;
      });

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

  Future<String> createGroup({
    required String groupName,
    required List<String> memberIds,
    File? iconFile,
  }) async {
    final groupRef = firestore.collection(AppConstants.groupsCollection).doc();
    final allMembers = <String>{_currentUid, ...memberIds}.toList();
    String? iconUrl;

    if (iconFile != null) {
      final iconRef = storage.ref('group_icons/${groupRef.id}.jpg');
      await iconRef.putFile(iconFile);
      iconUrl = await iconRef.getDownloadURL();
    }

    await groupRef.set({
      'name': groupName.trim(),
      'iconUrl': iconUrl,
      'members': allMembers,
      'createdBy': _currentUid,
      'lastMessage': 'Group created',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
    AppLogger.info('chat_repository', 'Group created id=${groupRef.id} members=${allMembers.length}');
    return groupRef.id;
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

  Stream<List<ChatMessage>> watchGroupMessages(String groupId) => firestore
      .collection(AppConstants.groupsCollection)
      .doc(groupId)
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

  Future<void> sendGroupTextMessage({
    required String groupId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    final ref = firestore
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.messagesSubCollection)
        .doc();

    await ref.set({
      'senderId': _currentUid,
      'text': text.trim(),
      'imageUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _updateGroupThread(groupId, text.trim());
  }

  Future<void> sendGroupImageMessage({
    required String groupId,
    required File imageFile,
  }) async {
    final imageRef = storage.ref('group_images/$groupId/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await imageRef.putFile(imageFile);
    final imageUrl = await imageRef.getDownloadURL();

    final ref = firestore
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.messagesSubCollection)
        .doc();

    await ref.set({
      'senderId': _currentUid,
      'text': '',
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _updateGroupThread(groupId, 'Image');
  }

  Future<void> _updateThread(String chatId, String preview) => firestore.collection(AppConstants.chatsCollection).doc(chatId).set({
        'lastMessage': preview,
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> _updateGroupThread(String groupId, String preview) => firestore.collection(AppConstants.groupsCollection).doc(groupId).set({
        'lastMessage': preview,
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  String getCurrentUid() => _currentUid;
}
