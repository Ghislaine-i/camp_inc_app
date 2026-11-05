import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/state_views.dart';
import '../providers/auth_providers.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const LoadingView();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        CircleAvatar(
          radius: 40,
          child: Text(
            user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
            style: const TextStyle(fontSize: 32),
          ),
        ),
        const SizedBox(height: 16),
        Text(user.name,
            textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
        Text(user.email, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Center(
          child: Chip(
            avatar: Icon(user.isStaff ? Icons.verified_user : Icons.school, size: 18),
            label: Text(user.isStaff ? 'Campus staff' : 'Student'),
          ),
        ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: () async {
            await ref.read(authControllerProvider.notifier).signOut();
          },
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}
