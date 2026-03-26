import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investflow/core/models/project.dart';
import 'package:investflow/features/auth/logic/auth_service.dart';
import 'package:investflow/features/dashboard/logic/dashboard_notifier.dart';
import 'package:investflow/features/dashboard/presentation/widgets/project_card.dart';
import 'package:investflow/features/dashboard/presentation/widgets/stats_summary.dart';
import 'package:investflow/features/dashboard/presentation/widgets/user_profile_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardNotifierProvider);
    final authService = AuthService();
    final userId = authService.currentUserId;

    return RefreshIndicator(
      onRefresh: () async => ref.read(dashboardNotifierProvider.notifier).initialize(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Card
            UserProfileCard(
              userProfile: dashboardState.userProfile,
              onEdit: () => _showEditProfileDialog(context, ref),
            ),
            const SizedBox(height: 16),

            // Stats Summary
            StatsSummary(
              ownedProjects: dashboardState.ownedProjects,
              investedProjects: dashboardState.investedProjects,
            ),
            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(context, ref),
            const SizedBox(height: 24),

            // Section: My Projects
            _buildSectionHeader('My Projects', 'View and manage your projects'),
            const SizedBox(height: 12),
            _buildProjectsList(
              projects: dashboardState.ownedProjects,
              emptyMessage: 'You haven\'t created any projects yet',
              onTap: (project) => _navigateToProjectDetail(context, project.id),
            ),
            const SizedBox(height: 24),

            // Section: My Investments
            _buildSectionHeader('My Investments', 'Projects you\'ve invested in'),
            const SizedBox(height: 12),
            _buildProjectsList(
              projects: dashboardState.investedProjects,
              emptyMessage: 'You haven\'t invested in any projects yet',
              onTap: (project) => _navigateToProjectDetail(context, project.id),
            ),
            const SizedBox(height: 24),

            // Section: Discover Projects
            _buildSectionHeader('Discover', 'Browse active investment opportunities'),
            const SizedBox(height: 12),
            _buildProjectsList(
              projects: dashboardState.activeProjects
                  .where((p) => !dashboardState.ownedProjects.any((op) => op.id == p.id) &&
                  !dashboardState.investedProjects.any((ip) => ip.id == p.id))
                  .take(5)
                  .toList(),
              emptyMessage: 'No active projects available',
              onTap: (project) => _navigateToProjectDetail(context, project.id),
              showInvestButton: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
        TextButton(
          onPressed: () {},
          child: const Text('View All'),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickAction(
              icon: Icons.add_circle_outline,
              label: 'New Project',
              color: Colors.blue,
              onTap: () => _showCreateProjectDialog(context, ref),
            ),
            _buildQuickAction(
              icon: Icons.search_outlined,
              label: 'Browse',
              color: Colors.green,
              onTap: () {},
            ),
            _buildQuickAction(
              icon: Icons.chat_outlined,
              label: 'Messages',
              color: Colors.purple,
              onTap: () => _navigateToMessages(context),
            ),
            _buildQuickAction(
              icon: Icons.bar_chart_outlined,
              label: 'Reports',
              color: Colors.orange,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsList({
    required List<Project> projects,
    required String emptyMessage,
    required void Function(Project) onTap,
    bool showInvestButton = false,
  }) {
    if (projects.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: projects.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final project = projects[index];
          return SizedBox(
            width: 280,
            child: ProjectCard(
              project: project,
              onTap: () => onTap(project),
            ),
          );
        },
      ),
    );
  }

  // ==================== DIALOGS & NAVIGATION ====================

  void _showCreateProjectDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final goalCtrl = TextEditingController();
    DateTime? selectedDeadline;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Project Title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: goalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Goal Amount (\$)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(selectedDeadline != null
                      ? 'Deadline: ${selectedDeadline!.toLocal()}'
                      : 'Select Deadline'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => selectedDeadline = date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty || goalCtrl.text.isEmpty || selectedDeadline == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                Navigator.pop(context);

                try {
                  await ref.read(dashboardNotifierProvider.notifier).createProject(
                    title: titleCtrl.text,
                    description: descCtrl.text,
                    goalAmount: double.tryParse(goalCtrl.text) ?? 0,
                    deadline: selectedDeadline!,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Project created successfully!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create project: $e')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    // Implement profile editing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile editing coming soon!')),
    );
  }

  void _navigateToProjectDetail(BuildContext context, String projectId) {
    // Navigate to project detail screen
    // context.push('/projects/$projectId');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening project: $projectId')),
    );
  }

  void _navigateToMessages(BuildContext context) {
    // Navigate to messages screen
    // context.push('/messages');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Messages coming soon!')),
    );
  }
}
