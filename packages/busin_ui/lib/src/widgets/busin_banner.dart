import 'package:flutter/material.dart';

import '../painters/contour.dart';
import '../painters/grain.dart';
import '../painters/marked_text.dart';
import '../tokens/elevation.dart';
import '../tokens/palette.dart';
import '../tokens/ramps.dart';
import '../tokens/shape.dart';
import 'illustration.dart';

/// The page's opening statement, the portal's welcome banner on a phone: the brand teal with fine grain, a small line
/// above, a headline with the orange marker under it, a sentence below, 3D art that overflows the right and bottom edges
/// (the banner clips it), and the stitched thread inside. It is the same in light and dark: the banner is always teal.
/// It grows with its words and never gets shorter than [minHeight].
class BusinBanner extends StatelessWidget {
  const BusinBanner({super.key, required this.title, this.eyebrow, this.body, this.art, this.minHeight = 188, this.child, this.trailing});

  final String title;

  /// A small line above the headline: a date, a place.
  final String? eyebrow;
  final String? body;
  final BusinIllustration? art;
  final double minHeight;

  /// Anything extra under the words (a chip, a row of facts).
  final Widget? child;

  /// A small control in the top right corner (the person's avatar, opening their profile).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const radius = BorderRadius.all(Radius.circular(BusinRadius.lg));
    return DecoratedBox(
      decoration: const BoxDecoration(borderRadius: radius, boxShadow: BusinElevation.float),
      child: ClipRRect(
        borderRadius: radius,
        child: ColoredBox(
          color: BusinRamps.seed,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Stack(
              children: [
                const Positioned.fill(child: Grain(opacity: 1)),
                Positioned.fill(child: Contour(color: Colors.white.withValues(alpha: 0.26), style: ContourStyle.banner)),
                // The art is drawn over the thread, so the stitching passes behind it.
                if (art != null) Positioned(right: -36, bottom: -30, child: Illustration(art!, width: 168, height: 168)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(BusinSpace.x6, BusinSpace.x6, BusinSpace.x6, BusinSpace.x6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (eyebrow != null) ...[
                        Padding(
                          padding: EdgeInsets.only(right: trailing != null ? 52 : 0),
                          child: Text(eyebrow!, style: text.labelLarge?.copyWith(color: Colors.white.withValues(alpha: 0.7))),
                        ),
                        const SizedBox(height: BusinSpace.x2),
                      ],
                      // Leave room for the art on the right.
                      Padding(
                        padding: EdgeInsets.only(right: art != null ? 56 : 0),
                        child: MarkedText(title, opacity: 0.7, style: text.headlineMedium?.copyWith(color: Colors.white, height: 1.15)),
                      ),
                      if (body != null) ...[
                        const SizedBox(height: BusinSpace.x3),
                        Padding(
                          padding: EdgeInsets.only(right: art != null ? 56 : 0),
                          child: Text(body!, style: text.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
                        ),
                      ],
                      if (child != null) ...[const SizedBox(height: BusinSpace.x4), child!],
                    ],
                  ),
                ),
                if (trailing != null) Positioned(top: BusinSpace.x4, right: BusinSpace.x4, child: trailing!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The colour pair the banner's words are drawn in, so screens that put their own text on it match.
class BannerInk {
  const BannerInk._();

  static const Color strong = Colors.white;
  static Color get soft => Colors.white.withValues(alpha: 0.85);
  static Color get faint => Colors.white.withValues(alpha: 0.7);
  static Color get thread => Colors.white.withValues(alpha: 0.26);
  static Color get ground => BusinRamps.seed;
  static Color get accent => BusinPalette.orange;
}
