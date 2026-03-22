import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );
      if (mounted) context.go('/');
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getAuthErrorMessage(e.message)),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          )
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("An unexpected error occurred."),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getAuthErrorMessage(String? message) {
    switch (message) {
      case 'Invalid login credentials':
        return 'Invalid email or password';
      case 'Email not confirmed':
        return 'Please verify your email address';
      case 'User already registered':
        return 'An account with this email already exists';
      default:
        return message ?? 'Authentication failed';
    }
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
                const Text("InvestFlow", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0052CC))),
                const SizedBox(height: 8),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading ? const CircularProgressIndicator() : const Text("Sign In"),
                ),
                TextButton(onPressed: () {}, child: Text("Create an account (Coming soon)"))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
