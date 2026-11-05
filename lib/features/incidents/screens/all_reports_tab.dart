import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/widgets/state_views.dart';
import '../providers/incident_providers.dart';
import '../widgets/incident_card.dart';

class AllReportsTab extends ConsumerWidget {
  const AllReportsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterProvider);
    final notifier = ref.read(filterProvider.notifier);
    final incidents = ref.watch(filteredIncidentsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            onChanged: notifier.setQuery,
            decoration: InputDecoration(
              hintText: 'Search title, description or location',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              suffixIcon: filter.isActive
                  ? IconButton(
                      tooltip: 'Clear filters',
                      icon: const Icon(Icons.filter_alt_off),
                      onPressed: () {
                        notifier.clear();
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
            ),
          ),
        ),
        _ChipRow<IncidentCategory>(
          values: IncidentCategory.values,
          selected: filter.category,
          label: (c) => c.label,
          onSelected: notifier.setCategory,
        ),
        _ChipRow<IncidentStatus>(
          values: IncidentStatus.values,
          selected: filter.status,
          label: (s) => s.label,
          onSelected: notifier.setStatus,
        ),
        const Divider(height: 1),
        Expanded(
          child: AsyncValueView(
            value: incidents,
            onRetry: () => ref.invalidate(incidentsStreamProvider),
            data: (list) {
              if (list.isEmpty) {
                return EmptyView(
                  icon: filter.isActive ? Icons.search_off : Icons.inbox,
                  message: filter.isActive
                      ? 'No reports match your search or filters.'
                      : 'No reports yet. Tap "Report issue" to submit the first one.',
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(incidentsStreamProvider);
                  await ref.read(incidentsStreamProvider.future);
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 88, top: 4),
                  itemCount: list.length,
                  itemBuilder: (_, i) => IncidentCard(incident: list[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChipRow<T> extends StatelessWidget {
  const _ChipRow({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<T> values;
  final T? selected;
  final String Function(T) label;
  final void Function(T?) onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final v in values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label(v)),
                selected: selected == v,
                onSelected: (on) => onSelected(on ? v : null),
              ),
            ),
        ],
      ),
    );
  }
}
