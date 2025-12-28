import 'dart:async';
import 'package:busin/controllers/auth_controller.dart';
import 'package:busin/controllers/onboarding_controller.dart';
import 'package:busin/docs/docs.dart';
import 'package:busin/models/actors/roles.dart';
import 'package:busin/ui/screens/home/home_tab.dart';
import 'package:busin/ui/screens/home/scanner.dart';
import 'package:busin/ui/screens/home/scannings_tab.dart';
import 'package:busin/ui/screens/home/subscriptions_tab.dart';
import 'package:busin/ui/screens/onboarding/verification.dart';
import 'package:busin/ui/screens/profile/account_info.dart';
import 'package:busin/ui/screens/profile/appearance.dart';
import 'package:busin/ui/screens/profile/legal.dart';
import 'package:busin/ui/screens/profile/profile.dart';
import 'package:busin/ui/screens/profile/semesters/semester.dart';
import 'package:busin/ui/screens/profile/semesters/semester_form.dart';
import 'package:busin/ui/screens/profile/stops/stops.dart';
import 'package:busin/ui/screens/profile/stops/stops_new.dart';
import 'package:busin/ui/screens/profile/stops/stops_edit.dart';
import 'package:busin/ui/screens/profile/subscriptions_admin.dart';
import 'package:busin/ui/screens/screens.dart';
import 'package:busin/ui/screens/subscriptions/subscription_details.dart';
import 'package:busin/ui/screens/subscriptions/subscription_new.dart';
import 'package:busin/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../api/docs_api.dart';
import '../models/semester_config.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

AuthController get authController => Get.isRegistered<AuthController>()
    ? Get.find<AuthController>()
    : Get.put(AuthController(), permanent: true);

OnboardingController get onboardingController =>
    Get.isRegistered<OnboardingController>()
    ? Get.find<OnboardingController>()
    : Get.put(OnboardingController(), permanent: true);

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class MultiStreamRefresh extends ChangeNotifier {
  MultiStreamRefresh(List<Stream<dynamic>> streams) {
    _subs = streams.map((s) => s.listen((_) => notifyListeners())).toList();
  }

  late final List<StreamSubscription> _subs;

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}

String _computeInitialLocation() {
  final authed = fb_auth.FirebaseAuth.instance.currentUser != null;
  final onboardingDone = onboardingController.shouldSkipOnboarding();
  if (authed) return HomePage.routeName;
  if (onboardingDone) return AnonymousHomePage.routeName;
  return OnboardingPage.routeName;
}

