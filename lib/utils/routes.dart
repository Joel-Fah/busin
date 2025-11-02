import 'package:busin/docs/docs.dart';
import 'package:busin/ui/screens/screens.dart';
import 'package:busin/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/docs_api.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  debugLogDiagnostics: true,
  navigatorKey: rootNavigatorKey,
  initialLocation: AnonymousHomePage.routeName,
  routes: [
    // Onboarding & Docs
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: OnboardingPage.routeName,
      name: removeLeadingSlash(OnboardingPage.routeName),
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: DocsPage.routeName +
          '/:topic' +
          '/:baseUrl', // baseUrl is optional
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
      path: HomePage.routeName,
      name: removeLeadingSlash(HomePage.routeName),
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AnonymousHomePage.routeName,
      name: removeLeadingSlash(AnonymousHomePage.routeName),
      builder: (context, state) => const AnonymousHomePage(),
    ),
  ],
);
