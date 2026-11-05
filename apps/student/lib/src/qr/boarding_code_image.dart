import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// The boarding code as a QR image: round dots in the brand's deep teal on white, in both themes (the contrast is
/// about 14 to 1, and scanners need a light ground). The error correction is high enough for round dots to read well.
class BoardingCodeImage extends StatelessWidget {
  const BoardingCodeImage({super.key, required this.data, required this.size});

  /// The code text, `busin1.<student>.<window>.<mac>`.
  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data: data,
      size: size,
      padding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: BusinRamps.seed),
      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: BusinRamps.seed),
      errorCorrectionLevel: QrErrorCorrectLevel.Q,
    );
  }
}
