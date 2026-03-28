import 'dart:async';
import 'package:investflow/features/auth/logic/auth_provider_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class SupabaseAuthProvider implements AuthProviderInterface {
  SupabaseClient? _supabase;
  
  @override
  Future<void> initialize() async {
    await Supabase.initialize(
        url: const String.fromEnvironment('SUPABASE_URL'),
        anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY')
    );
    _supabase = Supabase.instance.client;
  }

  @override
  Future<void> signIn(String email, String password) async {
    await _supabase!.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    await _supabase!.auth.signOut();
  }

  @override
  Future<void> signUp(String email, String password, String fullName) async {
    await _supabase!.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  @override
  Stream<AuthState> get authStateChanges {
    return _supabase!.auth.onAuthStateChange.map((data) {
      final session = data.session;
      return AuthState(
        userId: session?.user.id,
        email: session?.user.email,
        isAuthenticated: session != null,
      );
    });
  }

  @override
  String? get currentUserEmail => _supabase!.auth.currentUser?.email;

  @override
  String? get currentUserId => _supabase!.auth.currentUser?.id;

  @override
  bool get isAuthenticated => _supabase!.auth.currentUser != null;

  @override
  Future<void> createUserProfile(String userId, String email, String fullName, {String? role}) {
    // TODO: implement createUserProfile
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) {
    // TODO: implement getUserProfile
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    // TODO: implement sendPasswordResetEmail
    throw UnimplementedError();
  }

  @override
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) {
    // TODO: implement updateUserProfile
    throw UnimplementedError();
  }


}
