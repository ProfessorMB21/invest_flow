import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:investflow/core/models/project.dart';
import 'package:investflow/core/providers/repository_providers.dart';
import 'package:investflow/features/auth/logic/auth_service.dart';
import 'package:investflow/features/dashboard/presentation/widgets/project_card.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  ProjectStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final userId = authService.currentUserId;

    if (kDebugMode) {
      if (userId != null) {
        print('current user id: $userId');
      }
      else {
        print('user id null: $userId');
      }
    }

    // Stream providers
    final allProjectsAsync = ref.watch(activeProjectsStreamProvider);
    final myProjectsAsync = userId != null
        ? ref.watch(userOwnedProjectsStreamProvider(userId))
        : const AsyncValue<List<Project>>.data([]);
    final investedProjectsAsync = userId != null
        ? ref.watch(userInvestedProjectsStreamProvider(userId))
        : const AsyncValue<List<Project>>.data([]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.explore), text: 'Discover'),
            Tab(icon: Icon(Icons.folder), text: 'My Projects'),
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Invested'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar (visible when searching)
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                label: Text('Search: "$_searchQuery"'),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() => _searchQuery = '');
                  _searchController.clear();
                },
              ),
            ),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Discover Tab
                _buildProjectGrid(
                  projectsAsync: allProjectsAsync,
                  emptyMessage: 'No active projects available',
                  userId: userId,
                ),
                // My Projects Tab
                _buildProjectGrid(
                  projectsAsync: myProjectsAsync,
                  emptyMessage: 'You haven\'t created any projects yet',
                  userId: userId,
                  showCreateButton: true,
                ),
                // Invested Tab
                _buildProjectGrid(
                  projectsAsync: investedProjectsAsync,
                  emptyMessage: 'You haven\'t invested in any projects yet',
                  userId: userId,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
        onPressed: () => context.push('/projects/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      )
          : null,
    );
  }

  Widget _buildProjectGrid({
    required AsyncValue<List<Project>> projectsAsync,
    required String emptyMessage,
    String? userId,
    bool showCreateButton = false,
  }) {
    return projectsAsync.when(
      data: (projects) {
        // Filter by search query
        final filteredProjects = _searchQuery.isEmpty
            ? projects
            : projects.where((p) {
          return p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.category.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        // Filter by status
        final statusFiltered = _filterStatus == null
            ? filteredProjects
            : filteredProjects.where((p) => p.status == _filterStatus).toList();

        if (statusFiltered.isEmpty) {
          return _buildEmptyState(emptyMessage, showCreateButton);
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Trigger refresh (streams auto-update)
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: statusFiltered.length,
            itemBuilder: (context, index) {
              final project = statusFiltered[index];
              return ProjectCard(
                project: project,
                onTap: () => context.push('/projects/${project.id}'),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Error loading projects: $error'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(activeProjectsStreamProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, bool showCreateButton) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          if (showCreateButton) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/projects/create'),
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Project'),
            ),
          ],
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Projects'),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search by title, description, or category',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            setState(() => _searchQuery = value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _searchQuery = '');
              _searchController.clear();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _searchQuery = _searchController.text);
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Radio<ProjectStatus?>(
                value: null,
                groupValue: _filterStatus,
                onChanged: (value) {
                  setState(() => _filterStatus = value);
                  Navigator.pop(context);
                },
              ),
              title: const Text('All Projects'),
            ),
            ...ProjectStatus.values.map((status) {
              return ListTile(
                leading: Radio<ProjectStatus?>(
                  value: status,
                  groupValue: _filterStatus,
                  onChanged: (value) {
                    setState(() => _filterStatus = value);
                    Navigator.pop(context);
                  },
                ),
                title: Text(status.name.capitalize()),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _filterStatus = null);
              Navigator.pop(context);
            },
            child: const Text('Clear Filter'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

// Extension for capitalizing first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
