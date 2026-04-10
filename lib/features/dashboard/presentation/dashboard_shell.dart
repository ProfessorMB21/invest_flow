import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:investflow/features/auth/logic/auth_service.dart';
import 'package:investflow/features/dashboard/presentation/dashboard_screen.dart';
import 'package:investflow/features/dashboard/presentation/widgets/theme_toggle.dart';
import 'package:investflow/features/projects/presentation/projects_screen.dart';

class DashboardShell extends ConsumerStatefulWidget {
  const DashboardShell({super.key});
  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _logout() async {
    await AuthService().signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    // Determine if Desktop (width > 600)
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: isDesktop
      ? null
      : AppBar(
        title: const Text("InvestFlow"),
        actions: [
          // Theme toggle
          const ThemeToggle(),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout))
        ],
      ),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              labelType: NavigationRailLabelType.all,
              trailing: IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
              leading: ThemeToggle(),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
                NavigationRailDestination(icon: Icon(Icons.folder), label: Text('Projects')),
                NavigationRailDestination(icon: Icon(Icons.chat), label: Text('Messages')),
                // NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
              ],
            ),
          Expanded(child: _getPage(_selectedIndex))
        ],
      ),
      bottomNavigationBar: isDesktop
      ? null
      : NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.folder), label: 'Projects'),
          NavigationDestination(icon: Icon(Icons.chat), label: 'Messages'),
        ],
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const ProjectsScreen();
      case 2:
        return const Center(child: Text("FlowMessenger"));
      default:
        return const Center(child: Text("Settings"));
    }
  }
}
