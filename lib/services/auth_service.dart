import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserModel?> getUserModel(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(name);
    final user = UserModel(id: cred.user!.uid, email: email, name: name);
    await _db.collection('users').doc(cred.user!.uid).set(user.toFirestore());
    return user;
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return getUserModel(cred.user!.uid);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  /// Update display name in both Firebase Auth and Firestore
  Future<void> updateProfile({
    required String uid,
    required String name,
    String? photoUrl,
    String? businessName,
    String? businessAddress,
    String? businessPhone,
    String? description,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(name);
      // Only update Auth photoURL if it's a real web URL (Base64 is too long for Auth profile)
      if (photoUrl != null && photoUrl.startsWith('http')) {
        await user.updatePhotoURL(photoUrl);
      }
    }
    final data = <String, dynamic>{
      'name': name,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (businessName != null) 'businessName': businessName,
      if (businessAddress != null) 'businessAddress': businessAddress,
      if (businessPhone != null) 'businessPhone': businessPhone,
      if (description != null) 'description': description,
    };
    await _db.collection('users').doc(uid).update(data);
  }
}
