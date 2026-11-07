import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../offline/offline_banner.dart';
import '../offline/offline_binder.dart';
import '../push/push_binder.dart';
import '../router.dart';
import '../subscription/live_changes.dart';
import '../subscription/subscription_providers.dart';

/// The signed-in student's frame: four destinations. On a phone or a portrait tablet a floating glass bar rides over
/// the page; on a wide screen (a tablet in landscape) a slim rail sits at the left. Each destination keeps its own
/// place when you switch away and back. The page inside learns how much room the bar takes from [BusinScope].
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _subscriptionBranch = 0;
  static const _qrBranch = 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    // The short label sits under the icon; the full name is what a screen reader says.
    final destinations = [
      BusinDestination(label: l10n.navSubscription, icon: HugeIcons.strokeRoundedTicket03),
      BusinDestination(label: l10n.navQrShort, icon: HugeIcons.strokeRoundedQrCode, semanticLabel: l10n.navQr),
      BusinDestination(label: l10n.navBus, icon: HugeIcons.strokeRoundedBus01),
      BusinDestination(label: l10n.navProfile, icon: HugeIcons.strokeRoundedUser),
    ];

    // The main tab is where the student lands: the code for someone with a subscription, the subscription otherwise.
    final landing = ref.watch(landingPathProvider).value;
    final home = landing == Routes.qr ? _qrBranch : _subscriptionBranch;

    // A Scaffold stays at the root: snack bars need one to appear in.
    return Scaffold(
      backgroundColor: p.bg,
      // Back from any other tab goes to the main tab first; only from the main tab does it leave the app.
      body: PopScope(
        canPop: shell.currentIndex == home,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) shell.goBranch(home);
        },
        child: AdaptiveScaffold(
          destinations: destinations,
          currentIndex: shell.currentIndex,
          onDestinationSelected: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
          railHeader: BrandMark(color: p.fg, height: 28),
          // The profile is the last destination: on the rail it sits at the bottom end.
          pinLastToRailEnd: true,
          body: OfflineBinder(
            child: SubscriptionLiveBinder(
              child: PushBinder(
                // The notice sits above whichever tab is showing; it takes no room while everything is fresh.
                child: SafeArea(bottom: false, child: Column(children: [const OfflineBanner(), Expanded(child: shell)])),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
