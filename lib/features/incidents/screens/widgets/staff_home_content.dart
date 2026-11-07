import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../models/incident.dart';
import '../../providers/incident_providers.dart';

class StaffHomeContent extends ConsumerWidget {
  const StaffHomeContent({super.key, required this.onSeeAll});
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueView<List<Incident>>(
      value: ref.watch(incidentsStreamProvider),
      onRetry: () => ref.invalidate(incidentsStreamProvider),
      data: (incidents) {
        final needsAttention = incidents
            .where((incident) =>
                incident.status == IncidentStatus.submitted ||
                incident.status == IncidentStatus.underReview)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Transform.translate(
                offset: const Offset(0, -24),
                child: _OverviewCard(incidents: incidents),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - 8) / 2;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final status in IncidentStatus.values)
                        _StatusTile(
                          status: status,
                          count: incidents
                              .where((incident) => incident.status == status)
                              .length,
                          width: width,
                          onTap: () {
                            ref.read(filterProvider.notifier).clear();
                            ref.read(filterProvider.notifier).setStatus(status);
                            onSeeAll();
                          },
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              SectionHeader(
                'Needs attention',
                action: 'See all',
                onAction: onSeeAll,
              ),
              Text(
                'Open a report to update its status.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              if (needsAttention.isEmpty)
                const EmptyView(
                  icon: Icons.check_circle_outline,
                  message: 'Nothing needs attention. Great job!',
                )
              else
                for (final incident in needsAttention.take(5))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: IncidentCard(incident: incident),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.incidents});
  final List<Incident> incidents;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('All reports',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              Text(
                '${incidents.length}',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              StatusProgressBar(
                incidents: incidents,
                emptyMessage: 'No reports have been submitted yet.',
              ),
            ],
          ),
        ),
      );
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.status,
    required this.count,
    required this.width,
    required this.onTap,
  });
  final IncidentStatus status;
  final int count;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(_iconFor(status), color: status.color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(status.label,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('$count',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                    color: status.color,
                                    fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  IconData _iconFor(IncidentStatus status) => switch (status) {
        IncidentStatus.submitted => Icons.inbox_outlined,
        IncidentStatus.underReview => Icons.visibility_outlined,
        IncidentStatus.inProgress => Icons.build_circle_outlined,
        IncidentStatus.resolved => Icons.check_circle_outline,
      };
}
