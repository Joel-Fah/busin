import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth/access.dart';
import 'providers.dart';
import 'screens/blocked_screen.dart';
import 'screens/bus_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_shell.dart';
import 'screens/problem_screen.dart';
import 'screens/qr_screen.dart';
import 'screens/subscription_screen.dart';
import 'styleguide/styleguide_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/splash_screen.dart';

abstract final class Routes {
  static const signIn = '/sign-in';
  static const loading = '/loading';
  static const blocked = '/blocked';
  static const problem = '/problem';
  static const subscription = '/subscription';
  static const qr = '/qr';
  static const history = '/history';
  static const bus = '/bus';

  /// Debug builds only: the design language on a screen (`fvm flutter run --route /styleguide`).
  static const styleguide = '/styleguide';

  static const _gate = {signIn, loading, blocked, problem};
}

/// Where a person at [location] should be, given what the app may show. Null means stay.
///
/// Signed-out people see only sign-in; anyone the server does not allow sees only the page that says why.
/// Signed-in students never see those pages, so Back cannot lead to them.
String? redirectFor(AccessState access, String location, {bool debug = kDebugMode}) {
  // The styleguide needs no account, and exists only in debug builds.
  if (debug && location == Routes.styleguide) return null;
  final target = switch (access) {
    SignedOut() => Routes.signIn,
    AccessLoading() => Routes.loading,
    AccessLoadFailed() => Routes.problem,
    Blocked() => Routes.blocked,
    Allowed() => null,
  };
  if (target != null) return location == target ? null : target;
  return Routes._gate.contains(location) || location == '/' ? Routes.subscription : null;
}

final routerProvider = Provider<GoRouter>((ref) {
  // The router re-checks its redirect whenever the access state changes.
  final changes = ValueNotifier<AccessState>(ref.read(accessProvider));
  ref.listen(accessProvider, (_, next) => changes.value = next);
  ref.onDispose(changes.dispose);

  final router = GoRouter(
    initialLocation: kDebugMode && WidgetsBinding.instance.platformDispatcher.defaultRouteName == Routes.styleguide ? Routes.styleguide : Routes.loading,
    refreshListenable: changes,
    redirect: (context, state) => redirectFor(ref.read(accessProvider), state.matchedLocation),
    routes: [
      GoRoute(path: Routes.loading, builder: (_, _) => const SplashScreen()),
      if (kDebugMode) GoRoute(path: Routes.styleguide, builder: (_, _) => const StyleguideScreen()),
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(path: Routes.blocked, builder: (_, _) => const BlockedScreen()),
      GoRoute(path: Routes.problem, builder: (_, _) => const ProblemScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: Routes.subscription, builder: (_, _) => const SubscriptionScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.qr, builder: (_, _) => const QrScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.history, builder: (_, _) => const HistoryScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.bus, builder: (_, _) => const BusScreen())]),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
