import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/state_views.dart';
import '../providers/incident_providers.dart';
import '../widgets/incident_card.dart';

class MyReportsTab extends ConsumerWidget {
  const MyReportsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = ref.watch(myIncidentsProvider);
    return AsyncValueView(
      value: mine,
      onRetry: () => ref.invalidate(incidentsStreamProvider),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyView(
            icon: Icons.assignment_outlined,
            message: "You haven't submitted any reports yet.",
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(incidentsStreamProvider);
            await ref.read(incidentsStreamProvider.future);
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 88, top: 8),
            itemCount: list.length,
            itemBuilder: (_, i) => IncidentCard(incident: list[i]),
          ),
        );
      },
    );
  }
}
