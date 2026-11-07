import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../providers/auth_providers.dart';
import '../../incidents/providers/incident_providers.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key, this.onOpenDashboard});
  final VoidCallback? onOpenDashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const LoadingView();
    final isStaff = ref.watch(isStaffProvider);
    final reports = isStaff
        ? ref.watch(incidentsStreamProvider).value ?? const []
        : ref.watch(myIncidentsProvider).value ?? const [];
    final active = isStaff
        ? reports
            .where((i) =>
                i.status == IncidentStatus.submitted ||
                i.status == IncidentStatus.underReview)
            .length
        : reports.where((i) => i.status != IncidentStatus.resolved).length;
    final inProgress =
        reports.where((i) => i.status == IncidentStatus.inProgress).length;
    final resolved =
        reports.where((i) => i.status == IncidentStatus.resolved).length;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(
          color: AppColors.primaryContainer,
          child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                AppAvatar(name: user.name, radius: 30),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(user.name,
                          style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 9),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(user.isStaff ? 'Staff' : 'Student',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700))),
                    ])),
              ]))),
      const SizedBox(height: 20),
      Text(isStaff ? 'Campus overview' : 'Your activity',
          style: const TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      if (isStaff)
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.8,
          children: [
            _Stat(label: 'Total reports', value: reports.length),
            _Stat(label: 'Awaiting review', value: active),
            _Stat(label: 'In progress', value: inProgress),
            _Stat(label: 'Resolved', value: resolved),
          ],
        )
      else
        Row(children: [
          Expanded(child: _Stat(label: 'Total', value: reports.length)),
          Expanded(child: _Stat(label: 'Active', value: active)),
          Expanded(child: _Stat(label: 'Resolved', value: resolved)),
        ]),
      if (isStaff) ...[
        const SizedBox(height: 20),
        const Text('Staff tools',
            style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onOpenDashboard,
          icon: const Icon(Icons.dashboard_rounded),
          label: const Text('Open dashboard'),
        ),
      ],
      const SizedBox(height: 28),
      const Text('Account',
          style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                    title: const Text('Sign out?'),
                    content: const Text('You can sign back in anytime.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Sign out')),
                    ],
                  ));
          if (confirmed == true) {
            await ref.read(authControllerProvider.notifier).signOut();
          }
        },
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Sign out'),
      ),
    ]);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(children: [
            Text('$value',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ])));
}
