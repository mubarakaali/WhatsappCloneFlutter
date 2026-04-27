part of 'chat_repository_impl.dart';

extension ChatRepositoryStatus on ChatRepository {
  Stream<List<StatusItem>> watchStatuses() => firestore
      .collectionGroup(AppConstants.statusItemsSubCollection)
      .where('expiresAt', isGreaterThan: Timestamp.now())
      .orderBy('expiresAt')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => StatusItem.fromMap(doc.id, doc.data())).toList());

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
}
