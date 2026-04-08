import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:investflow/core/models/project.dart';

class StatsSummary extends StatelessWidget {
  final int totalProjects;
  final int activeProjects;
  final double totalRaised;
  final double totalInvested;
  final int totalInvestments;

  const StatsSummary({
    super.key,
    required this.totalProjects,
    required this.activeProjects,
    required this.totalRaised,
    required this.totalInvested,
    required this.totalInvestments,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.compactCurrency(symbol: '\$');

    return Row(
      children: [
        Row(
          children: [
            _buildStatCard(
              icon: Icons.folder_outlined,
              label: 'Total Projects',
              value: totalProjects.toString(),
              subtitle: '$activeProjects active',
              color: Colors.blue,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              icon: Icons.trending_up_outlined,
              label: 'Total Raised',
              value: currencyFormat.format(totalRaised),
              subtitle: 'From your projects',
              color: Colors.green,
            ),
          ],
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            _buildStatCard(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Total Invested',
              value: currencyFormat.format(totalInvested),
              subtitle: 'In $totalInvestments project${totalInvestments != 1 ? 's' : ''}',
              color: Colors.purple,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              icon: Icons.pie_chart_outline,
              label: 'Portfolio',
              value: '${_calculateROI().toStringAsFixed(1)}%',
              subtitle: 'Return on investment',
              color: Colors.orange,
            )
          ],
        )

      ],
    );
  }

  double _calculateROI() {
    if (totalInvested == 0) return 0.0;
    // Simplified ROI calculation
    return ((totalRaised - totalInvested) / totalInvested) * 100;
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
