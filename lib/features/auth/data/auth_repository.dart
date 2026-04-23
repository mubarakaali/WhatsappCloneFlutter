import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(
      auth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
      storage: FirebaseStorage.instance,
    ));

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  AuthRepository({required this.auth, required this.firestore, required this.storage});

  Stream<User?> authStateChanges() => auth.authStateChanges();

  Future<void> signUp({required String email, required String password}) async {
    final credential = await auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = credential.user;
    if (user == null) return;

    final appUser = AppUser(id: user.uid, email: email, displayName: email.split('@').first, photoUrl: null);
    await firestore.collection(AppConstants.usersCollection).doc(user.uid).set({
      'email': appUser.email,
      'displayName': appUser.displayName,
      'photoUrl': appUser.photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signIn({required String email, required String password}) => auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => auth.signOut();

  Stream<AppUser> watchCurrentUserProfile() {
    final uid = auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return firestore.collection(AppConstants.usersCollection).doc(uid).snapshots().map((doc) => AppUser.fromMap(doc.id, doc.data() ?? <String, dynamic>{}));
  }

  Future<void> updateProfile({required String displayName, File? imageFile}) async {
    final user = auth.currentUser;
    if (user == null) return;

    String? photoUrl;
    if (imageFile != null) {
      final ref = storage.ref('profiles/.jpg');
      await ref.putFile(imageFile);
      photoUrl = await ref.getDownloadURL();
    }

    await firestore.collection(AppConstants.usersCollection).doc(user.uid).set({
      'displayName': displayName,
      'photoUrl': photoUrl ?? FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
