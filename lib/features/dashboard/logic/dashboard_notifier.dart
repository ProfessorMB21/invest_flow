import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:investflow/core/models/investment.dart';
import 'package:investflow/core/models/project.dart';
import 'package:investflow/core/models/user_profile.dart';
import 'package:investflow/core/providers/repository_providers.dart';
import 'package:investflow/features/auth/logic/auth_service.dart';

class DashboardState {
  final UserProfile? userProfile;
  final List<Project> ownedProjects;
  final List<Project> investedProjects;
  final List<Project> activeProjects;
  final List<Investment> investments;
  final double totalInvested;
  final double totalRaised;
  final int activeProjectsCount;
  final bool isLoading;
  final String? error;

  DashboardState({
    this.userProfile,
    this.ownedProjects = const [],
    this.investedProjects = const [],
    this.activeProjects = const [],
    this.investments = const [],
    this.totalInvested = 0,
    this.totalRaised = 0,
    this.activeProjectsCount = 0,
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    UserProfile? userProfile,
    List<Project>? ownedProjects,
    List<Project>? investedProjects,
    List<Project>? activeProjects,
    List<Investment>? investments,
    double? totalInvested,
    double? totalRaised,
    int? activeProjectsCount,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      userProfile: userProfile ?? this.userProfile,
      ownedProjects: ownedProjects ?? this.ownedProjects,
      investedProjects: investedProjects ?? this.investedProjects,
      activeProjects: activeProjects ?? this.activeProjects,
      investments: investments ?? this.investments,
      totalInvested: totalInvested ?? this.totalInvested,
      totalRaised: totalRaised ?? this.totalRaised,
      activeProjectsCount: activeProjectsCount ?? this.activeProjectsCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Dashboard Notifier
class DashboardNotifier extends StateNotifier<DashboardState> {
  final Ref _ref;
  StreamSubscription? _profileSubscription;
  StreamSubscription? _ownedProjectsSubscription;
  StreamSubscription? _investedProjectsSubscription;
  StreamSubscription? _investmentsSubscription;

  DashboardNotifier(this._ref) : super(DashboardState()) {
    _setupListeners();
  }

  // Initialize dashboard data
  Future<void> _setupListeners() async {
    final authService = AuthService();
    final userId = authService.currentUserId;

    if (userId == null) {
      state = state.copyWith(error: 'User not authenticated');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Listen to user profile stream
      _profileSubscription = _ref
        .read(userRepositoryProvider)
        .getProfileStream(userId)
        .listen((profile) {
          state = state.copyWith(userProfile: profile);
      });

      // Listen to owned projects stream
      _ref.read(userOwnedProjectsStreamProvider(userId)).whenData((projects) {
        state = state.copyWith(ownedProjects: projects);
      });

      // Listen to invested projects stream
      _ref.read(userInvestedProjectsStreamProvider(userId)).whenData((projects) {
        state = state.copyWith(investedProjects: projects);
      });

      // Listen to active projects stream (for browsing)
      _ref.read(activeProjectsStreamProvider).whenData((projects) {
        state = state.copyWith(activeProjects: projects);
      });

    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _ownedProjectsSubscription?.cancel();
    _investedProjectsSubscription?.cancel();
    _investmentsSubscription?.cancel();
    super.dispose();
  }

  // Refresh all data
  Future<void> refresh() async {
    _setupListeners();
  }

  // Create new project
  Future<String> createProject({
    required String title,
    required String description,
    required double goalAmount,
    required DateTime deadline,
    String category = 'General',
  }) async {
    final authService = AuthService();
    final userId = authService.currentUserId;

    if (userId == null) throw Exception('User not authenticated');

    final projectRepo = _ref.read(projectRepositoryProvider);

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
    );

    final projectId = await projectRepo.createProject(project);

    // Refresh streams automatically via Riverpod
    return projectId;
  }

  // Update user profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final authService = AuthService();
    final userId = authService.currentUserId;

    if (userId == null) throw Exception('User not authenticated');

    final userRepo = _ref.read(userRepositoryProvider);
    await userRepo.updateProfile(userId, data);
  }
}

// Dashboard Notifier Provider
final dashboardNotifierProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final notifier = DashboardNotifier(ref);
  // Auto-initialize when provider is first accessed
  //Future.microtask(() => notifier._setupListeners());
  return DashboardNotifier(ref);
});
