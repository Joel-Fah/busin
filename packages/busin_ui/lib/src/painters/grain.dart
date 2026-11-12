import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Fine grain over a surface, the portal's `texture-grain`: a small noise picture tiled across the area and blended
/// in softly (soft-light) at [opacity]. Decoration for banners and feature cards only. It must never sit behind forms,
/// tables or small text, and it takes no pointer events. Place it with `Positioned.fill` in a `Stack`, above the
/// background and below the content, inside the clip of the surface it decorates.
class Grain extends StatefulWidget {
  const Grain({super.key, this.opacity = 0.8});

  /// How strong it is; the portal uses 0.5 to 1.
  final double opacity;

  @override
  State<Grain> createState() => _GrainState();
}

class _GrainState extends State<Grain> {
  // One decode for the whole app: every grain uses the same picture.
  static Future<ui.Image>? _loading;

  static Future<ui.Image> _load() => _loading ??= () async {
        final data = await rootBundle.load('packages/busin_ui/assets/textures/grain.png');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        return (await codec.getNextFrame()).image;
      }();

  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _load().then((image) {
      if (mounted) setState(() => _image = image);
    }).catchError((Object _) {
      // No grain is better than no screen.
    });
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: ExcludeSemantics(
        child: CustomPaint(
          painter: GrainPainter(image: image, opacity: widget.opacity, pixelRatio: MediaQuery.devicePixelRatioOf(context)),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class GrainPainter extends CustomPainter {
  const GrainPainter({required this.image, required this.opacity, required this.pixelRatio});

  final ui.Image image;
  final double opacity;
  final double pixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    // The layer carries the strength and the blend, the shader carries the noise.
    canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.softLight..color = Color.fromRGBO(255, 255, 255, opacity.clamp(0, 1)));
    // One picture pixel per screen pixel, so the grain stays fine on every density.
    final scale = 1 / pixelRatio;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = ImageShader(image, TileMode.repeated, TileMode.repeated, Matrix4.diagonal3Values(scale, scale, 1).storage)
        ..filterQuality = FilterQuality.low,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(GrainPainter old) => old.image != image || old.opacity != opacity || old.pixelRatio != pixelRatio;
}
