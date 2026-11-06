import 'package:flutter/material.dart';
import '../brand/brand_intro.dart';
import '../brand/brand_paths.dart';

/// The 3D illustrations (the same set as the portal), used where they carry meaning: an empty state, a hero.
enum BusinIllustration {
  bus('bus'),
  busLarge('bus-large'),
  busStop('bus-stop'),
  ticket('ticket1'),
  papers('papers'),
  verified('verified'),
  waiting('waiting'),
  blocked('blocked'),
  semester('semester'),
  seat('seat'),
  staff('staff');

  const BusinIllustration(this.file);

  final String file;
  String get asset => 'assets/illustrations/$file.webp';
}

/// An illustration, decorative: hidden from screen readers (the words around it say what it says).
class Illustration extends StatelessWidget {
  const Illustration(this.art, {super.key, this.width, this.height, this.fit = BoxFit.contain, this.alignment = Alignment.center});

  final BusinIllustration art;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Image.asset(
        art.asset,
        package: 'busin_ui',
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
        gaplessPlayback: true,
      );
}

/// The BusIn wordmark in one colour. Never stretch it: give a height and it keeps its proportions (205 by 126).
///
/// It is painted from the same shapes the opening animation draws, so the finished animation and this mark are the same
/// picture. (Recolouring the SVG with a colour filter came out in the SVG's own dark teal on the dev tablet, which made
/// the mark vanish on the dark loading screen.)
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, required this.color, this.height = 32, this.semanticLabel});

  final Color color;
  final double height;

  /// Give a label only where the mark stands alone; next to the word "BusIn" leave it out.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final mark = CustomPaint(
      size: Size(height * brandWidth / brandHeight, height),
      painter: BrandIntroPainter(frame: finishedBrandFrame, color: color),
    );
    return semanticLabel == null ? ExcludeSemantics(child: mark) : Semantics(label: semanticLabel, image: true, child: ExcludeSemantics(child: mark));
  }
}
