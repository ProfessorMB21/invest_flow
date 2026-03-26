import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investflow/features/auth/logic/auth_service.dart';
import 'package:investflow/features/auth/logic/firebase_auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  // bool _obscurePassword = true;

  @override @override
  void initState() {
    super.initState();
    testFirestore();
  }

  Future<void> _login() async {
    final currentState = _formKey.currentState;
    if (currentState == null || !currentState.validate()) return;

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
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showError(_getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.trending_up,
                  size: 80,
                  color: Color(0xFF0052CC),
                ),
                const SizedBox(height: 16),

                const Text(
                    "InvestFlow",
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0052CC)
                    )
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to manage your investments',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 48),

                // Email field
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'your@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                //Password field
                TextFormField(
                  controller: _passCtrl,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at lease 6 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Sign in button
                FilledButton.icon(
                  onPressed: _isLoading ? null : _login,
                  icon: _isLoading
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Icon(Icons.login),
                  //child: _isLoading ? const CircularProgressIndicator() : const Text("Sign In"),
                  label: Text(_isLoading ? 'Signing in...' : 'Sign In'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF0052CC),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sign up coming soon!'),
                        )
                      );
                    },
                    child: Text("Create an account (Coming soon)")
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> testFirestore() async {
  try {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection('profiles').limit(1).get();
    print('✓ Firestore connected! Collections: ${snapshot.docs.length}');
  } catch (e) {
    print('✗ Firestore error: $e');
  }
}
