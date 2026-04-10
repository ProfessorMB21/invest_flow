// Flutter Imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investflow/core/utils/app_colors.dart';
import 'package:investflow/features/auth/logic/auth_service.dart';
import 'package:investflow/features/dashboard/logic/dashboard_notifier.dart';

class UpdatesSection extends ConsumerWidget {
  const UpdatesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardNotifierProvider);
    final authService = AuthService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Welcome!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (authService.isAuthenticated)
              TextButton.icon(
                onPressed: () {
                  // TODO: Implement help dialog
                },
                icon: const Icon(Icons.help_outline),
                label: const Text('Help'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        dashboardAsync.when(
          data: (state) {
            if (authService.isAuthenticated) {
              return Text(
                'Your dashboard is ready. You can create projects, invest in others, and track your portfolio.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              );
            } else if (state.userProfile?.email.isNotEmpty == true) {
              return const Text(
                'Welcome back! Check your recent activity and investments.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              );
            }
            return const SizedBox.shrink();
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Recent Updates',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (authService.isAuthenticated)
          const UpdatesList()
        else
          const SizedBox.shrink(),
      ],
    );
  }
}

class UpdatesList extends StatelessWidget {
  const UpdatesList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final projects = snapshot.data!.docs;
        if (projects.isEmpty) {
          return const SizedBox.shrink();
        }

        final updates = <_UpdateData>[];

        // Add project updates
        for (final project in projects) {
          final data = project.data() as Map<String, dynamic>;
          updates.add(_UpdateData(
            icon: Icons.cases_outlined,
            title: 'New Project',
            subtitle: data['title'] ?? 'New investment opportunity',
            action: 'View',
          ));
        }

        // Add recent investments
        final investmentStream = FirebaseFirestore.instance
            .collection('investments')
            .orderBy('createdAt', descending: true)
            .limit(5)
            .snapshots();

        return StreamBuilder<QuerySnapshot>(
          stream: investmentStream,
          builder: (context, investmentSnapshot) {
            if (!investmentSnapshot.hasData) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (updates.isEmpty)
                    _UpdateItem(
                      icon: Icons.cloud_off,
                      title: 'No Activity',
                      subtitle: 'No recent updates',
                      action: '',
                    ),
                ],
              );
            }

            final investments = investmentSnapshot.data!.docs;
            if (investments.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (updates.isEmpty)
                    _UpdateItem(
                      icon: Icons.cloud_off,
                      title: 'No Activity',
                      subtitle: 'No recent updates',
                      action: '',
                    ),
                ],
              );
            }

            final allUpdates = <_UpdateData>[
              ...updates,
              ...investments.map((inv) {
                final invData = inv.data() as Map<String, dynamic>;
                return _UpdateData(
                  icon: Icons.attach_money,
                  title: 'Investment',
                  subtitle: invData['amount'] != null
                      ? '\$${(invData['amount'] as num).toStringAsFixed(2)}'
                      : 'Investment made',
                  action: 'View',
                );
              }),
            ];

            if (allUpdates.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _UpdateItem(
                    icon: Icons.cloud_off,
                    title: 'No Activity',
                    subtitle: 'No recent updates',
                    action: '',
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: allUpdates
                  .take(3)
                  .map((u) => _UpdateItem(
                        icon: u.icon,
                        title: u.title,
                        subtitle: u.subtitle,
                        action: u.action,
                      ))
                  .toList(),
            );
          },
        );
      },
    );
  }
}

class _UpdateData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String action;

  _UpdateData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
  });
}

class _UpdateItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String action;

  const _UpdateItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (action.isNotEmpty)
            Text(
              action,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
