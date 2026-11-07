import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/format.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/incident.dart';
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        if (incident.imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
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
          )
        else
          Container(
              height: 180,
              decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(incident.category.icon,
                  size: 64, color: theme.colorScheme.primary)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
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
              const SizedBox(height: 16),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        _InfoRow(
                            icon: incident.category.icon,
                            label: 'Category',
                            value: incident.category.label),
                        _InfoRow(
                            icon: Icons.place_rounded,
                            label: 'Location',
                            value: incident.location),
                        _InfoRow(
                            icon: Icons.schedule_rounded,
                            label: 'Submitted',
                            value: formatDate(incident.createdAt)),
                        _InfoRow(
                            icon: Icons.person_rounded,
                            label: 'Reported by',
                            value: incident.reporterName),
                      ]))),
              const SizedBox(height: 12),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Description',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Text(incident.description,
                                style: theme.textTheme.bodyLarge),
                          ]))),
              const SizedBox(height: 12),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Progress',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 16),
                            StatusStepper(
                                incident: incident,
                                history: history.value ?? const []),
                            if (history.hasError)
                              const Text('Could not load the full history.'),
                          ]))),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text('$label  ', style: Theme.of(context).textTheme.bodySmall),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ]),
      );
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
