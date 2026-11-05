import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/format.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/incident.dart';
import '../models/status_event.dart';
import '../providers/incident_providers.dart';

class IncidentDetailScreen extends ConsumerWidget {
  const IncidentDetailScreen({super.key, required this.incidentId});
  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incident = ref.watch(incidentProvider(incidentId));
    final isStaff = ref.watch(isStaffProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Report details')),
      body: AsyncValueView<Incident?>(
        value: incident,
        data: (i) {
          if (i == null) {
            return const EmptyView(message: 'This report no longer exists.');
          }
          return _Body(incident: i);
        },
      ),
      floatingActionButton: isStaff && incident.value != null
          ? FloatingActionButton.extended(
              onPressed: () => _openStatusSheet(context, incident.value!),
              icon: const Icon(Icons.edit),
              label: const Text('Update status'),
            )
          : null,
    );
  }

  void _openStatusSheet(BuildContext context, Incident incident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _StatusSheet(incident: incident),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.incident});
  final Incident incident;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(statusHistoryProvider(incident.id));
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        if (incident.imageUrl != null)
          Image.network(
            incident.imageUrl!,
            height: 240,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (c, child, p) => p == null
                ? child
                : const SizedBox(height: 240, child: LoadingView()),
            errorBuilder: (_, __, ___) => const SizedBox(
                height: 120,
                child: EmptyView(
                    icon: Icons.broken_image, message: 'Photo unavailable')),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(incident.title,
                        style: theme.textTheme.headlineSmall),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: incident.status),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [
                Chip(
                  avatar: Icon(incident.category.icon, size: 18),
                  label: Text(incident.category.label),
                ),
                Chip(
                  avatar: const Icon(Icons.place_outlined, size: 18),
                  label: Text(incident.location),
                ),
              ]),
              const SizedBox(height: 12),
              Text(incident.description, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 12),
              Text(
                  'Reported by ${incident.reporterName} on ${formatDate(incident.createdAt)}',
                  style: theme.textTheme.bodySmall),
              const Divider(height: 32),
              Text('Status timeline', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _Timeline(incident: incident, history: history),
            ],
          ),
        ),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.incident, required this.history});
  final Incident incident;
  final AsyncValue<List<StatusEvent>> history;

  @override
  Widget build(BuildContext context) {
    final events = history.value ?? const <StatusEvent>[];
    final entries = <_Entry>[
      _Entry(IncidentStatus.submitted, 'Report submitted',
          'by ${incident.reporterName}', incident.createdAt),
      for (final e in events)
        _Entry(
          e.newStatus,
          'Marked "${e.newStatus.label}"',
          e.note.isEmpty
              ? 'by ${e.changedByName}'
              : '${e.note}\n— ${e.changedByName}',
          e.timestamp,
        ),
    ];

    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          _TimelineTile(entry: entries[i], isLast: i == entries.length - 1),
        if (history.hasError)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Could not load the full history.'),
          ),
      ],
    );
  }
}

class _Entry {
  const _Entry(this.status, this.title, this.subtitle, this.time);
  final IncidentStatus status;
  final String title;
  final String subtitle;
  final DateTime time;
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.entry, required this.isLast});
  final _Entry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                      color: entry.status.color, shape: BoxShape.circle),
                ),
                if (!isLast)
                  Expanded(
                      child: Container(
                          width: 2, color: Theme.of(context).dividerColor)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(entry.subtitle),
                  Text(formatDate(entry.time),
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Only reachable for staff (button is hidden otherwise, the controller
/// re-checks the role, and Firestore rules reject non-staff writes).
class _StatusSheet extends ConsumerStatefulWidget {
  const _StatusSheet({required this.incident});
  final Incident incident;

  @override
  ConsumerState<_StatusSheet> createState() => _StatusSheetState();
}

class _StatusSheetState extends ConsumerState<_StatusSheet> {
  late IncidentStatus _selected = widget.incident.status;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ok = await ref.read(statusControllerProvider.notifier).updateStatus(
          incident: widget.incident,
          newStatus: _selected,
          note: _note.text,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Status updated')));
    } else {
      final err = ref.read(statusControllerProvider).error;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Update failed: $err')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(statusControllerProvider).isLoading;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Update status', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<IncidentStatus>(
            initialValue: _selected,
            decoration: const InputDecoration(labelText: 'New status'),
            items: [
              for (final s in IncidentStatus.values)
                DropdownMenuItem(value: s, child: Text(s.label)),
            ],
            onChanged: (s) => setState(() => _selected = s ?? _selected),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note for the student (optional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: saving ? null : _save,
            child: saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
