import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/screens/profile_tab.dart';
import '../../staff/staff_dashboard_tab.dart';
import '../models/incident.dart';
import '../providers/incident_providers.dart';
import 'all_reports_tab.dart';
import 'my_reports_tab.dart';
import 'submit_incident_screen.dart';
import 'widgets/staff_home_content.dart';

final homeIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    ref.listen(homeIndexProvider, (_, next) => setState(() => _index = next));
    final isStaff = ref.watch(isStaffProvider);
    final dashboardIndex = isStaff ? 2 : -1;
    final tabs = <_Tab>[
      const _Tab('Home', Icons.home_rounded, _HomeTab()),
      const _Tab('Reports', Icons.list_alt_rounded, AllReportsTab()),
      if (!isStaff)
        const _Tab('My reports', Icons.person_search_rounded, MyReportsTab()),
      if (isStaff)
        const _Tab('Dashboard', Icons.dashboard_rounded, StaffDashboardTab()),
      _Tab(
        'Profile',
        Icons.account_circle_rounded,
        isStaff
            ? ProfileTab(
                onOpenDashboard: () => setState(() => _index = dashboardIndex))
            : const ProfileTab(),
      ),
    ];
    final index = _index.clamp(0, tabs.length - 1);
    final current = tabs[index];
    return Scaffold(
      appBar: index == 0 ? null : AppBar(title: Text(current.label)),
      body: IndexedStack(
          index: index, children: [for (final tab in tabs) tab.page]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          for (final tab in tabs)
            NavigationDestination(icon: Icon(tab.icon), label: tab.label)
        ],
      ),
    );
  }
}

class _Tab {
  const _Tab(this.label, this.icon, this.page);
  final String label;
  final IconData icon;
  final Widget page;
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final isStaff = ref.watch(isStaffProvider);
    final name = user?.name.split(' ').first ?? 'there';
    if (isStaff) {
      return SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
                child: _Header(name: name, fullName: user?.name ?? '')),
            SliverToBoxAdapter(
              child: StaffHomeContent(
                onSeeAll: () => ref.read(homeIndexProvider.notifier).state = 1,
              ),
            ),
          ],
        ),
      );
    }

    final reports = ref.watch(myIncidentsProvider);
    return AsyncValueView<List<Incident>>(
      value: reports,
      data: (items) {
        final recent = [...items]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return CustomScrollView(slivers: [
          SliverToBoxAdapter(
              child: _Header(name: name, fullName: user?.name ?? '')),
          SliverToBoxAdapter(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Card(
                child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('My reports',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    Text('${items.length}',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    StatusProgressBar(incidents: items),
                  ]),
            )),
          )),
          if (!isStaff)
            SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                sliver: SliverToBoxAdapter(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader('Report an issue'),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.1,
                      children: [
                        for (final category in IncidentCategory.values)
                          _CategoryTile(category: category)
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SubmitIncidentScreen())),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Report a new issue'),
                    ),
                    const SizedBox(height: 18),
                    SectionHeader('Recent activity',
                        action: 'See all',
                        onAction: () =>
                            ref.read(homeIndexProvider.notifier).state = 1),
                  ],
                ))),
          if (recent.isEmpty)
            const SliverToBoxAdapter(
                child: EmptyView(
                    icon: Icons.assignment_outlined,
                    message:
                        'No reports yet. You are helping keep campus running smoothly.'))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.builder(
                itemCount: recent.length > 3 ? 3 : recent.length,
                itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: IncidentCard(incident: recent[i])),
              ),
            ),
        ]);
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.fullName});
  final String name;
  final String fullName;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 52, 20, 58),
        decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Hello, $name',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text("Let's keep our campus running smoothly.",
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: .82))),
              ])),
          AppAvatar(name: fullName, radius: 24),
        ]),
      );
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});
  final IncidentCategory category;
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SubmitIncidentScreen(initialCategory: category))),
        child: Ink(
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.outline)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(category.icon, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(category.label.split(' ').first,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}
