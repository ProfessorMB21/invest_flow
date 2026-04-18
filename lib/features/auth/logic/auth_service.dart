import 'package:flutter/cupertino.dart';
import 'package:investflow/core/services/auth_persistence_service.dart';
import 'package:investflow/features/auth/logic/auth_provider_interface.dart';
import 'package:investflow/features/auth/logic/firebase_auth_provider.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  late final AuthProviderInterface _provider;
  final AuthPersistenceService _persistenceService = AuthPersistenceService();
  AuthState _authState = AuthState(isAuthenticated: false);

  Future<void> initialize({bool useFirebase = true}) async {
    if (useFirebase) {
      _provider = FirebaseAuthProvider();
    } else {
      throw UnimplementedError('Supabase not supported!');
    }

    await _provider.initialize();
    await _persistenceService.initialize();

    // listen to auth state changes
    _provider.authStateChanges.listen((state) {
      _authState = state;
      notifyListeners(); // Notify GoRouter
    });
  }

  // ==================== Auth methods
  Future<void> signIn(String email, String password, {bool rememberMe = true}) =>
      _provider.signIn(email, password, rememberMe: rememberMe);

  Future<void> signUp(String email, String password, String fullName) =>
      _provider.signUp(email, password, fullName);

  Future<void> signOut({bool clearSavedCredentials = false}) => _provider.signOut(clearSavedCredentials: clearSavedCredentials);

  // ==================== Persistence methods
  AuthPersistenceService get persistence => _persistenceService;

  Future<void> sendPasswordResetEmail(String email) async {
    await _provider.sendPasswordResetEmail(email);
  }

  // ====================== Profile methods
  Future<void> createUserProfile(
      String userId,
      String email,
      String fullName,
      {String? role}
      ) async {
    await _provider.createUserProfile(userId, email, fullName,role: role);
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    await _provider.updateUserProfile(userId, data);
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;
    return await _provider.getUserProfile(userId);
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return await _provider.getUserProfile(userId);
  }

  // Getters
  AuthState get authState => _authState;
  String? get currentUserId => _authState.userId;
  String? get currentUserEmail => _authState.email;
  bool get isAuthenticated => _authState.isAuthenticated;
}
