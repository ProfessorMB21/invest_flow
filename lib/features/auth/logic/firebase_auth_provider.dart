import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:investflow/core/services/auth_persistence_service.dart';
import 'package:investflow/features/auth/logic/auth_provider_interface.dart';

class FirebaseAuthProvider implements AuthProviderInterface{
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  final AuthPersistenceService _persistenceService = AuthPersistenceService();

  @override
  Future<void> initialize() async {
    await Firebase.initializeApp();
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;

    // Initialize persistence settings
    await _persistenceService.initialize();
    await _persistenceService.initializePersistence();

    // BUG FIX: If user has "Remember me" disabled but Firebase has a
    // persisted session, sign out immediately to respect user preference
    if (!_persistenceService.rememberMe && _auth!.currentUser != null) {
      if (kDebugMode) {
        debugPrint('Remember me is disabled - signing out persisted session');
      }
      await _auth!.signOut();
      // Clear any saved credentials as well
      await _persistenceService.clearSavedCredentials();
    }

    if (kDebugMode) {
      debugPrint('***** Firebase Auth Provider Initialized *****');
    }
  }

  // ======================= Auth methods
  @override
  Future<void> signIn(String email, String password, {bool rememberMe = true}) async {
    try {
      // Update persistence based on remember me setting before signing in
      await _persistenceService.setRememberMe(rememberMe);

      await _auth!.signInWithEmailAndPassword(email: email, password: password);

      // auto create profile if doesn't exist
      final user = _auth!.currentUser;
      if (user != null) {
        await createUserProfile(
            user.uid,
            user.email ?? '',
            user.displayName ?? 'user${user.uid}'
        );

        // Save credentials for quick login next time
        if (rememberMe) {
          final profile = await getUserProfile(user.uid);
          await _persistenceService.saveCredentials(
            email,
            username: profile?['fullName'] ?? user.displayName,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message ?? '');
    }
  }

  @override
  Future<void> signUp(String email, String password, String fullName) async {
    try {
      final credential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password
      );

      // create user profile immediately after sign up
      if (credential.user != null) {
        await createUserProfile(
          credential.user!.uid,
          email,
          fullName
        );
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message ?? '');
    }
  }

  @override
  Future<void> signOut({bool clearSavedCredentials = false}) async {
    await _auth!.signOut();
    if (clearSavedCredentials) {
      await _persistenceService.clearSavedCredentials();
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth!.sendPasswordResetEmail(email: email);
  }

  // ========================  Profile methods
  @override
  Future<void> createUserProfile(
      String userId,
      String email,
      String fullName,
      {String? role}
      ) async {
    try {
    final profileRef = _firestore!.collection('profile').doc(userId);
    final profileDoc = await profileRef.get();

    if (!profileDoc.exists) {
      await profileRef.set({
        'email': email,
        'fullName': fullName.isNotEmpty ? fullName : email.split('@').first,
        'role': role ?? 'investor',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isVerified': false,
      });
      if (kDebugMode) {
        print("User profile created: $userId");
      }
    }
    } catch (e) {
      if (kDebugMode) {
        print('failed to create user profile');
      }
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _firestore!.collection('profiles').doc(userId).get();
    return doc.exists ? doc.data() : null;
  }

  @override
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _firestore!.collection('profiles').doc(userId).update({
      ...data,
      'updateAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================== State methods
  @override
  Stream<AuthState> get authStateChanges {
    return _auth!.authStateChanges().map((user) {
      return AuthState(
        userId: user?.uid,
        email: user?.email,
        isAuthenticated: user != null,
      );
    });
  }

  @override
  String? get currentUserId => _auth!.currentUser?.uid;

  @override
  String? get currentUserEmail => _auth!.currentUser?.email;

  @override
  bool get isAuthenticated => _auth!.currentUser != null;

}

class AuthException implements Exception {
  final String code;
  final String message;
  AuthException(this.code, this.message);

  @override
  String toString() => 'AuthException($code): $message';
}
