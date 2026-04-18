import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing authentication persistence settings and saved credentials.
///
/// Handles:
/// - "Remember me" preference (controls Firebase Auth persistence)
/// - Saving/retrieving last logged in username/email for quick re-login
class AuthPersistenceService {
  static final AuthPersistenceService _instance = AuthPersistenceService._internal();
  factory AuthPersistenceService() => _instance;
  AuthPersistenceService._internal();

  SharedPreferences? _prefs;

  static const String _rememberMeKey = 'auth_remember_me';
  static const String _savedEmailKey = 'auth_saved_email';
  static const String _savedUsernameKey = 'auth_saved_username';

  /// Initialize the service. Must be called before using other methods.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Whether user wants to stay logged in across app restarts.
  /// If false, Firebase Auth will use in-memory persistence only.
  bool get rememberMe => _prefs?.getBool(_rememberMeKey) ?? true;

  /// Set the remember me preference.
  Future<void> setRememberMe(bool value) async {
    await _prefs?.setBool(_rememberMeKey, value);
    await _applyPersistenceSetting(value);
  }

  /// Apply Firebase Auth persistence based on remember me setting.
  Future<void> _applyPersistenceSetting(bool rememberMe) async {
    try {
      final persistence = rememberMe
          ? Persistence.LOCAL
          : Persistence.NONE;
      await FirebaseAuth.instance.setPersistence(persistence);
      if (kDebugMode) {
        debugPrint('Firebase Auth persistence set to: ${rememberMe ? "LOCAL" : "NONE"}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to set Firebase persistence: $e');
      }
    }
  }

  /// Initialize Firebase Auth persistence on app startup.
  /// Call this after Firebase.initializeApp().
  Future<void> initializePersistence() async {
    await _applyPersistenceSetting(rememberMe);
  }

  /// The saved email from last successful login.
  String? get savedEmail => _prefs?.getString(_savedEmailKey);

  /// The saved username/display name from last successful login.
  String? get savedUsername => _prefs?.getString(_savedUsernameKey);

  /// Whether there's a saved username/email available.
  bool get hasSavedCredentials => savedEmail != null && savedEmail!.isNotEmpty;

  /// Save credentials after successful login.
  Future<void> saveCredentials(String email, {String? username}) async {
    await _prefs?.setString(_savedEmailKey, email);
    if (username != null && username.isNotEmpty) {
      await _prefs?.setString(_savedUsernameKey, username);
    }
  }

  /// Clear saved credentials (called on sign out).
  Future<void> clearSavedCredentials() async {
    await _prefs?.remove(_savedEmailKey);
    await _prefs?.remove(_savedUsernameKey);
  }

  /// Clear all auth-related preferences.
  Future<void> clearAll() async {
    await clearSavedCredentials();
    await _prefs?.remove(_rememberMeKey);
  }
}
