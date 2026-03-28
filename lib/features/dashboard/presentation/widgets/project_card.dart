import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:investflow/core/models/project.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;
  final bool showProgress;

  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat.yMMMd();

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(project.status),
                ],
              ),
              const SizedBox(height: 8),

              // Category
              Text(
                project.category,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                project.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // Progress Bar (if enabled)
              if (showProgress && project.status == ProjectStatus.active) ...[
                LinearProgressIndicator(
                  value: project.progressPercentage / 100,
                  backgroundColor: Colors.grey[200],
                  color: Theme.of(context).colorScheme.primary,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${project.progressPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${currencyFormat.format(project.raisedAmount)} / ${currencyFormat.format(project.goalAmount)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Footer: Deadline + Investors
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Deadline
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        project.deadline != null
                            ? dateFormat.format(project.deadline!)
                            : 'No deadline',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),

                  // Investor Count
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${project.totalInvestors} investor${project.totalInvestors != 1 ? 's' : ''}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ProjectStatus status) {
    final config = _getStatusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color.withValues(alpha: 0.3)),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: config.color,
        ),
      ),
    );
  }

  ({String label, Color color}) _getStatusConfig(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.active:
        return (label: 'Active', color: Colors.green);
      case ProjectStatus.completed:
        return (label: 'Completed', color: Colors.blue);
      case ProjectStatus.paused:
        return (label: 'Paused', color: Colors.orange);
      case ProjectStatus.cancelled:
        return (label: 'Cancelled', color: Colors.red);
    }
  }
}