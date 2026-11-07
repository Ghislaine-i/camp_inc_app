import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/validators.dart';
import '../models/app_user.dart';

class AuthRepository {
  AuthRepository(this._auth, this._db);
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// Use userChanges() so emailVerified updates propagate after a reload.
  Stream<User?> authStateChanges() => _auth.userChanges();

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    // Reject non-ALU emails BEFORE creating the account.
    if (!Validators.isAluEmail(email)) {
      throw FirebaseAuthException(
        code: 'invalid-email-domain',
        message: 'Use your ALU email (@alustudent.com or @alueducation.com).',
      );
    }

    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    final user = cred.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-creation-failed',
        message: 'Account creation did not return a user.',
      );
    }

    await _db.collection('users').doc(user.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'role': 'student',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await user.sendEmailVerification();
    await user.updateDisplayName(name.trim());
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> resendVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Reloads the Firebase user and forces a token refresh so that
  /// email_verified is up-to-date in the cached claims.
  Future<void> refreshUser() async {
    final u = _auth.currentUser;
    if (u == null) return;
    await u.reload();
    await _auth.currentUser?.getIdTokenResult(true);
  }

  Stream<AppUser?> watchUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      final data = snap.data();
      return data == null ? null : AppUser.fromMap(snap.id, data);
    });
  }
}
