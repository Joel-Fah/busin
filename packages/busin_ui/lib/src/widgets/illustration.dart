import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, required this.color, this.height = 32, this.semanticLabel});

  final Color color;
  final double height;

  /// Give a label only where the mark stands alone; next to the word "BusIn" leave it out.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        'assets/brand/wordmark.svg',
        package: 'busin_ui',
        height: height,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        semanticsLabel: semanticLabel,
        excludeFromSemantics: semanticLabel == null,
      );
}
