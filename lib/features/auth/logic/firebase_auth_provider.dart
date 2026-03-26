import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:investflow/features/auth/logic/auth_provider_interface.dart';

class FirebaseAuthProvider implements AuthProviderInterface{
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  @override
  Future<void> initialize() async {
    await Firebase.initializeApp();
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;

    if (kDebugMode) {
      print('***** Firebase Auth Provider Initialized *****');
    }
    // Create user profile
    await _ensureUserProfileCollection();
  }

  Future<void> _ensureUserProfileCollection() async {
    // initialize user profiles collection
    await _firestore!.collection('profiles').limit(1).get();
  }

  @override
  Future<void> signIn(String email, String password) async {
    try {
      await _auth!.signInWithEmailAndPassword(email: email, password: password);

      // ensure user profiles exist in firestore
      await _createOrUpdateUserProfile();
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

      // create user profile in firestore
      await _firestore!.collection('profile').doc(credential.user!.uid).set({
        'email': email,
        'fullName': fullName,
        'role': 'investor',
        'createdAt': FieldValue.serverTimestamp()
      });
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message ?? '');
    }
  }

  Future<void> _createOrUpdateUserProfile() async {
    final user = _auth!.currentUser;
    if (user == null) return;

    final profileRef = _firestore!.collection('profile').doc(user.uid);
    final profileDoc = await profileRef.get();

    if (!profileDoc.exists) {
      await profileRef.set({
        'email': user.email,
        'fullName': user.displayName ?? '',
        'role': 'investor',
        'createdAt': FieldValue.serverTimestamp()
      });
    }
  }

  @override
  Future<void> signOut() async {
    await _auth!.signOut();
  }

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
