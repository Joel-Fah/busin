import 'package:flutter/material.dart';

import '../painters/contour.dart';
import '../tokens/elevation.dart';
import '../tokens/palette.dart';
import '../tokens/shape.dart';

/// Opens a sheet in the BusIn style: a card that floats above the page with space on every side (it never touches the
/// screen's edge), every corner rounded, the stitched thread inside it, and a single grab handle *outside* it, above
/// the card. Sheets are for choices and details that do not deserve a new screen (a stop, a photo source). It opens on
/// the root navigator, so it sits above the floating navigation bar.
Future<T?> showBusinSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    elevation: 0,
    useSafeArea: true,
    // The root navigator, so the sheet is above the floating bar (the bar lives inside the page).
    useRootNavigator: true,
    // The frame draws its own handle, outside the card.
    showDragHandle: false,
    builder: (context) => BusinSheetFrame(child: builder(context)),
  );
}

/// The look of a sheet: use [showBusinSheet]; this is public so a screen can preview it.
class BusinSheetFrame extends StatelessWidget {
  const BusinSheetFrame({super.key, required this.child});

  final Widget child;

  /// Space between the card and the screen's edges.
  static const double margin = 16;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    const radius = BorderRadius.all(Radius.circular(BusinRadius.xl));
    return Padding(
      padding: const EdgeInsets.fromLTRB(margin, 0, margin, margin),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The handle sits on the dimmed page above the card, not inside it.
          Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: BusinSpace.x2),
          Flexible(
            child: DecoratedBox(
              decoration: const BoxDecoration(borderRadius: radius, boxShadow: BusinElevation.float),
              child: Material(
                color: p.surface,
                shape: const RoundedRectangleBorder(borderRadius: radius),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Padding(padding: const EdgeInsets.only(top: BusinSpace.x2), child: child),
                    Positioned.fill(child: Contour(color: threadColor(text: p.fg, background: p.surface, mix: 0.16), style: ContourStyle.sheet)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
