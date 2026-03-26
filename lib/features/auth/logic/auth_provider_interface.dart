abstract class AuthProviderInterface {
  Future<void> initialize();
  Future<void> signIn(String email, String password);
  Future<void> signUp(String email, String password, String fullName);
  Future<void> signOut();
  Stream<AuthState> get authStateChanges;
  String? get currentUserId;
  String? get currentUserEmail;
  bool get isAuthenticated;
}

class AuthState {
  final String? userId;
  final String? email;
  final bool isAuthenticated;

  AuthState({this.userId, this.email, required this.isAuthenticated});
}
