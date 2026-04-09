// Dashboard State
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investflow/core/models/project.dart';
import 'package:investflow/core/models/user_profile.dart';
import 'package:investflow/core/providers/repository_providers.dart';
import 'package:investflow/features/auth/logic/auth_service.dart';

class DashboardState {
  final UserProfile? userProfile;
  final List<Project> myProjects;
  final List<Project> investedProjects;
  final List<Project> activeProjects;
  final double totalRaised;
  final bool isLoading;
  final String? error;

  DashboardState({
    this.userProfile,
    this.myProjects = const [],
    this.investedProjects = const [],
    this.activeProjects = const [],
    this.totalRaised = 0.0,
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    UserProfile? userProfile,
    List<Project>? myProjects,
    List<Project>? investedProjects,
    List<Project>? activeProjects,
    double? totalRaised,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      userProfile: userProfile ?? this.userProfile,
      myProjects: myProjects ?? this.myProjects,
      investedProjects: investedProjects ?? this.investedProjects,
      activeProjects: activeProjects ?? this.activeProjects,
      totalRaised: totalRaised ?? this.totalRaised,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Dashboard Notifier
class DashboardNotifier extends AsyncNotifier<DashboardState> {
  final AuthService _authService = AuthService();
  double _totalBalance = 0.0;

  @override
  Future<DashboardState> build() async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      return DashboardState();
    }

    try {
      // Get user profile stream and wait for first value
      final profileStream = ref.watch(userRepositoryProvider).getProfileStream(userId);
      final userProfile = await profileStream.first;

      if (userProfile != null) {
        // Get owned projects
        final ownedProjectsStream = ref.watch(projectRepositoryProvider).getProjectsByOwnerStream(userId);
        final ownedProjects = await ownedProjectsStream.first;

        // Get invested projects
        final investedProjectsStream = ref.watch(projectRepositoryProvider).getProjectsByInvestorStream(userId);
        final investedProjects = await investedProjectsStream.first;

        // Get active projects for user
        final activeProjectsStream = ref.watch(projectRepositoryProvider).getActiveProjectsStreamForUser(userId);
        final activeProjects = await activeProjectsStream.first;

        // Calculate total balance from owned projects
        _totalBalance = ownedProjects.fold<double>(
          0,
          (sum, project) => sum + project.raisedAmount,
        );

        return DashboardState(
          userProfile: userProfile,
          myProjects: ownedProjects,
          investedProjects: investedProjects,
          activeProjects: activeProjects,
          totalRaised: _totalBalance,
          isLoading: false,
        );
      } else {
        // Profile doesn't exist yet, create it
        await createOrUpdateProfile();
        return state.value ?? DashboardState();
      }
    } catch (e) {
      return DashboardState(error: e.toString(), isLoading: false);
    }
  }

  // Create/update user profile if it doesn't exist
  Future<void> createOrUpdateProfile() async {
    try {
      final userRepository = ref.read(userRepositoryProvider);

      // Create initial profile with default values
      final userProfile = UserProfile(
        id: _authService.currentUserId ?? '',
        fullName: 'User',
        email: _authService.currentUserEmail ?? '',
        role: UserRole.investor,
        createdAt: DateTime.now(),
      );

      await userRepository.createOrUpdateProfile(userProfile);
      // Trigger rebuild
      ref.invalidateSelf();
    } catch (e) {
      print('Error creating/updating profile: $e');
    }
  }

  // Refresh data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  // Check for updates
  Future<void> checkForUpdates({
    bool autoCheck = false,
    Duration checkInterval = const Duration(seconds: 10),
  }) async {
    final userId = _authService.authState.userId;

    if (userId == null || !_authService.authState.isAuthenticated) {
      return;
    }

    try {
      // Skip if auto-check and already loading
      if (autoCheck && state.isLoading) {
        return;
      }

      // Just refresh to get latest data
      await refresh();
    } catch (e) {
      print('Error checking for updates: $e');
    }
  }

  // Getters
  UserProfile? get userProfile => state.value?.userProfile;
  List<Project> get myProjects => state.value?.myProjects ?? [];
  List<Project> get investedProjects => state.value?.investedProjects ?? [];
  List<Project> get activeProjects => state.value?.activeProjects ?? [];
  bool get isLoading => state.isLoading;
  String? get error => state.error?.toString();
  double get totalBalance => _totalBalance;

  double get totalInvested {
    final investments = state.value?.investedProjects ?? [];
    // Note: This calculates from projects, but should calculate from actual investment amounts
    // This is a placeholder - investments should have amount field
    return 0.0; // TODO: Implement proper total invested calculation from InvestmentRepository
  }

  int get totalInvestmentsCount =>
      state.value?.investedProjects.length ?? 0;

  int get activeProjectsCount =>
      state.value?.activeProjects.where((p) => p.status == ProjectStatus.active).length ?? 0;
}

// Dashboard Notifier Provider
final dashboardNotifierProvider = AsyncNotifierProvider<DashboardNotifier, DashboardState>(
  () => DashboardNotifier(),
);
