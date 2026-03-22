import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});
  @override
  State<StatefulWidget> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _logout() async {
    await Supabase.instance.client.auth.signOut();
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
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout,)],
      ),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              labelType: NavigationRailLabelType.all,
              trailing: IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
                NavigationRailDestination(icon: Icon(Icons.folder), label: Text('Projects')),
                NavigationRailDestination(icon: Icon(Icons.chat), label: Text('Messages')),
                NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
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
        return const Center(child: Text("Dashboard Overview"));
      case 1:
        return const Center(child: Text("Project List & Milestones"));
      case 2:
        return const Center(child: Text("FlowMessenger"));
      default:
        return const Center(child: Text("Settings"));
    }
  }
}
