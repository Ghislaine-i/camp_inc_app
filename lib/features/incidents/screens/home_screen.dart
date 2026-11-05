import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../auth/screens/profile_tab.dart';
import '../../staff/staff_dashboard_tab.dart';
import 'all_reports_tab.dart';
import 'my_reports_tab.dart';
import 'submit_incident_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isStaff = ref.watch(isStaffProvider);

    final tabs = <_Tab>[
      const _Tab('Reports', Icons.list_alt, AllReportsTab(), true),
      const _Tab('My reports', Icons.person_search, MyReportsTab(), true),
      if (isStaff) const _Tab('Dashboard', Icons.dashboard, StaffDashboardTab(), false),
      const _Tab('Profile', Icons.account_circle, ProfileTab(), false),
    ];
    final index = _index.clamp(0, tabs.length - 1);
    final current = tabs[index];

    return Scaffold(
      appBar: AppBar(title: Text(current.label)),
      body: IndexedStack(
        index: index,
        children: [for (final t in tabs) t.page],
      ),
      floatingActionButton: current.showFab
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SubmitIncidentScreen())),
              icon: const Icon(Icons.add),
              label: const Text('Report issue'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final t in tabs)
            NavigationDestination(icon: Icon(t.icon), label: t.label),
        ],
      ),
    );
  }
}

class _Tab {
  const _Tab(this.label, this.icon, this.page, this.showFab);
  final String label;
  final IconData icon;
  final Widget page;
  final bool showFab;
}
