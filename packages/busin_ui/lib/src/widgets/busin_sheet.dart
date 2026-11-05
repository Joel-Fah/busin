import 'package:flutter/material.dart';

import '../painters/contour.dart';
import '../tokens/elevation.dart';
import '../tokens/palette.dart';
import '../tokens/shape.dart';

/// Opens a bottom sheet in the BusIn style: a 36 px top corner, the stitched thread, a drag handle, and a floating
/// shadow. Sheets are for choices and details that do not deserve a new screen (a stop, a photo source).
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
    builder: (context) => BusinSheetFrame(child: builder(context)),
  );
}

/// The look of a sheet: use [showBusinSheet]; this is public so a screen can preview it.
class BusinSheetFrame extends StatelessWidget {
  const BusinSheetFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    const radius = BorderRadius.vertical(top: Radius.circular(BusinRadius.xl));
    return Padding(
      // A little room at the sides so it floats, like the portal's sheets.
      padding: const EdgeInsets.fromLTRB(BusinSpace.x2, 0, BusinSpace.x2, 0),
      child: DecoratedBox(
        decoration: const BoxDecoration(borderRadius: radius, boxShadow: BusinElevation.float),
        child: Material(
          color: p.surface,
          shape: const RoundedRectangleBorder(borderRadius: radius),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: BusinSpace.x3),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: BusinSpace.x2),
                  Flexible(child: child),
                ],
              ),
              Positioned.fill(child: Contour(color: threadColor(text: p.fg, background: p.surface, mix: 0.16), style: ContourStyle.sheet)),
            ],
          ),
        ),
      ),
    );
  }
}
