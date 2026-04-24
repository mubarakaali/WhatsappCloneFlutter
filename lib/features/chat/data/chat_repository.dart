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
import '../../../models/status_item.dart';

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

  Stream<List<ChatThread>> watchUserChats() => auth.authStateChanges().asyncExpand((user) {
        if (user == null || user.uid.isEmpty) {
          return Stream.value(const <ChatThread>[]);
        }
        return _watchUserChatsForUid(user.uid);
      });

  Stream<List<ChatThread>> _watchUserChatsForUid(String uid) => firestore
      .collection(AppConstants.chatsCollection)
      .where('participants', arrayContains: uid)
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

  Stream<List<AppUser>> watchAllUsers() => auth.authStateChanges().asyncExpand((user) {
        final uid = user?.uid ?? '';
        if (uid.isEmpty) {
          return Stream.value(const <AppUser>[]);
        }
        return firestore.collection(AppConstants.usersCollection).snapshots().map(
              (snapshot) => snapshot.docs
                  .map((doc) => AppUser.fromMap(doc.id, doc.data()))
                  .where((appUser) => appUser.id != uid)
                  .toList(),
            );
      });

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
    if (otherUserId == _currentUid) {
      throw StateError('Cannot create a chat with yourself.');
    }
    final chatId = buildChatId(_currentUid, otherUserId);
    final chatRef = firestore.collection(AppConstants.chatsCollection).doc(chatId);
    AppLogger.info('chat_repository', 'Ensuring chat exists for chatId=$chatId');
    // We use merge without pre-read so rules do not need a separate get permission.
    await chatRef.set({
      'participants': [_currentUid, otherUserId],
      'lastMessage': 'Say hello',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCounts': {
        _currentUid: 0,
        otherUserId: 0,
      },
    }, SetOptions(merge: true));

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

  Stream<List<StatusItem>> watchStatuses() => firestore
      .collectionGroup(AppConstants.statusItemsSubCollection)
      .where('expiresAt', isGreaterThan: Timestamp.now())
      .orderBy('expiresAt')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => StatusItem.fromMap(doc.id, doc.data())).toList());

  Future<void> sendTextMessage({required String chatId, required String text}) async {
    if (text.trim().isEmpty) return;
    AppLogger.info('chat_repository', 'Sending text message to chatId=$chatId');

    final participants = await _chatParticipants(chatId);
    final ref = firestore.collection(AppConstants.chatsCollection).doc(chatId).collection(AppConstants.messagesSubCollection).doc();
    await ref.set({
      'senderId': _currentUid,
      'text': text.trim(),
      'imageUrl': null,
      'audioUrl': null,
      'audioDurationMs': null,
      'type': MessageType.text.name,
      // Beginner note: sender sees this message as delivered/read to self immediately.
      'deliveredTo': [_currentUid],
      'readBy': [_currentUid],
      'reactions': <String, String>{},
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _updateThread(chatId, text.trim(), participants: participants, senderId: _currentUid);
    AppLogger.info('chat_repository', 'Text message sent and thread preview updated for chatId=$chatId');
  }

  Future<void> sendImageMessage({required String chatId, required File imageFile}) async {
    // Upload image first, then save only its URL inside message document.
    AppLogger.info('chat_repository', 'Uploading image message for chatId=$chatId');
    final imageRef = storage.ref('chat_images/$chatId/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await imageRef.putFile(imageFile);
    final imageUrl = await imageRef.getDownloadURL();

    final participants = await _chatParticipants(chatId);
    final ref = firestore.collection(AppConstants.chatsCollection).doc(chatId).collection(AppConstants.messagesSubCollection).doc();
    await ref.set({
      'senderId': _currentUid,
      'text': '',
      'imageUrl': imageUrl,
      'audioUrl': null,
      'audioDurationMs': null,
      'type': MessageType.image.name,
      'deliveredTo': [_currentUid],
      'readBy': [_currentUid],
      'reactions': <String, String>{},
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _updateThread(chatId, 'Image', participants: participants, senderId: _currentUid);
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
      'audioUrl': null,
      'audioDurationMs': null,
      'type': MessageType.text.name,
      'deliveredTo': [_currentUid],
      'readBy': [_currentUid],
      'reactions': <String, String>{},
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
      'audioUrl': null,
      'audioDurationMs': null,
      'type': MessageType.image.name,
      'deliveredTo': [_currentUid],
      'readBy': [_currentUid],
      'reactions': <String, String>{},
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _updateGroupThread(groupId, 'Image');
  }

  Future<void> sendAudioMessage({
    required String chatId,
    required File audioFile,
    required int durationMs,
  }) async {
    final participants = await _chatParticipants(chatId);
    final audioRef = storage.ref('chat_audio/$chatId/${DateTime.now().millisecondsSinceEpoch}.m4a');
    await audioRef.putFile(audioFile);
    final audioUrl = await audioRef.getDownloadURL();

    final ref = firestore.collection(AppConstants.chatsCollection).doc(chatId).collection(AppConstants.messagesSubCollection).doc();
    await ref.set({
      'senderId': _currentUid,
      'text': '',
      'imageUrl': null,
      'audioUrl': audioUrl,
      'audioDurationMs': durationMs,
      'type': MessageType.audio.name,
      'deliveredTo': [_currentUid],
      'readBy': [_currentUid],
      'reactions': <String, String>{},
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _updateThread(chatId, 'Audio', participants: participants, senderId: _currentUid);
  }

  Future<void> sendGroupAudioMessage({
    required String groupId,
    required File audioFile,
    required int durationMs,
  }) async {
    final audioRef = storage.ref('group_audio/$groupId/${DateTime.now().millisecondsSinceEpoch}.m4a');
    await audioRef.putFile(audioFile);
    final audioUrl = await audioRef.getDownloadURL();

    final ref = firestore
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.messagesSubCollection)
        .doc();

    await ref.set({
      'senderId': _currentUid,
      'text': '',
      'imageUrl': null,
      'audioUrl': audioUrl,
      'audioDurationMs': durationMs,
      'type': MessageType.audio.name,
      'deliveredTo': [_currentUid],
      'readBy': [_currentUid],
      'reactions': <String, String>{},
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _updateGroupThread(groupId, 'Audio');
  }

  Future<void> setMessageReaction({
    required String chatId,
    required String messageId,
    required String emoji,
  }) async {
    await firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesSubCollection)
        .doc(messageId)
        .set({
      'reactions': {_currentUid: emoji},
    }, SetOptions(merge: true));
  }

  Future<void> removeMessageReaction({
    required String chatId,
    required String messageId,
  }) async {
    await firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesSubCollection)
        .doc(messageId)
        .update({
      'reactions.$_currentUid': FieldValue.delete(),
    });
  }

  Future<void> setGroupMessageReaction({
    required String groupId,
    required String messageId,
    required String emoji,
  }) async {
    await firestore
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.messagesSubCollection)
        .doc(messageId)
        .set({
      'reactions': {_currentUid: emoji},
    }, SetOptions(merge: true));
  }

  Future<void> removeGroupMessageReaction({
    required String groupId,
    required String messageId,
  }) async {
    await firestore
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.messagesSubCollection)
        .doc(messageId)
        .update({
      'reactions.$_currentUid': FieldValue.delete(),
    });
  }

  Future<void> createTextStatus(String text) async {
    final ref = firestore
        .collection(AppConstants.statusesCollection)
        .doc(_currentUid)
        .collection(AppConstants.statusItemsSubCollection)
        .doc();
    final now = DateTime.now();
    await ref.set({
      'userId': _currentUid,
      'type': StatusType.text.name,
      'text': text.trim(),
      'imageUrl': null,
      'createdAt': Timestamp.fromDate(now),
      // Beginner note: the client hides status once expiresAt is older than now.
      'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 24))),
    });
  }

  Future<void> createImageStatus(File imageFile, {String text = ''}) async {
    final statusId = firestore
        .collection(AppConstants.statusesCollection)
        .doc(_currentUid)
        .collection(AppConstants.statusItemsSubCollection)
        .doc()
        .id;
    final imageRef = storage.ref('statuses/$_currentUid/$statusId.jpg');
    await imageRef.putFile(imageFile);
    final imageUrl = await imageRef.getDownloadURL();
    final now = DateTime.now();
    await firestore
        .collection(AppConstants.statusesCollection)
        .doc(_currentUid)
        .collection(AppConstants.statusItemsSubCollection)
        .doc(statusId)
        .set({
      'userId': _currentUid,
      'type': StatusType.image.name,
      'text': text.trim(),
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 24))),
    });
  }

  Future<void> markChatAsRead(String chatId) async {
    final uid = _currentUid;
    if (uid.isEmpty) return;
    final chatRef = firestore.collection(AppConstants.chatsCollection).doc(chatId);
    try {
      await chatRef.set({
        'unreadCounts.$uid': 0,
      }, SetOptions(merge: true));
    } catch (e) {
      AppLogger.error('chat_repository', 'Could not reset unread count', e);
    }

    try {
      final unreadMessages = await chatRef
          .collection(AppConstants.messagesSubCollection)
          .where('senderId', isNotEqualTo: uid)
          .get();

      for (final doc in unreadMessages.docs) {
        await doc.reference.update({
          'deliveredTo': FieldValue.arrayUnion([uid]),
          'readBy': FieldValue.arrayUnion([uid]),
        });
      }
    } catch (e) {
      AppLogger.error('chat_repository', 'Could not mark messages as read', e);
    }
  }

  Future<void> _updateThread(
    String chatId,
    String preview, {
    required List<String> participants,
    required String senderId,
  }) async {
    final updates = <String, dynamic>{
      'lastMessage': preview,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCounts.$senderId': 0,
    };
    for (final uid in participants) {
      if (uid == senderId) continue;
      updates['unreadCounts.$uid'] = FieldValue.increment(1);
    }
    await firestore.collection(AppConstants.chatsCollection).doc(chatId).set(updates, SetOptions(merge: true));
  }

  Future<void> _updateGroupThread(String groupId, String preview) => firestore.collection(AppConstants.groupsCollection).doc(groupId).set({
        'lastMessage': preview,
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<List<String>> _chatParticipants(String chatId) async {
    final snapshot = await firestore.collection(AppConstants.chatsCollection).doc(chatId).get();
    final data = snapshot.data();
    final participants = List<String>.from(data?['participants'] as List? ?? const <String>[]);
    if (participants.isEmpty && _currentUid.isNotEmpty) {
      return <String>[_currentUid];
    }
    return participants;
  }

  String getCurrentUid() => _currentUid;
}
