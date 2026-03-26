abstract class AuthProviderInterface {
  Future<void> initialize();

  // Auth methods
  Future<void> signIn(String email, String password);
  Future<void> signUp(String email, String password, String fullName);
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email); // coming soon

  // State streams
  Stream<AuthState> get authStateChanges;

  // Getters
  String? get currentUserId;
  String? get currentUserEmail;
  bool get isAuthenticated;

  // user profile methods
  Future<void> createUserProfile(
      String userId,
      String email,
      String fullName,
      {String? role}
  );
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getUserProfile(String userId);
}

class AuthState {
  final String? userId;
  final String? email;
  final bool isAuthenticated;

  AuthState({this.userId, this.email, required this.isAuthenticated});
}
