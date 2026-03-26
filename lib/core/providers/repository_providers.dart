import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investflow/core/models/project.dart';
import 'package:investflow/core/models/user_profile.dart';
import 'package:investflow/core/repositories/investment_repository.dart';
import 'package:investflow/core/repositories/project_repository.dart';
import 'package:investflow/core/repositories/user_repository.dart';
import 'package:investflow/core/services/database_service.dart';

// DB Service Provider
final databaseServiceProvider = Provider<DatabaseService>((ref){
  return DatabaseService();
});

// UserRepo provider
final userRepositoryProvider = Provider<UserRepository>((ref){
  return ref.watch(databaseServiceProvider).userRepository;
});

// ProjectRepo provider
final projectRepositoryProvider = Provider<ProjectRepository>((ref){
  return ref.watch(databaseServiceProvider).projectRepository;
});

// InvestmentRepo provider
final investmentRepositoryProvider = Provider<InvestmentRepository>((ref){
  return ref.watch(databaseServiceProvider).investmentRepository;
});

// ================ Stream Providers

// Current User profile stream
final currentUserProfileStreamProvider = StreamProvider.family<UserProfile?, String>((ref, userId) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getProfileStream(userId);
});

// Active projects stream
final activeProjectsStreamProvider = StreamProvider<List<Project>>((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getActiveProjectsStream();
});

// User's Projects Stream (as owner)
final userOwnedProjectsStreamProvider = StreamProvider.family<List<Project>, String>((ref, ownerId) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getProjectsByOwnerStream(ownerId);
});

// User's Investments Stream (as investor)
final userInvestedProjectsStreamProvider = StreamProvider.family<List<Project>, String>((ref, investorId) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getProjectsByInvestorStream(investorId);
});
