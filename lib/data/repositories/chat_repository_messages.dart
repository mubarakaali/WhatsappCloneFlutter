part of 'chat_repository_impl.dart';

extension ChatRepositoryMessages on ChatRepository {
  String buildChatId(String userA, String userB) {
    final sorted = [userA, userB]..sort();
    return sorted.join('_');
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

  Future<String> ensureChatWith(String otherUserId) async {
    if (otherUserId == _currentUid) {
      throw StateError('Cannot create a chat with yourself.');
    }
    final chatId = buildChatId(_currentUid, otherUserId);
    final chatRef = firestore.collection(AppConstants.chatsCollection).doc(chatId);
    AppLogger.info('chat_repository', 'Ensuring chat exists for chatId=$chatId');
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

  Future<void> sendTextMessage({required String chatId, required String text}) async {
    if (text.trim().isEmpty) return;
    final participants = await _chatParticipants(chatId);
    final ref = firestore.collection(AppConstants.chatsCollection).doc(chatId).collection(AppConstants.messagesSubCollection).doc();
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
    await _updateThread(chatId, text.trim(), participants: participants, senderId: _currentUid);
  }

  Future<void> sendImageMessage({required String chatId, required File imageFile}) async {
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
}
