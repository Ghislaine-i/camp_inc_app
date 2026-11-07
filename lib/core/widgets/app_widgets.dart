import 'package:flutter/material.dart';

import '../constants.dart';
import '../format.dart';
import '../theme.dart';
import '../../features/incidents/models/incident.dart';
import '../../features/incidents/models/status_event.dart';
import '../../features/incidents/screens/incident_detail_screen.dart';
import 'status_badge.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.name, this.radius = 22});
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.primary,
        child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
            style:
                TextStyle(fontWeight: FontWeight.w700, fontSize: radius * .8)),
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      );
}

class StatusProgressBar extends StatelessWidget {
  const StatusProgressBar({
    super.key,
    required this.incidents,
    this.emptyMessage = 'Your reports will appear here as you submit them.',
  });
  final List<Incident> incidents;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final counts = {
      for (final s in IncidentStatus.values)
        s: incidents.where((i) => i.status == s).length
    };
    final total = incidents.length;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 10,
            child: Row(children: [
              for (final s in IncidentStatus.values)
                Expanded(
                  flex: counts[s]! == 0 ? 1 : counts[s]!,
                  child: Container(color: s.color),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final s in IncidentStatus.values)
              Text('${s.label} ${counts[s]}',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.muted)),
          ],
        ),
        if (total == 0)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(emptyMessage,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.muted)),
          ),
      ],
    );
  }
}

class StatusStepper extends StatelessWidget {
  const StatusStepper(
      {super.key, required this.incident, required this.history});
  final Incident incident;
  final List<StatusEvent> history;

  @override
  Widget build(BuildContext context) {
    final currentIndex = IncidentStatus.values.indexOf(incident.status);
    final dates = <IncidentStatus, DateTime>{
      IncidentStatus.submitted: incident.createdAt
    };
    for (final event in history) {
      dates[event.newStatus] = event.timestamp;
    }
    return Column(children: [
      for (var i = 0; i < IncidentStatus.values.length; i++)
        _Step(
          status: IncidentStatus.values[i],
          active: i <= currentIndex,
          date: dates[IncidentStatus.values[i]],
          last: i == IncidentStatus.values.length - 1,
        ),
    ]);
  }
}

class _Step extends StatelessWidget {
  const _Step(
      {required this.status,
      required this.active,
      required this.date,
      required this.last});
  final IncidentStatus status;
  final bool active;
  final DateTime? date;
  final bool last;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            width: 24,
            child: Column(children: [
              Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                      color: active ? status.color : AppColors.outline,
                      shape: BoxShape.circle)),
              if (!last)
                Expanded(
                    child: Container(
                        width: 2,
                        color: active
                            ? status.color.withValues(alpha: .35)
                            : AppColors.outline)),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(status.label,
                        style: TextStyle(
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w400,
                            color: active ? AppColors.text : AppColors.muted)),
                    if (date != null)
                      Text(formatDate(date!),
                          style: Theme.of(context).textTheme.labelSmall),
                  ]),
            ),
          ),
        ]),
      );
}

class IncidentCard extends StatelessWidget {
  const IncidentCard({super.key, required this.incident});
  final Incident incident;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => IncidentDetailScreen(incidentId: incident.id))),
          child: IntrinsicHeight(
            child: Row(children: [
              Container(width: 4, color: incident.status.color),
              Padding(
                  padding: const EdgeInsets.all(12),
                  child: _Thumbnail(incident: incident)),
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(incident.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700))),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.muted),
                      ]),
                      const SizedBox(height: 5),
                      Text('${incident.category.label} • ${incident.location}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.muted)),
                      const SizedBox(height: 9),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StatusBadge(status: incident.status),
                            Text(relativeDate(incident.createdAt),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: AppColors.muted)),
                          ]),
                    ]),
              )),
            ]),
          ),
        ),
      );
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.incident});
  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
        width: 62,
        height: 62,
        color: AppColors.primaryContainer,
        child: Icon(incident.category.icon, color: AppColors.primary));
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: incident.imageUrl == null
          ? fallback
          : Image.network(incident.imageUrl!,
              width: 62,
              height: 62,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : fallback,
              errorBuilder: (_, __, ___) => fallback),
    );
  }
}
