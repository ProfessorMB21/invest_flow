import 'package:flutter/material.dart';
import 'package:investflow/core/models/project.dart';

class StatsSummary extends StatelessWidget {
  final List<Project> ownedProjects;
  final List<Project> investedProjects;

  const StatsSummary({
    super.key,
    required this.ownedProjects,
    required this.investedProjects,
  });

  @override
  Widget build(BuildContext context) {
    final activeOwned = ownedProjects.where((p) => p.status == ProjectStatus.active).length;
    final totalRaised = ownedProjects.fold<double>(0, (sum, p) => sum + p.raisedAmount);
    final totalInvested = investedProjects.fold<double>(0, (sum, p) => sum + p.raisedAmount);

    return Row(
      children: [
        _buildStatCard(
          icon: Icons.folder_outlined,
          label: 'My Projects',
          value: ownedProjects.length.toString(),
          subtitle: '$activeOwned active',
          color: Colors.blue,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.trending_up_outlined,
          label: 'Total Raised',
          value: '\$${(totalRaised / 1000).toStringAsFixed(1)}K',
          subtitle: 'From your projects',
          color: Colors.green,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Invested',
          value: '\$${(totalInvested / 1000).toStringAsFixed(1)}K',
          subtitle: 'In ${investedProjects.length} projects',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
