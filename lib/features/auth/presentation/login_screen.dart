import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:investflow/core/services/update_checker.dart';
import 'package:investflow/features/auth/logic/auth_service.dart';
import 'package:investflow/features/dashboard/presentation/widgets/theme_toggle.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(); // For sign up

  // focus nodes for field navigation
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _nameFocusNode = FocusNode(); // for the sign up form

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isSignUpMode = false;

  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  // ======================== Application version updater
  /// Reads version from version.json, falls back to package_info
  Future<String> _getVersionFromFile() async {
    try {
      final versionFile = File('version.json');
      if (await versionFile.exists()) {
        final content = await versionFile.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        final version = data['version']?.toString();
        if (version != null && version.isNotEmpty) {
          return version;
        }
      }
    } catch (e) {
      debugPrint('Could not read version.json: $e');
    }
    // Fallback to package_info
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<void> _initializeScreen() async {
    final version = await _getVersionFromFile();
    if (!mounted) return;
    setState(() => _appVersion = 'v$version');

    // Check for updates (skip if already checked this session)
    try {
      final update = await UpdateChecker.checkForUpdate();
      if (!mounted) return;

      if (update != null) {
        final installed = await UpdateChecker.promptAndInstall(context, update);
        if (installed) {
          // Update was installed and app will restart
          return;
        }
      }
    } catch (e) {
      debugPrint('Update check error: $e');
      // Silent fail - don't block login on update check failure
    }
  }

  // ========================= Login/Sign In
  Future<void> _login() async {
    final currentState = _formKey.currentState;
    if (currentState == null || !currentState.validate()) {
      if (kDebugMode) {
        print('Form validation failed');
        return;
      }
    }

    if (_emailCtrl.text.isEmpty) {
      _showError('Email is required');
      return;
    }
    if (_passCtrl.text.isEmpty) {
      _showError('Password is required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (kDebugMode) {
        print('>>> Attempting Firebase login...');
      }
      await AuthService().signIn(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );

      if (kDebugMode) {
        print('>>> Login successful!');
      }
      if (mounted) context.go('/');
    } catch (e) {
      if (!mounted) return;
      _showError(_getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===================== Sign up
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await AuthService().signUp(
        _emailCtrl.text.trim(),
        _passCtrl.text,
        _nameCtrl.text.trim()
      );
      
      if (mounted) {
        context.go('/');
      }
      
    } catch (e) {
      if (mounted) {
        _showError(_getErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  // ===================== Error handling
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString();
    if (errorString.contains('invalid-email')) return 'Invalid email address';
    if (errorString.contains('user-not-found')) return 'No user found with this email';
    if (errorString.contains('wrong-password')) return 'Incorrect password';
    if (errorString.contains('invalid-credential')) return 'Invalid email or password';
    if (errorString.contains('network-request-failed')) return 'Network error. Check your connection';
    return 'Login failed: ${error.toString()}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleMode() {
    setState(() {
      _isSignUpMode = !_isSignUpMode;
      _formKey.currentState?.reset();
      FocusScope.of(context).unfocus(); // clears focus when switching nodes
    });
  }

  // ========================== Enter key handlers
  /// Called when Enter is pressed on Email field
  void _onEmailSubmitted(String value) {
    // Move focus to password field
    FocusScope.of(context).requestFocus(_passwordFocusNode);
  }

  /// Called when Enter is pressed on Password field
  void _onPasswordSubmitted(String value) {
    // Unfocus keyboard and trigger login/signup
    FocusScope.of(context).unfocus();

    if (_isSignUpMode) {
      _handleSignUp();
    } else {
      _login();
    }
  }

  /// Called when Enter is pressed on Name field (Sign Up mode)
  void _onNameSubmitted(String value) {
    // Move focus to email field
    FocusScope.of(context).requestFocus(_emailFocusNode);
  }


  // ========================== UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Version in top-left
          Positioned(
            top: 12,
            left: 12,
            child: AnimatedOpacity(
              opacity: _appVersion.isEmpty ? 0.0 : 1.0,
              duration: const Duration(microseconds: 300),
              child: Text(
                'ver. $_appVersion',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5
                ),
              ),
            ),
          ),

          // Theme toggle in top-right
          const Positioned(
            top: 4,
            right: 4,
            child: ThemeToggle(),
          ),

          // Test update checker button (debug only)
          if (kDebugMode)
            Positioned(
              top: 4,
              right: 60,
              child: IconButton(
                icon: const Icon(Icons.bug_report, color: Colors.orange),
                tooltip: 'Test Update Checker',
                onPressed: () async {
                  final results = await UpdateChecker.runTest();
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('UpdateChecker Test Results'),
                        content: SingleChildScrollView(
                          child: Text(
                            results.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),

          // Login UI
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                            Icons.trending_up,
                            size: 80,
                            color: Color(0xFF0052CC)
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isSignUpMode
                              ? 'Create Account'
                              : 'InvestFlow',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0052CC)
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isSignUpMode
                              ? 'Sign up to start investing'
                              : 'Sign in to manage your investments',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 48),

                        if (_isSignUpMode) ...[
                          TextFormField(
                            controller: _nameCtrl,
                            focusNode: _nameFocusNode,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: _onNameSubmitted,
                            decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.person_outline),
                                border: OutlineInputBorder()
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Please enter your name'
                                : null,
                          ),
                          const SizedBox(height: 16),
                        ],

                        TextFormField(
                          controller: _emailCtrl,
                          focusNode: _emailFocusNode,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: _onEmailSubmitted,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'you@example.com',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder()
                          ),
                          validator: (value) => value == null || value.isEmpty || !value.contains('@')
                              ? 'Please enter a valid email'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passCtrl,
                          focusNode: _passwordFocusNode,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: _onPasswordSubmitted,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: _isSignUpMode
                                ? 'Min 6 characters'
                                : 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) => value == null || value.isEmpty || (_isSignUpMode && value.length < 6)
                              ? 'Password must be at least 6 characters'
                              : null,
                        ),
                        const SizedBox(height: 24),

                        // Main action button
                        FilledButton.icon(
                          onPressed: _isLoading
                              ? null
                              : (_isSignUpMode ? _handleSignUp : _login),
                          icon: _isLoading
                              ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white
                              ))
                              : Icon(_isSignUpMode ? Icons.person_add : Icons.login),
                          label: Text(
                              _isLoading
                                  ? (_isSignUpMode ? 'Creating account...' : 'Signing in...')
                                  : (_isSignUpMode ? 'Create Account' : 'Sign In')
                          ),
                          style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFF0052CC),
                              foregroundColor: Colors.white),
                        ),
                        const SizedBox(height: 16),

                        TextButton(
                            onPressed: _isLoading
                                ? null
                                : _toggleMode,
                            child: Text(
                                _isSignUpMode
                                    ? 'Already have an account? Sign in'
                                    : "Don't have an account? Sign up"
                            )
                        ),

                        if (!_isSignUpMode)
                          TextButton(
                              onPressed: () => _showForgotPasswordDialog(),
                              child: const Text('Forgot password?')
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      )
    );
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email to receive a password reset link'),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await AuthService().sendPasswordResetEmail(emailCtrl.text.trim());
                if (mounted) _showError('Password reset link sent! Check your email.');
              } catch (e) {
                if (mounted) _showError('Failed to send reset email');
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Send Link'),
          )
        ],
      )
    );
  }
}

Future<void> testFirestore() async {
  try {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection('profiles').limit(1).get();
    if (kDebugMode) {
      print('✓ Firestore connected! Collections: ${snapshot.docs.length}');
    }
  } catch (e) {
    if (kDebugMode) {
      print('✗ Firestore error: $e');
    }
  }
}
