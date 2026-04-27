part of 'chat_repository_impl.dart';

extension ChatRepositoryQueries on ChatRepository {
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
}
