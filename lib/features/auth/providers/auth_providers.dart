import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/providers.dart';
import '../data/auth_repository.dart';
import '../models/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
      ref.watch(firebaseAuthProvider), ref.watch(firestoreProvider));
});

/// Firebase Auth session (null = signed out).
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Refreshes the signed-in user's token before Firestore listeners start.
final tokenReadyProvider = FutureProvider<void>((ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null || !user.emailVerified) return;
  await user.getIdTokenResult(true);
});

/// Firestore profile of the signed-in user (includes the role).
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final auth = ref.watch(authStateProvider).value;
  if (auth == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).watchUser(auth.uid);
});

/// Drives role-based UI. (Firestore rules are the real enforcement.)
final isStaffProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider).value?.role == UserRole.staff;
});

String authErrorMessage(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
  return e.toString();
}

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(authRepositoryProvider).signIn(email, password));
    return !state.hasError;
  }

  Future<bool> register(String name, String email, String password) async {
    state = const AsyncLoading();
    state =
        await AsyncValue.guard(() => ref.read(authRepositoryProvider).register(
              name: name,
              email: email,
              password: password,
            ));
    return !state.hasError;
  }

  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();

  Future<void> resendVerification() =>
      ref.read(authRepositoryProvider).resendVerification();

  /// Reloads the Firebase user so `emailVerified` is up to date.
  Future<void> refreshUser() => ref.read(authRepositoryProvider).refreshUser();
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
