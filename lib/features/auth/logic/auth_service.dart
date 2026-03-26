import 'package:flutter/cupertino.dart';
import 'package:investflow/features/auth/logic/auth_provider_interface.dart';
import 'package:investflow/features/auth/logic/firebase_auth_provider.dart';
import 'package:investflow/features/auth/logic/supabaase_client.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  late final AuthProviderInterface _provider;
  AuthState _authState = AuthState(isAuthenticated: false);

  Future<void> initialize({bool useFirebase = true}) async {
    if (useFirebase) {
      _provider = FirebaseAuthProvider();
    } else {
      _provider = SupabaseAuthProvider();
    }

    await _provider.initialize();

    // listen to auth state changes
    _provider.authStateChanges.listen((state) {
      _authState = state;
      notifyListeners(); // Notify GoRouter
    });
  }

  Future<void> signIn(String email, String password) =>
      _provider.signIn(email, password);

  Future<void> signUp(String email, String password, String fullName) =>
      _provider.signUp(email, password, fullName);

  Future<void> signOut() => _provider.signOut();

  AuthState get authState => _authState;
  String? get currentUserId => _authState.userId;
  String? get currentUserEmail => _authState.email;
  bool get isAuthenticated => _authState.isAuthenticated;
}
