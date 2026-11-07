import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../models/incident.dart';
import '../providers/incident_providers.dart';

class MyReportsTab extends ConsumerStatefulWidget {
  const MyReportsTab({super.key});
  @override
  ConsumerState<MyReportsTab> createState() => _MyReportsTabState();
}

class _MyReportsTabState extends ConsumerState<MyReportsTab> {
  String _query = '';
  IncidentCategory? _category;
  IncidentStatus? _status;
  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(myIncidentsProvider);
    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            onChanged: (value) => setState(() => _query = value.toLowerCase()),
            decoration: const InputDecoration(
                hintText: 'Search my reports',
                prefixIcon: Icon(Icons.search_rounded)),
          )),
      SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(children: [
            for (final category in IncidentCategory.values)
              Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    avatar: Icon(category.icon, size: 16),
                    label: Text(category.label.split(' ').first),
                    selected: _category == category,
                    onSelected: (value) =>
                        setState(() => _category = value ? category : null),
                  )),
            for (final status in IncidentStatus.values)
              Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(status.label),
                    selected: _status == status,
                    onSelected: (value) =>
                        setState(() => _status = value ? status : null),
                  )),
            if (_query.isNotEmpty || _category != null || _status != null)
              TextButton(
                  onPressed: () => setState(() {
                        _query = '';
                        _category = null;
                        _status = null;
                      }),
                  child: const Text('Clear filters')),
          ])),
      Expanded(
          child: AsyncValueView<List<Incident>>(
        value: reports,
        onRetry: () => ref.invalidate(incidentsStreamProvider),
        data: (items) {
          final list = items
              .where((incident) =>
                  (_category == null || incident.category == _category) &&
                  (_status == null || incident.status == _status) &&
                  (_query.isEmpty ||
                      '${incident.title} ${incident.description} ${incident.location}'
                          .toLowerCase()
                          .contains(_query)))
              .toList();
          if (list.isEmpty) {
            return EmptyView(
                icon: _query.isEmpty && _category == null && _status == null
                    ? Icons.assignment_outlined
                    : Icons.search_off_rounded,
                message: _query.isEmpty && _category == null && _status == null
                    ? "You haven't submitted any reports yet."
                    : 'No reports match your filters.');
          }
          return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Text('${list.length} reports',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.muted)),
                const SizedBox(height: 10),
                for (final incident in list)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: IncidentCard(incident: incident)),
              ]);
        },
      )),
    ]);
  }
}