final router = GoRouter(
  debugLogDiagnostics: true,
  navigatorKey: rootNavigatorKey,
  initialLocation: _computeInitialLocation(),
  refreshListenable: MultiStreamRefresh([
    fb_auth.FirebaseAuth.instance.authStateChanges(),
    authController.bootstrappedStream,
  ]),
  redirect: (context, state) {
    final authed = fb_auth.FirebaseAuth.instance.currentUser != null;
    final onboardingDone = onboardingController.shouldSkipOnboarding();
    final loc = state.matchedLocation; // safer than state.uri.toString()

    // 1️⃣ Wait until bootstrap completes
    if (!authController.isBootstrapped) {
      if (loc != LoadingPage.routeName) return LoadingPage.routeName;
      return null;
    }

    // 2️⃣ If we're bootstrapped but *still on the loading page*, route properly now
    if (loc == LoadingPage.routeName) {
      if (authed) {
        final user = authController.currentUser.value;

        // Check if staff/admin user is pending verification
        if (user != null &&
            (user.role.isStaff || user.role.isAdmin) &&
            (user.status.isPending || user.status.isSuspended)) {
          return VerificationPage.routeName;
        }

        return HomePage.routeName;
      }
      if (onboardingDone) return AnonymousHomePage.routeName;
      return OnboardingPage.routeName;
    }

    // 3️⃣ Allow docs pages freely
    if (loc.startsWith(DocsPage.routeName)) return null;

    // 4️⃣ Authenticated user
    if (authed) {
      final user = authController.currentUser.value;

      // Check if staff/admin user is pending verification
      if (user != null &&
          (user.role == UserRole.staff || user.role == UserRole.admin) &&
          user.status == AccountStatus.pending) {
        // Redirect to verification page if not already there
        if (loc != VerificationPage.routeName) {
          return VerificationPage.routeName;
        }
        return null;
      }

      // Keep verified users off verification page
      if (loc == VerificationPage.routeName &&
          user?.status == AccountStatus.verified) {
        return HomePage.routeName;
      }

      // Keep authed users off onboarding/anonymous pages
      if (loc == OnboardingPage.routeName ||
          loc == AnonymousHomePage.routeName) {
        return HomePage.routeName;
      }

      return null; // stay where they are
    }

    // 5️⃣ Anonymous user
    if (onboardingDone) {
      final isProtected =
          loc.startsWith(HomePage.routeName) ||
          loc.startsWith(SubscriptionDetailsPage.routeName);
      if (isProtected) return AnonymousHomePage.routeName;
      return null;
    }

    // 6️⃣ Onboarding users
    if (loc != OnboardingPage.routeName) return OnboardingPage.routeName;

    return null;
  },
  routes: [
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: LoadingPage.routeName,
      name: removeLeadingSlash(LoadingPage.routeName),
      builder: (context, state) => const LoadingPage(),
    ),
    // Onboarding & Docs
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: OnboardingPage.routeName,
      name: removeLeadingSlash(OnboardingPage.routeName),
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: VerificationPage.routeName,
      name: removeLeadingSlash(VerificationPage.routeName),
      builder: (context, state) => const VerificationPage(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: DocsPage.routeName + '/:topic' + '/:baseUrl',
      name: removeLeadingSlash(DocsPage.routeName),
      builder: (context, state) {
        final topic = state.pathParameters['topic'];
        final baseUrl = state.pathParameters['baseUrl'] ?? '';
        return DocsPage(
          topic: topic == 'student' ? DocsTopic.student : DocsTopic.admin,
          baseUrl: baseUrl,
        );
      },
    ),

    // Home
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AnonymousHomePage.routeName,
      name: removeLeadingSlash(AnonymousHomePage.routeName),
      builder: (context, state) => const AnonymousHomePage(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: HomePage.routeName,
      name: removeLeadingSlash(HomePage.routeName),
      builder: (context, state) => const HomePage(),
    ),
    ShellRoute(
      navigatorKey: rootNavigatorKey,
      parentNavigatorKey: rootNavigatorKey,
      routes: [
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: HomeTab.routeName,
          name: removeLeadingSlash(HomeTab.routeName),
          builder: (context, state) => const HomeTab(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: SubscriptionsTab.routeName,
          name: removeLeadingSlash(SubscriptionsTab.routeName),
          builder: (context, state) => const SubscriptionsTab(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: ScanningsTab.routeName,
          name: removeLeadingSlash(ScanningsTab.routeName),
          builder: (context, state) => const ScanningsTab(),
        ),
      ],
    ),

    // Subscriptions
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: "${SubscriptionDetailsPage.routeName}/:subscriptionId",
      name: removeLeadingSlash(SubscriptionDetailsPage.routeName),
      builder: (context, state) {
        final subscriptionId = state.pathParameters['subscriptionId']!;
        return SubscriptionDetailsPage(subscriptionId: subscriptionId);
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: NewSubscriptionPage.routeName,
      name: removeLeadingSlash(NewSubscriptionPage.routeName),
      builder: (context, state) => NewSubscriptionPage(),
    ),

    // Profile
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: ProfilePage.routeName + '/:tag',
      name: removeLeadingSlash(ProfilePage.routeName),
      builder: (context, state) {
        final tag = state.pathParameters['tag'];
        return ProfilePage(tag: tag ?? '');
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AccountInfoPage.routeName,
      name: removeLeadingSlash(AccountInfoPage.routeName),
      builder: (context, state) => const AccountInfoPage(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppearancePage.routeName,
      name: removeLeadingSlash(AppearancePage.routeName),
      builder: (context, state) => const AppearancePage(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: LegalPage.routeName,
      name: removeLeadingSlash(LegalPage.routeName),
      builder: (context, state) => const LegalPage(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: BusStopsManagementPage.routeName,
      name: removeLeadingSlash(BusStopsManagementPage.routeName),
      builder: (context, state) => const BusStopsManagementPage(),
      routes: [
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: NewStopPage.routeName,
          name: removeLeadingSlash(NewStopPage.routeName),
          builder: (context, state) => const NewStopPage(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: EditStopPage.routeName + '/:stopId',
          name: removeLeadingSlash(EditStopPage.routeName),
          builder: (context, state) {
            final stopId = state.pathParameters['stopId']!;
            return EditStopPage(stopId: stopId);
          },
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: SemesterManagementPage.routeName,
      name: removeLeadingSlash(SemesterManagementPage.routeName),
      builder: (context, state) => const SemesterManagementPage(),
      routes: [
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: SemesterFormPage.routeName,
          name: removeLeadingSlash(SemesterFormPage.routeName),
          builder: (context, state) {
            final semester = state.extra as SemesterConfig?;
            return SemesterFormPage(semester: semester);
          },
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: SubscriptionsAdminPage.routeName,
      name: removeLeadingSlash(SubscriptionsAdminPage.routeName),
      builder: (context, state) => const SubscriptionsAdminPage(),
    ),

    // Scanner
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: ScannerPage.routeName,
      name: removeLeadingSlash(ScannerPage.routeName),
      builder: (context, state) => const ScannerPage(),
    ),
  ],
);
