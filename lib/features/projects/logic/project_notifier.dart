// Project State
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:investflow/core/models/investment.dart';
import 'package:investflow/core/models/milestone.dart';
import 'package:investflow/core/models/project.dart';
import 'package:investflow/core/services/database_service.dart';
import 'package:investflow/features/auth/logic/auth_service.dart';

class ProjectState {
  final List<Project> allProjects;
  final List<Project> myProjects;
  final List<Project> investedProjects;
  final Project? selectedProject;
  final bool isLoading;
  final String? error;

  ProjectState({
    this.allProjects = const [],
    this.myProjects = const [],
    this.investedProjects = const [],
    this.selectedProject,
    this.isLoading = false,
    this.error,
  });

  ProjectState copyWith({
    List<Project>? allProjects,
    List<Project>? myProjects,
    List<Project>? investedProjects,
    Project? selectedProject,
    bool? isLoading,
    String? error,
  }) {
    return ProjectState(
      allProjects: allProjects ?? this.allProjects,
      myProjects: myProjects ?? this.myProjects,
      investedProjects: investedProjects ?? this.investedProjects,
      selectedProject: selectedProject ?? this.selectedProject,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Project Notifier
class ProjectNotifier extends StateNotifier<ProjectState> {
  final Ref _ref;
  final _dbService = DatabaseService();

  ProjectNotifier(this._ref) : super(ProjectState());

  // Create new project
  Future<String> createProject({
    required String title,
    required String description,
    required double goalAmount,
    required DateTime deadline,
    required String category,
  }) async {
    final authService = AuthService();
    final userId = authService.currentUserId;

    if (userId == null) {
      throw Exception('User not authenticated');
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final project = Project(
        id: '', // Auto-generated
        ownerId: userId,
        title: title,
        description: description,
        goalAmount: goalAmount,
        raisedAmount: 0,
        status: ProjectStatus.active,
        createdAt: DateTime.now(),
        deadline: deadline,
        category: category,
        investorIds: [],
        totalInvestors: 0,
      );

      final projectId = await _dbService.projectRepository.createProject(project);

      // Create initial milestone
      await _createInitialMilestone(projectId, deadline);

      state = state.copyWith(isLoading: false);
      return projectId;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Create initial milestone for new project
  Future<void> _createInitialMilestone(String projectId, DateTime deadline) async {
    final milestone = Milestone(
      id: '',
      projectId: projectId,
      title: 'Project Launch',
      description: 'Initial project setup and launch',
      deadline: deadline,
      isCompleted: false,
      createdAt: DateTime.now(),
    );
    await _dbService.milestoneRepository.createMilestone(milestone);
  }

  // Update project
  Future<void> updateProject(String projectId, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dbService.projectRepository.updateProject(projectId, data);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Delete project
  Future<void> deleteProject(String projectId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dbService.projectRepository.deleteProject(projectId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Add investment to project
  Future<void> addInvestment(String projectId, double amount) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authService = AuthService();
      final investorId = authService.currentUserId!;

      // Create investment record
      final investmentId = await _dbService.investmentRepository.createInvestment(
        Investment(
          id: '', // auto generated
          projectId: projectId,
          investorId: investorId,
          amount: amount,
          createdAt: DateTime.timestamp(),
        )
      );

      // Update project raised amount
      await _dbService.projectRepository.updateRaisedAmount(projectId, amount);

      // Add investor to project
      await _dbService.projectRepository.addInvestorToProject(projectId, investorId);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Load project by ID
  Future<void> loadProject(String projectId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final project = await _dbService.projectRepository.getProject(projectId);
      state = state.copyWith(selectedProject: project, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Clear selected project
  void clearSelectedProject() {
    state = state.copyWith(selectedProject: null);
  }
}

// Project Notifier Provider
final projectNotifierProvider = StateNotifierProvider<ProjectNotifier, ProjectState>((ref) {
  return ProjectNotifier(ref);
});
