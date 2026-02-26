import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/auth_provider.dart';
import '../core/supabase/supabase_client.dart';
import '../features/auth/presentation/screens/create_team_screen.dart';
import '../features/auth/presentation/screens/join_team_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/roster/presentation/screens/player_detail_screen.dart';
import '../features/roster/presentation/screens/roster_screen.dart';
import '../features/settings/presentation/screens/team_settings_screen.dart';

/// Notifier que escucha cambios de auth para refrescar el router.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
  }

  /// Redirige según el estado de autenticación.
  String? redirect(BuildContext context, GoRouterState state) {
    final isLoggedIn = supabaseClient.auth.currentUser != null;
    final location = state.matchedLocation;
    final isAuthRoute = location == '/login' || location == '/register';

    if (!isLoggedIn && !isAuthRoute) return '/login';
    if (isLoggedIn && isAuthRoute) return '/home';
    return null;
  }
}

/// Proveedor global del router de la aplicación.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/join-team',
        builder: (context, state) => const JoinTeamScreen(),
      ),
      GoRoute(
        path: '/create-team',
        builder: (context, state) => const CreateTeamScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/roster',
        builder: (context, state) => const RosterScreen(),
      ),
      GoRoute(
        path: '/roster/:memberId',
        builder: (context, state) => PlayerDetailScreen(
          memberId: state.pathParameters['memberId']!,
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const TeamSettingsScreen(),
      ),
    ],
  );
});
