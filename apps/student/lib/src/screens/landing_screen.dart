import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../subscription/subscription_providers.dart';
import 'splash_screen.dart';

/// Shown for a moment after sign-in or opening the app: it finds out whether the student already has an approved
/// subscription and sends them to the boarding code (what they need at the door) or to the subscription tab.
class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final landing = ref.watch(landingPathProvider);
    final path = landing.value;
    if (path != null) {
      // After this frame: the router cannot be moved while the tree is building.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(path);
      });
    }
    return const SplashScreen();
  }
}
