import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/widgets/state_views.dart';
import '../auth/providers/auth_providers.dart';
import '../incidents/models/incident.dart';
import '../incidents/providers/incident_providers.dart';
import '../incidents/widgets/incident_card.dart';

/// Staff-only dashboard. The widget checks the role itself as a second guard
/// (in addition to the tab being hidden for students).
class StaffDashboardTab extends ConsumerWidget {
  const StaffDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isStaffProvider)) {
      return const EmptyView(
          icon: Icons.lock_outline, message: 'Staff access only.');
    }
    final incidents = ref.watch(incidentsStreamProvider);

    return AsyncValueView<List<Incident>>(
      value: incidents,
      onRetry: () => ref.invalidate(incidentsStreamProvider),
      data: (list) {
        final counts = {
          for (final s in IncidentStatus.values)
            s: list.where((i) => i.status == s).length,
        };
        // Oldest unresolved reports first = what needs attention most.
        final attention = list
            .where((i) => i.status == IncidentStatus.submitted)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  for (final s in IncidentStatus.values)
                    _StatCard(status: s, count: counts[s] ?? 0),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text('Awaiting review (${attention.length})',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            if (attention.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: EmptyView(
                    icon: Icons.check_circle_outline,
                    message: 'Nothing waiting. Nice work!'),
              )
            else
              for (final i in attention) IncidentCard(incident: i),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.status, required this.count});
  final IncidentStatus status;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(height: 4, color: status.color),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$count',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: status.color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text(status.label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    );
  }
}
