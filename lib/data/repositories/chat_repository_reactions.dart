part of 'chat_repository_impl.dart';

extension ChatRepositoryReactions on ChatRepository {
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
}
