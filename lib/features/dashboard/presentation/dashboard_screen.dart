import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:investflow/core/models/investment.dart';
import 'package:investflow/core/models/project.dart';
import 'package:investflow/features/auth/logic/auth_service.dart';
//import 'package:investflow/features/auth/logic/auth_service.dart';
import 'package:investflow/features/dashboard/logic/dashboard_notifier.dart';
import 'package:investflow/features/dashboard/presentation/widgets/project_card.dart';
import 'package:investflow/features/dashboard/presentation/widgets/stats_summary.dart';
import 'package:investflow/features/dashboard/presentation/widgets/user_profile_card.dart';
import 'package:riverpod/src/framework.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardNotifierProvider);
    final authService = AuthService();
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return RefreshIndicator(
      onRefresh: () async => ref.read(dashboardNotifierProvider.notifier).refresh(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back${dashboardState.userProfile?.fullName != null ? ", ${dashboardState.userProfile!.fullName.split(' ').first}" : ""}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Here\'s what\'s happening with your investments',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // User Profile Card
            UserProfileCard(
              userProfile: dashboardState.userProfile,
              onEdit: () => _showEditProfileDialog(context, ref),
            ),
            const SizedBox(height: 24),

            // Stats Summary
            StatsSummary(
              totalProjects: dashboardState.ownedProjects.length,
              activeProjects: dashboardState.activeProjectsCount,
              totalRaised: dashboardState.totalRaised,
              totalInvested: dashboardState.totalInvested,
              totalInvestments: dashboardState.investments.length,
            ),
            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(context, ref),
            const SizedBox(height: 24),

            // Section: My Projects
            _buildSectionHeader(
                context,
                'My Projects',
              '${dashboardState.ownedProjects.length} project${dashboardState.ownedProjects.length != 1 ? 's' : ''}',
                () => context.push('/projects')
            ),
            const SizedBox(height: 12),
            dashboardState.ownedProjects.isEmpty
              ? _buildEmptyState(
              'You haven\'t created any projects yet',
              Icons.folder_outlined,
              () => context.push('/projects/create'),
              'Create project',
              )
              : _buildProjectsGrid(dashboardState.ownedProjects.take(3).toList()),
            const SizedBox(height: 24),

            // Section: My Investments
           dashboardState.investedProjects.isEmpty
            ? _buildEmptyState(
             'You haven\'t invested in any projects yet',
             Icons.account_balance_outlined,
               () => context.push('/projects'),
             'Browse projects',
            )
           : _buildProjectsGrid(dashboardState.investedProjects.take(3).toList()),
            const SizedBox(height: 24),

            // Recent Activity Section
            if (dashboardState.investments.isNotEmpty) ...[
              _buildSectionHeader(
                context,
                'Recent Activity',
                '${dashboardState.investments.length} transaction${dashboardState.investments.length != 1 ? 's' : ''}',
                null,
              ),
              const SizedBox(height: 12),
              _buildRecentActivity(dashboardState.investments.take(5).toList(), currencyFormat)
            ]

          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String subtitle, VoidCallback? onTap) {
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
        if (onTap != null)
          TextButton(
            onPressed: onTap,
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
              onTap: () => context.push('/projects/create'),
            ),
            _buildQuickAction(
              icon: Icons.search_outlined,
              label: 'Browse',
              color: Colors.green,
              onTap: () => context.push('/projects'),
            ),
            _buildQuickAction(
              icon: Icons.chat_outlined,
              label: 'Messages',
              color: Colors.purple,
              onTap: () => _showComingSoon(context, 'Messages'),
            ),
            _buildQuickAction(
              icon: Icons.bar_chart_outlined,
              label: 'Reports',
              color: Colors.orange,
              onTap: () => _showComingSoon(context, 'Reports'),
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

  Widget _buildProjectsGrid(List<Project> projects) {
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
              onTap: () => context.push('/projects/${project.id}'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
      String message,
      IconData icon,
      VoidCallback onTap,
      String buttonText
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add),
              label: Text(buttonText),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(List<dynamic> investments, NumberFormat currencyFormat) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: investments.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final Investment investment = investments[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.withValues(alpha: 0.1),
              child: const Icon(Icons.trending_up, color: Colors.green, size: 20),
            ),
            title: Text('Investments in project'),
            subtitle: Text(DateFormat.yMMMd().add_jm().format(investment.createdAt)),
            trailing: Text(
              currencyFormat.format(investment.amount),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
          );
        },
      ),
    );
  }

  // ==================== DIALOGS & NAVIGATION ====================

  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    // Implement profile editing
    final nameCtrl = TextEditingController(
      text: ref.read(dashboardNotifierProvider).userProfile?.fullName ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Full name',
            border: OutlineInputBorder()
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await ref.read(dashboardNotifierProvider.notifier).updateProfile({
                  'fullName': nameCtrl.text.trim()
                });
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully'))
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update profile: $e'))
                  );
                }
              }
            },
            child: const Text('Save'),
          )
        ],
      )
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon!')),
    );
  }
}
