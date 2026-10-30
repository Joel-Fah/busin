import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Generates the rotating boarding code.
///
/// Format: `busin1.<student uuid>.<window>.<mac>` where `window` is
/// `floor(unix seconds / 30)` and `mac` is the first 20 hex characters of
/// `HMAC-SHA256(key = secret, message = "<student uuid>:<window>")`.
/// The server checks it in `record_qr_scan`. See docs/guides/qr-code-format.md.
class QrCodeGenerator {
  const QrCodeGenerator._();

  static const String version = 'busin1';
  static const int windowSeconds = 30;
  static const int macLength = 20;

  /// The 30-second window that contains [at].
  static int windowFor(DateTime at) =>
      at.millisecondsSinceEpoch ~/ 1000 ~/ windowSeconds;

  /// The signature for [studentId] in [window].
  static String mac({
    required Uint8List secret,
    required String studentId,
    required int window,
  }) {
    final digest =
        Hmac(sha256, secret).convert(utf8.encode('$studentId:$window'));
    return digest.toString().substring(0, macLength);
  }

  /// The code to show at [now].
  static String generate({
    required Uint8List secret,
    required String studentId,
    required DateTime now,
  }) {
    final window = windowFor(now);
    final signature = mac(secret: secret, studentId: studentId, window: window);
    return '$version.$studentId.$window.$signature';
  }

  /// Decodes the base64 secret returned by `get_my_qr_secret`.
  static Uint8List decodeSecret(String base64Secret) {
    final bytes = base64.decode(base64Secret);
    if (bytes.length != 32) {
      throw FormatException('The secret must be 32 bytes, got ${bytes.length}');
    }
    return Uint8List.fromList(bytes);
  }

  /// Seconds left before the code made at [now] is replaced.
  static int secondsRemaining(DateTime now) =>
      windowSeconds - (now.millisecondsSinceEpoch ~/ 1000 % windowSeconds);
}
