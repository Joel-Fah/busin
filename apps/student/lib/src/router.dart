import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth/access.dart';
import 'legal/legal_documents.dart';
import 'legal/legal_screen.dart';
import 'providers.dart';
import 'screens/blocked_screen.dart';
import 'screens/bus_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_shell.dart';
import 'screens/landing_screen.dart';
import 'screens/problem_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/setup_screen.dart';
import 'join/choose_school_screen.dart';
import 'join/waiting_school_screen.dart';
import 'area/area_screen.dart';
import 'reminders/notifications_screen.dart';
import 'screens/qr_screen.dart';
import 'screens/subscription_screen.dart';
import 'styleguide/qr_preview.dart';
import 'styleguide/styleguide_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/splash_screen.dart';

abstract final class Routes {
  static const signIn = '/sign-in';
  static const loading = '/loading';
  static const blocked = '/blocked';
  static const problem = '/problem';
  static const setup = '/setup';
  static const join = '/join';
  static const waiting = '/waiting';

  /// Where an allowed student arrives: it looks up whether they have an approved subscription and moves on to the
  /// boarding code or the subscription tab.
  static const start = '/start';
  static const profile = '/profile';
  static const subscription = '/subscription';
  static const qr = '/qr';
  static const history = '/history';
  static const notifications = '/notifications';
  static const area = '/area';
  static const legal = '/legal';

  /// The page of one legal document.
  static String legalFor(LegalDoc doc) => '$legal/${doc.name}';
  static const bus = '/bus';

  /// Debug builds only: the design language on a screen (`fvm flutter run --route /styleguide`).
  static const styleguide = '/styleguide';

  /// Debug builds only: the first-run screens, previewed without signing out (`--route /styleguide/sign-in`).
  static const previewPrefix = '/styleguide/';

  static const _gate = {signIn, loading, blocked, problem, setup, join, waiting};
}

/// Where a person at [location] should be, given what the app may show. Null means stay.
///
/// Signed-out people see only sign-in; anyone the server does not allow sees only the page that says why.
/// Signed-in students never see those pages, so Back cannot lead to them.
String? redirectFor(AccessState access, String location, {bool debug = kDebugMode, bool introDone = true}) {
  // The styleguide needs no account, and exists only in debug builds.
  if (debug && (location == Routes.styleguide || location.startsWith(Routes.previewPrefix))) return null;
  // The opening animation plays first, on the splash screen, whatever the session turns out to be.
  if (!introDone) return location == Routes.loading ? null : Routes.loading;
  final target = switch (access) {
    SignedOut() => Routes.signIn,
    AccessLoading() => Routes.loading,
    AccessLoadFailed() => Routes.problem,
    Blocked() => Routes.blocked,
    NeedsSchool() => Routes.join,
    AwaitingSchool() => Routes.waiting,
    NeedsSetup() => Routes.setup,
    Allowed() => null,
  };
  if (target != null) return location == target ? null : target;
  return Routes._gate.contains(location) || location == '/' ? Routes.start : null;
}

final routerProvider = Provider<GoRouter>((ref) {
  // The router re-checks its redirect whenever the access state changes.
  final changes = ValueNotifier<int>(0);
  ref.listen(accessProvider, (_, _) => changes.value++);
  ref.listen(introDoneProvider, (_, _) => changes.value++);
  ref.onDispose(changes.dispose);

  final router = GoRouter(
    initialLocation: kDebugMode && WidgetsBinding.instance.platformDispatcher.defaultRouteName.startsWith(Routes.styleguide) ? WidgetsBinding.instance.platformDispatcher.defaultRouteName : Routes.loading,
    refreshListenable: changes,
    redirect: (context, state) =>
        redirectFor(ref.read(accessProvider), state.matchedLocation, introDone: ref.read(introDoneProvider)),
    routes: [
      GoRoute(path: Routes.loading, builder: (_, _) => const SplashScreen()),
      if (kDebugMode) ...[
        GoRoute(path: Routes.styleguide, builder: (_, _) => const StyleguideScreen()),
        GoRoute(path: '${Routes.previewPrefix}sign-in', builder: (_, _) => const SignInScreen()),
        GoRoute(path: '${Routes.previewPrefix}splash', builder: (_, _) => const SplashScreen()),
        GoRoute(path: '${Routes.previewPrefix}blocked', builder: (_, _) => const BlockedScreen()),
        GoRoute(path: '${Routes.previewPrefix}problem', builder: (_, _) => const ProblemScreen()),
        GoRoute(path: '${Routes.previewPrefix}qr', builder: (_, _) => const QrPreviewScreen()),
      ],
      // No slide: the splash and this screen share the seed colour and the mark, so the swap is invisible and the mark
      // then travels to its corner by itself.
      GoRoute(path: Routes.signIn, pageBuilder: (_, state) => NoTransitionPage(key: state.pageKey, child: const SignInScreen())),
      GoRoute(path: Routes.blocked, builder: (_, _) => const BlockedScreen()),
      GoRoute(path: Routes.problem, builder: (_, _) => const ProblemScreen()),
      GoRoute(path: Routes.setup, builder: (_, _) => const SetupScreen()),
      GoRoute(path: Routes.join, builder: (_, _) => const ChooseSchoolScreen()),
      GoRoute(path: Routes.waiting, builder: (_, _) => const WaitingSchoolScreen()),
      GoRoute(path: Routes.start, builder: (_, _) => const LandingScreen()),
      GoRoute(path: Routes.history, builder: (_, _) => const HistoryPage()),
      GoRoute(path: Routes.notifications, builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: Routes.area, builder: (_, _) => const MyAreaScreen()),
      GoRoute(
        path: '${Routes.legal}/:doc',
        builder: (_, state) {
          final doc = LegalDoc.values.where((d) => d.name == state.pathParameters['doc']).firstOrNull;
          return doc == null ? const HistoryPage() : LegalPage(doc: doc);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: Routes.subscription, builder: (_, _) => const SubscriptionScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.qr, builder: (_, _) => const QrScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.bus, builder: (_, _) => const BusScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen())]),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
