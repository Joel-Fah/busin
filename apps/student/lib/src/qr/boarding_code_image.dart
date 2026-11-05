import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// The boarding code as a QR image. Always dark on white, in both themes: scanners need the contrast.
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
      backgroundColor: Colors.white,
      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
  }
}
