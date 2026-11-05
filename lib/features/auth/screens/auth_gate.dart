import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/state_views.dart';
import '../../incidents/screens/home_screen.dart';
import '../providers/auth_providers.dart';
import 'login_screen.dart';

/// Chooses the screen based on auth state, so no manual navigation is needed
/// after login/logout.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (e, _) => Scaffold(body: ErrorView(message: e.toString())),
      data: (user) {
        if (user == null) return const LoginScreen();
        final profile = ref.watch(currentUserProvider);
        return profile.when(
          loading: () => const Scaffold(body: LoadingView()),
          error: (e, _) => Scaffold(body: ErrorView(message: e.toString())),
          data: (appUser) {
            if (appUser == null) return const _ProfileMissing();
            return const HomeScreen();
          },
        );
      },
    );
  }
}

class _ProfileMissing extends ConsumerWidget {
  const _ProfileMissing();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Setting up your profile...'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
