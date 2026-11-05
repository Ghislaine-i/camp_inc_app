import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/incident.dart';
import '../screens/incident_detail_screen.dart';

class IncidentCard extends StatelessWidget {
  const IncidentCard({super.key, required this.incident});
  final Incident incident;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => IncidentDetailScreen(incidentId: incident.id))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(incident: incident),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(incident.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('${incident.category.label} • ${incident.location}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusBadge(status: incident.status),
                        Text(formatDate(incident.createdAt),
                            style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.incident});
  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 64,
      height: 64,
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Icon(incident.category.icon,
          color: Theme.of(context).colorScheme.onSecondaryContainer),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: incident.imageUrl == null
          ? fallback
          : Image.network(
              incident.imageUrl!,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }
}
