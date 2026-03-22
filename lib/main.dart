import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:investflow/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide SupabaseClient;
import 'package:investflow/supabaase_client.dart';

import 'features/auth/presentation/login_screen.dart';
import 'features/dashboard/presentation/dashboard_shell.dart';

// Auth provider
final authProvider = StreamProvider((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// Session provider
final sessionProvider = Provider<Session?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.value?.session;
});

// Router
final goRouterProvider = Provider((ref) {
  final session = ref.watch(sessionProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange
    ),
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
      final isLoggedIn = session != null;
      final isLoggingIn = state.uri.toString() == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/';
      return null;
    },
  );
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseClient().init();
  runApp(const ProviderScope(child: InvestFlowApp()));
}

class InvestFlowApp extends ConsumerWidget {
  const InvestFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'InvestFlow',
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// Helper class for GoRouter Refresh
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    subscription = stream.asBroadcastStream().listen(
        (dynamic _) => notifyListeners(),
    );
  }
  late final StreamSubscription<dynamic> subscription;

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }
}
