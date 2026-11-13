import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'push/push_binder.dart';

/// The signed-in staff member's frame: Trips (today and the weeks ahead), History, Stats and Profile. On a phone a
/// floating bar rides over the page; on a wide screen (a tablet in landscape) a slim rail sits at the left. Each tab keeps
/// its place when you switch away and back. The page learns how much room the bar takes from [BusinScope].
class OpsShell extends StatelessWidget {
  const OpsShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const tripsBranch = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final destinations = [
      BusinDestination(label: l10n.navTrips, icon: HugeIcons.strokeRoundedBus01),
      BusinDestination(label: l10n.navHistory, icon: HugeIcons.strokeRoundedCalendar03),
      BusinDestination(label: l10n.navStats, icon: HugeIcons.strokeRoundedAnalytics01),
      BusinDestination(label: l10n.navProfile, icon: HugeIcons.strokeRoundedUser),
    ];
    // A Scaffold stays at the root: snack bars need one to appear in.
    return Scaffold(
      backgroundColor: p.bg,
      // Back from any other tab goes to Trips first; only from Trips does it leave the app.
      body: PopScope(
        canPop: shell.currentIndex == tripsBranch,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) shell.goBranch(tripsBranch);
        },
        child: AdaptiveScaffold(
          destinations: destinations,
          currentIndex: shell.currentIndex,
          onDestinationSelected: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
          railHeader: BrandMark(color: p.fg, height: 28),
          pinLastToRailEnd: true,
          // Notifications are connected only while someone is signed in, which is when these tabs exist.
          body: OpsPushBinder(child: shell),
        ),
      ),
    );
  }
}
