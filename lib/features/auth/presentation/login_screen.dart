import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investflow/features/auth/logic/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(); // For sign up

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isSignUpMode = false;

  @override @override
  void initState() {
    super.initState();
    testFirestore();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
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
    });
  }

  // ========================== UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                    const Icon(Icons.trending_up, size: 80, color: Color(0xFF0052CC)),
                    const SizedBox(height: 16),
                    Text(
                      _isSignUpMode ? 'Create Account' : 'InvestFlow',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0052CC)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUpMode ? 'Sign up to start investing' : 'Sign in to manage your investments',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 48),

                    if (_isSignUpMode) ...[
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty || !value.contains('@') ? 'Please enter a valid email' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty || (_isSignUpMode && value.length < 6) ? 'Password must be at least 6 characters' : null,
                    ),
                    const SizedBox(height: 24),

                    FilledButton.icon(
                      onPressed: _isLoading ? null : (_isSignUpMode ? _handleSignUp : _login),
                      icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(_isSignUpMode ? Icons.person_add : Icons.login),
                      label: Text(_isLoading ? (_isSignUpMode ? 'Creating account...' : 'Signing in...') : (_isSignUpMode ? 'Create Account' : 'Sign In')),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: const Color(0xFF0052CC), foregroundColor: Colors.white),
                    ),
                    const SizedBox(height: 16),

                    TextButton(onPressed: _isLoading ? null : _toggleMode, child: Text(_isSignUpMode ? 'Already have an account? Sign in' : "Don't have an account? Sign up")),

                    if (!_isSignUpMode)
                      TextButton(onPressed: () => _showForgotPasswordDialog(), child: const Text('Forgot password?')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
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
