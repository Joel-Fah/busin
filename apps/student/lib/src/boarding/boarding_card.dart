import 'dart:async';

import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Shows the "on board" card over whatever is on screen, and closes it by itself after a few seconds. [quiet] is for a
/// boarding the app learns about later (the phone was offline at the door): it names the time instead of cheering.
Future<void> showBoardingCard(BuildContext context, {required String title, required String line, Duration stay = const Duration(seconds: 4)}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  var open = true;
  final closer = Timer(stay, () {
    if (open && navigator.mounted) navigator.pop();
  });
  BusinHaptics.medium();
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: BusinL10n.of(context).boardedClose,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, _, _) => BoardingCard(title: title, line: line),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
      return FadeTransition(opacity: animation, child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(curved), child: child));
    },
  );
  open = false;
  closer.cancel();
}

/// A green tick, "On board", and a line that fits the moment.
class BoardingCard extends StatelessWidget {
  const BoardingCard({super.key, required this.title, required this.line});

  final String title;
  final String line;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BusinSpace.x6),
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: BusinCard(
              padding: const EdgeInsets.all(BusinSpace.x6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(color: p.ok, borderRadius: BorderRadius.circular(BusinRadius.lg)),
                    child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedTick02, size: 36, color: Colors.white)),
                  ),
                  const SizedBox(height: BusinSpace.x4),
                  Text(title, style: text.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: BusinSpace.x2),
                  Text(line, style: text.bodyLarge?.copyWith(color: p.muted), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
