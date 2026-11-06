import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/breakpoints.dart';
import '../tokens/shape.dart';
import 'nav.dart';

/// What the scaffold tells the screens inside it: which layout is in use, and how much room the floating bar takes at
/// the bottom (so a scrolling list can end clear of it instead of hiding behind it).
class BusinScope extends InheritedWidget {
  const BusinScope({super.key, required this.layout, required this.bottomInset, required super.child});

  final BusinLayout layout;

  /// Space to leave at the bottom of scrollable content: the bar, its margins and the system inset. Zero with a rail.
  final double bottomInset;

  /// The scope above [context], or one derived from the window if there is none (a screen shown alone, in a test).
  static BusinScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BusinScope>() ?? BusinScope(layout: BusinLayout.of(context), bottomInset: 0, child: const SizedBox.shrink());

  @override
  bool updateShouldNotify(BusinScope old) => old.layout != layout || old.bottomInset != bottomInset;
}

/// The frame of the signed-in app. On phones and portrait tablets, the page fills the screen and a floating bar rides
/// over it (hiding while the keyboard is open). On wide screens, such as a tablet in landscape, a slim rail sits at the
/// left and the page uses the rest. Screens inside read [BusinScope] to know which one they are in.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.body,
    this.railHeader,
  });

  final List<BusinDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  /// The brand mark shown on top of the rail.
  final Widget? railHeader;

  /// Space around the floating bar.
  static const double barMargin = 16;

  @override
  Widget build(BuildContext context) {
    final layout = BusinLayout.of(context);
    final media = MediaQuery.of(context);
    final bg = Theme.of(context).scaffoldBackgroundColor;

    if (layout.isExpanded) {
      return Material(
        color: bg,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(BusinSpace.x3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BusinNavRail(destinations: destinations, currentIndex: currentIndex, onSelected: onDestinationSelected, header: railHeader),
                const SizedBox(width: BusinSpace.x3),
                Expanded(child: BusinScope(layout: layout, bottomInset: 0, child: body)),
              ],
            ),
          ),
        ),
      );
    }

    final safeBottom = math.max(media.viewPadding.bottom, 0.0);
    final keyboardOpen = media.viewInsets.bottom > 0;
    final bottomInset = FloatingNavBar.height + barMargin * 2 + safeBottom;

    // Its own Material, so the bar's ink effects work wherever the scaffold is placed.
    return Material(
      color: bg,
      child: Stack(
        children: [
          Positioned.fill(child: BusinScope(layout: layout, bottomInset: bottomInset, child: body)),
          Positioned(
            left: barMargin,
            right: barMargin,
            bottom: barMargin + safeBottom,
            child: AnimatedSlide(
              offset: keyboardOpen ? const Offset(0, 2) : Offset.zero,
              duration: BusinMotion.of(context, BusinMotion.normal),
              curve: BusinMotion.soft,
              child: AnimatedOpacity(
                opacity: keyboardOpen ? 0 : 1,
                duration: BusinMotion.of(context, BusinMotion.fast),
                child: IgnorePointer(
                  ignoring: keyboardOpen,
                  child: Center(
                    // Wider screens in portrait keep the bar a sensible size instead of stretching it edge to edge.
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 448),
                      child: FloatingNavBar(destinations: destinations, currentIndex: currentIndex, onSelected: onDestinationSelected),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A reading column: full width on a phone, centred and capped around 640 on bigger screens so lines stay short.
class ContentColumn extends StatelessWidget {
  const ContentColumn({super.key, required this.child, this.maxWidth = BusinLayout.maxColumn});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}

/// Two panes side by side when there is room (a tablet in landscape), one when there is not. When there is no room,
/// [secondary] is either dropped or, with [stackBelow], shown under [primary].
class SplitView extends StatelessWidget {
  const SplitView({super.key, required this.primary, required this.secondary, this.primaryFlex = 5, this.secondaryFlex = 4, this.gap = BusinSpace.x4, this.stackBelow = false});

  final Widget primary;
  final Widget secondary;
  final int primaryFlex;
  final int secondaryFlex;
  final double gap;
  final bool stackBelow;

  /// Both panes need at least this much width to sit side by side.
  static const double twoPaneFrom = 680;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= twoPaneFrom) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: primaryFlex, child: primary),
                SizedBox(width: gap),
                Expanded(flex: secondaryFlex, child: secondary),
              ],
            );
          }
          if (!stackBelow) return primary;
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [primary, SizedBox(height: gap), secondary]);
        },
      );
}
