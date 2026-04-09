import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:investflow/core/models/project.dart';
import 'package:investflow/features/projects/logic/project_notifier.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  late Project? _project;

  @override
  void initState() {
    super.initState();
    // Load project data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectNotifierProvider.notifier).loadProject(widget.projectId);
    });
  }

  // Navigates back to previous page
  void _goBack() {
    if (mounted) {
      // checks if can go back in navigation stack
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        // if can't pop, navigate to dashboard
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectNotifierProvider);
    final project = state.selectedProject;
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat.yMMMd();

    if (state.isLoading && project == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _goBack(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('Project not found'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(project.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _goBack(),
          tooltip: 'Go back to project list',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareProject(project),
            tooltip: 'Share Project',
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, project),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit Project')),
              const PopupMenuItem(value: 'milestones', child: Text('View Milestones')),
              const PopupMenuItem(value: 'investors', child: Text('View Investors')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'report', child: Text('Report Project')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.read(projectNotifierProvider.notifier).loadProject(widget.projectId),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Banner
              _buildStatusBanner(project),
              const SizedBox(height: 16),

              // Progress Card
              _buildProgressCard(project, currencyFormat),
              const SizedBox(height: 16),

              // Project Info
              _buildInfoCard(project, dateFormat),
              const SizedBox(height: 16),

              // Description
              _buildDescriptionCard(project),
              const SizedBox(height: 16),

              // Investment Button
              if (project.status == ProjectStatus.active)
                _buildInvestButton(project, currencyFormat),
            ],
          ),
        ),
      ),
    );
  }

  // Get status configuration (label and color)
  ({String label, Color color}) _getStatusConfig(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.active: return (label: 'Active', color: Colors.green);
      case ProjectStatus.completed: return (label: 'Completed', color: Colors.blue);
      case ProjectStatus.paused: return (label: 'Paused', color: Colors.orange);
      case ProjectStatus.cancelled: return (label: 'Cancelled', color: Colors.red);
    }
  }

  Widget _buildStatusBanner(Project project) {
    final config = _getStatusConfig(project.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: config.color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${config.label} Project',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: config.color,
                ),
              ),
              Text(
                project.deadline != null
                    ? 'Ends ${DateFormat.yMMMd().format(project.deadline!)}'
                    : 'No deadline set',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(Project project, NumberFormat currencyFormat) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currencyFormat.format(project.raisedAmount),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'raised of ${currencyFormat.format(project.goalAmount)} goal',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${project.progressPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'funded',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: project.progressPercentage / 100,
              backgroundColor: Colors.grey[200],
              color: Theme.of(context).colorScheme.primary,
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.people,
                  label: 'Investors',
                  value: project.totalInvestors.toString(),
                ),
                _buildStatItem(
                  icon: Icons.calendar_today,
                  label: 'Days Left',
                  value: project.deadline != null
                      ? project.deadline!.difference(DateTime.now()).inDays.toString()
                      : 'N/A',
                ),
                _buildStatItem(
                  icon: Icons.category,
                  label: 'Category',
                  value: project.category,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildInfoCard(Project project, DateFormat dateFormat) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Project Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow('Created', dateFormat.format(project.createdAt)),
            _buildInfoRow(
              'Deadline',
              project.deadline != null ? dateFormat.format(project.deadline!) : 'Not set',
            ),
            _buildInfoRow('Category', project.category),
            _buildInfoRow('Status', project.status.name.capitalize()),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(Project project) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Text(
              project.description,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestButton(Project project, NumberFormat currencyFormat) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Want to invest in this project?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _showInvestDialog(project),
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('Invest Now'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInvestDialog(Project project) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invest in Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Project: ${project.title}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Investment Amount',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
                hintText: 'Minimum \$100',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount < 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Minimum investment is \$100')),
                );
                return;
              }

              Navigator.pop(context);

              try {
                await ref
                    .read(projectNotifierProvider.notifier)
                    .addInvestment(project.id, amount);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Investment successful!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Reload project to show updated progress
                  ref.read(projectNotifierProvider.notifier).loadProject(project.id);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Investment failed: $e')),
                  );
                }
              }
            },
            child: const Text('Confirm Investment'),
          ),
        ],
      ),
    );
  }

  void _shareProject(Project project) {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  void _handleMenuAction(String value, Project project) {
    switch (value) {
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit project coming soon!')),
        );
        break;
      case 'milestones':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Milestones coming soon!')),
        );
        break;
      case 'investors':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Investors list coming soon!')),
        );
        break;
      case 'report':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted!')),
        );
        break;
    }
  }
}

extension on String {
  String capitalize() {
    return this[0].toUpperCase() + substring(1);
  }
}
