import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../providers/incident_providers.dart';
import '../models/incident_filter.dart';

class AllReportsTab extends ConsumerWidget {
  const AllReportsTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterProvider);
    final notifier = ref.read(filterProvider.notifier);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: TextField(
          onChanged: notifier.setQuery,
          decoration: InputDecoration(
            hintText: 'Search reports',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: filter.isActive
                ? IconButton(
                    onPressed: notifier.clear,
                    icon: const Icon(Icons.close_rounded))
                : null,
          ),
        ),
      ),
      _Filters(
          filter: filter,
          onCategory: notifier.setCategory,
          onStatus: notifier.setStatus,
          onClear: notifier.clear),
      Expanded(
          child: AsyncValueView(
        value: ref.watch(filteredIncidentsProvider),
        onRetry: () => ref.invalidate(incidentsStreamProvider),
        data: (list) => list.isEmpty
            ? EmptyView(
                icon: filter.isActive
                    ? Icons.search_off_rounded
                    : Icons.inbox_rounded,
                message: filter.isActive
                    ? 'No reports match your filters.'
                    : 'No reports yet.')
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(incidentsStreamProvider);
                  await ref.read(incidentsStreamProvider.future);
                },
                child: ListView(
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
                  ],
                ),
              ),
      )),
    ]);
  }
}

class _Filters extends StatelessWidget {
  const _Filters(
      {required this.filter,
      required this.onCategory,
      required this.onStatus,
      required this.onClear});
  final IncidentFilter filter;
  final void Function(IncidentCategory?) onCategory;
  final void Function(IncidentStatus?) onStatus;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(children: [
          for (final category in IncidentCategory.values)
            Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  avatar: Icon(category.icon, size: 16),
                  label: Text(category.label.split(' ').first),
                  selected: filter.category == category,
                  onSelected: (value) => onCategory(value ? category : null),
                )),
          for (final status in IncidentStatus.values)
            Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(status.label),
                  selected: filter.status == status,
                  onSelected: (value) => onStatus(value ? status : null),
                )),
          if (filter.isActive)
            TextButton(onPressed: onClear, child: const Text('Clear filters')),
        ]),
      );
}
