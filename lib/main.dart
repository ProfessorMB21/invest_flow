import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:investflow/core/services/database_service.dart';
import 'package:investflow/core/services/firestore_init_service.dart';
import 'package:investflow/core/theme/app_theme.dart';
import 'package:investflow/features/auth/logic/auth_service.dart';
import 'package:investflow/features/auth/logic/auth_provider_interface.dart';
import 'package:investflow/firebase_options.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/dashboard/presentation/dashboard_shell.dart';

// Auth state provider
final authStateProvider = Provider<AuthState>((ref) {
  return AuthService().authState;
});

// Router provider
late final GoRouter _router;

final goRouterProvider = Provider<GoRouter>((ref) {
  return _router;
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Auth Service (this also sets up the ChangeNotifier)
  await AuthService().initialize(useFirebase: true);

  // Initialize DB Service
  DatabaseService().initialize();

  // Initialize Firestore collections
  await FirestoreInitService().initialize();
  final status = await FirestoreInitService().getInitializationStatus();
  if (kDebugMode) {
    print('Firestore init status: $status');
  }

  // Initialize router with AuthService as refreshListenable
  _router = GoRouter(
    initialLocation: '/login',
    refreshListenable: AuthService(),
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardShell(),
      ),
    ],
    redirect: (context, state) {
      final authService = AuthService();
      final isLoggedIn = authService.isAuthenticated;
      final isLoggingIn = state.uri.toString() == '/login';

      if (kDebugMode) {
        print('>>> Redirect check: isLoggedIn=$isLoggedIn, location=${state.uri.toString()}');
      }

      if (!isLoggedIn && !isLoggingIn) {
        if (kDebugMode) {
          print('>>> Redirecting to /login');
        }
        return '/login';
      }
      if (isLoggedIn && isLoggingIn) {
        if (kDebugMode) {
          print('>>> Redirecting to /');
        }
        return '/';
      }
      return null;
    },
  );

  if (kDebugMode) {
    print('***** App Initialization Complete *****');
  }

  runApp(const ProviderScope(child: InvestFlowApp()));
}

class InvestFlowApp extends ConsumerWidget {
  const InvestFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'InvestFlow',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
