import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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

  /// Every self-registered account is a 'student'. Staff accounts are promoted
  /// manually in the Firebase console (and Firestore rules block self-promotion).
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    // Reject non-ALU emails BEFORE creating the account.
    if (!Validators.isAluEmail(email)) {
      throw FirebaseAuthException(
        code: 'invalid-email-domain',
        message:
            'Use your ALU email (@alustudent.com or @alueducation.com).',
      );
    }

    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    final user = cred.user!;

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
  ///
  /// In debug builds, prints the relevant token claims to the console so
  /// you can confirm the token has been updated.
  /// TODO: remove the debugPrint block before submission.
  Future<void> refreshUser() async {
    final u = _auth.currentUser;
    if (u == null) return;
    await u.reload();
    final result = await _auth.currentUser?.getIdTokenResult(true);
    if (kDebugMode && result != null) {
      debugPrint('[TokenDebug] email          : ${result.claims?['email']}');
      debugPrint('[TokenDebug] email_verified : ${result.claims?['email_verified']}');
    }
  }

  Stream<AppUser?> watchUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      final data = snap.data();
      return data == null ? null : AppUser.fromMap(snap.id, data);
    });
  }
}
