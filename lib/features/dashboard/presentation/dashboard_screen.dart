// Flutter Imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:investflow/core/models/project.dart';
import 'package:investflow/core/utils/app_colors.dart';
import 'package:investflow/features/auth/logic/auth_service.dart';
import 'package:investflow/features/dashboard/logic/dashboard_notifier.dart';
import 'package:investflow/features/dashboard/presentation/widgets/fund_balance_card.dart';
import 'package:investflow/features/dashboard/presentation/widgets/profile_section.dart';
import 'package:investflow/features/dashboard/presentation/widgets/project_card.dart';
import 'package:investflow/features/dashboard/presentation/widgets/stats_summary.dart';
import 'package:investflow/features/dashboard/presentation/widgets/updates_section.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();

    // Load user profile on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardNotifierProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'InvestFlow',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications coming soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: dashboardState.when(
            data: (state) => _buildContent(state),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error: $error'),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final userId = AuthService().currentUserId;
          if (userId != null) {
            _navigateToCreateProject();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
    );
  }

  Widget _buildContent(DashboardState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const UpdatesSection(),
          const SizedBox(height: 16),

          // Profile Section
          if (state.userProfile != null)
            ProfileSection(
              user: state.userProfile!,
              onEditProfile: _navigateToProfileEdit,
            )
          else
            const Center(
              child: CircularProgressIndicator(),
            ),

          const SizedBox(height: 24),

          // Fund Balance Card
          FundBalanceCard(
            balance: state.totalRaised,
            isLoading: state.isLoading,
          ),

          const SizedBox(height: 24),

          // Projects List
          if (state.myProjects.isNotEmpty || state.investedProjects.isNotEmpty) ...[
            Text(
              'Your Projects',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ..._buildProjectList([...state.myProjects, ...state.investedProjects]),
          ],

          const SizedBox(height: 24),

          // Stats Summary
          StatsSummary(
            totalProjects: state.myProjects.length,
            activeProjects: state.activeProjects.where((p) => p.status == ProjectStatus.active).length,
            totalRaised: state.totalRaised,
            totalInvested: ref.read(dashboardNotifierProvider.notifier).totalInvested,
            totalInvestments: state.investedProjects.length,
            investments: const [],
          ),

          const SizedBox(height: 24),

          // Empty State
          if (state.myProjects.isEmpty &&
              state.investedProjects.isEmpty &&
              state.userProfile != null) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 80,
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Get started by creating your first project or investing in others',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  List<Widget> _buildProjectList(List<Project> projects) {
    return projects.map((project) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ProjectCard(
        project: project,
        onTap: () => context.go('/projects/${project.id}'),
      ),
    )).toList();
  }

  void _navigateToProfileEdit() {
    context.push('/profile/edit');
  }

  void _navigateToCreateProject() {
    context.push('/projects/create');
  }

  @override
  void dispose() {
    // Clean up
    super.dispose();
  }
}
