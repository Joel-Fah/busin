import 'package:busin_app/busin_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'access.dart';
import 'history/history_screen.dart';
import 'providers.dart';
import 'scan/scanner_screen.dart';
import 'screens/access_screens.dart';
import 'profile/profile_screen.dart';
import 'screens/legal_screen.dart';
import 'screens/sign_in_screen.dart';
import 'shell.dart';
import 'stats/stats_screen.dart';
import 'trips/today_screen.dart';
import 'trips/trip_screen.dart';

class Routes {
  const Routes._();

  static const loading = '/loading';
  static const signIn = '/sign-in';
  static const blocked = '/blocked';
  static const problem = '/problem';
  static const today = '/today';
  static String trip(String id) => '/trip/$id';
  static String scan(String id) => '/trip/$id/scan';
  static String legal(LegalDoc doc) => '/legal/${doc.name}';
  static const history = '/history';
  static const stats = '/stats';
  static const profile = '/profile';
}

/// Where the access state sends someone who is at [location], or null to stay. Pure, so it is tested on its own.
String? redirectFor(OpsAccess access, String location) {
  // The terms and privacy policy are readable by anyone, signed in or not.
  if (location.startsWith('/legal/')) return null;
  final target = switch (access) {
    OpsLoading() => Routes.loading,
    OpsSignedOut() => Routes.signIn,
    OpsLoadFailed() => Routes.problem,
    OpsBlocked() => Routes.blocked,
    OpsAllowed() => null,
  };
  if (target != null) return location == target ? null : target;
  // Allowed: the gate screens are not for them.
  const gates = [Routes.loading, Routes.signIn, Routes.blocked, Routes.problem];
  return gates.contains(location) ? Routes.today : null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final changes = ValueNotifier<int>(0);
  ref.listen(accessProvider, (_, _) => changes.value++);
  ref.onDispose(changes.dispose);

  final router = GoRouter(
    initialLocation: Routes.loading,
    refreshListenable: changes,
    redirect: (context, state) => redirectFor(ref.read(accessProvider), state.matchedLocation),
    routes: [
      GoRoute(path: Routes.loading, builder: (_, _) => const LoadingScreen()),
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(path: Routes.blocked, builder: (_, _) => const BlockedScreen()),
      GoRoute(path: Routes.problem, builder: (_, _) => const ProblemScreen()),
      // The four tabs; a trip, the scanner and the legal texts open over them.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => OpsShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: Routes.today, builder: (_, _) => const TodayScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.history, builder: (_, _) => const HistoryScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.stats, builder: (_, _) => const StatsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.profile, builder: (_, _) => const OpsProfileScreen())]),
        ],
      ),
      GoRoute(path: '/trip/:id', builder: (_, state) => TripScreen(tripId: state.pathParameters['id']!)),
      GoRoute(path: '/trip/:id/scan', builder: (_, state) => ScannerScreen(tripId: state.pathParameters['id']!)),
      GoRoute(
        path: '/legal/:doc',
        builder: (_, state) => LegalScreen(doc: LegalDoc.values.firstWhere((d) => d.name == state.pathParameters['doc'], orElse: () => LegalDoc.privacy)),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
