import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../push/push_binder.dart';

/// The signed-in student's frame: four destinations along the bottom. Each keeps its own place when you
/// switch away and back.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    return PushBinder(
      child: Scaffold(
      body: SafeArea(bottom: false, child: shell),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
        destinations: [
          NavigationDestination(icon: const HugeIcon(icon: HugeIcons.strokeRoundedTicket03), label: l10n.navSubscription),
          NavigationDestination(icon: const HugeIcon(icon: HugeIcons.strokeRoundedQrCode), label: l10n.navQr),
          NavigationDestination(icon: const HugeIcon(icon: HugeIcons.strokeRoundedReceiptText), label: l10n.navHistory),
          NavigationDestination(icon: const HugeIcon(icon: HugeIcons.strokeRoundedBus01), label: l10n.navBus),
        ],
      ),
      ),
    );
  }
}
