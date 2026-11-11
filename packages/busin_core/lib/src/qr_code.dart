import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// The rotating boarding code (ADR 0014).
///
/// Format: `busin2.<student uuid>.<window>.<mac>` where `window` is `floor(unix seconds / 30)` and `mac` is the first
/// 20 hex characters of `HMAC-SHA256(key = day key, message = "<student uuid>:<window>")`. The day key is
/// `HMAC-SHA256(key = secret, message = "busin-day:YYYY-MM-DD")` for the school-local date of the window's start.
/// The student phone holds the secret; a staff phone holds only the day keys of the day. The server checks the code
/// again in `record_qr_scan`. See docs/guides/qr-code-format.md.
class QrCodeGenerator {
  const QrCodeGenerator._();

  static const String version = 'busin2';
  static const int windowSeconds = 30;
  static const int macLength = 20;

  /// The 30-second window that contains [at].
  static int windowFor(DateTime at) => at.millisecondsSinceEpoch ~/ 1000 ~/ windowSeconds;

  /// When [window] starts.
  static DateTime windowStart(int window) => DateTime.fromMillisecondsSinceEpoch(window * windowSeconds * 1000, isUtc: true);

  /// `YYYY-MM-DD` for a calendar date (only its year, month and day are used).
  static String dateLabel(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// The key for one school day, derived from the student's secret.
  static Uint8List dayKey({required Uint8List secret, required DateTime date}) =>
      Uint8List.fromList(Hmac(sha256, secret).convert(utf8.encode('busin-day:${dateLabel(date)}')).bytes);

  /// The signature for [studentId] in [window], with the day key of that window's day.
  static String mac({required Uint8List dayKey, required String studentId, required int window}) {
    final digest = Hmac(sha256, dayKey).convert(utf8.encode('$studentId:$window'));
    return digest.toString().substring(0, macLength);
  }

  /// The code to show at [now]. [schoolDate] turns an instant into the calendar date it is at the school (the
  /// school's time zone, not the phone's).
  static String generate({
    required Uint8List secret,
    required String studentId,
    required DateTime now,
    required DateTime Function(DateTime instant) schoolDate,
  }) {
    final window = windowFor(now);
    final key = dayKey(secret: secret, date: schoolDate(windowStart(window)));
    return '$version.$studentId.$window.${mac(dayKey: key, studentId: studentId, window: window)}';
  }

  /// Decodes a base64 key or secret of 32 bytes (`get_my_qr_secret`, `staff_day_keys`).
  static Uint8List decodeSecret(String base64Secret) {
    final bytes = base64.decode(base64Secret);
    if (bytes.length != 32) {
      throw FormatException('The key must be 32 bytes, got ${bytes.length}');
    }
    return Uint8List.fromList(bytes);
  }

  /// Seconds left before the code made at [now] is replaced.
  static int secondsRemaining(DateTime now) => windowSeconds - (now.millisecondsSinceEpoch ~/ 1000 % windowSeconds);
}

/// The parts of a boarding code.
class ParsedQrCode {
  const ParsedQrCode({required this.studentId, required this.window, required this.mac});

  final String studentId;
  final int window;
  final String mac;
}

/// What a staff phone concludes from a code on its own, before the server sees it.
enum QrCheck {
  /// The code is genuine and current, and the student is on today's list.
  valid,

  /// Not a BusIn code, tampered with, or made with another key.
  invalid,

  /// Genuine but too old (a photo or screenshot of an earlier code).
  expired,

  /// A well-formed code for a student who is not on today's list (no valid subscription today, or unknown).
  notOnList,
}

/// Checks codes on the staff phone with the day keys of today's riders (ADR 0014). Works without a connection.
class QrCodeVerifier {
  const QrCodeVerifier._();

  static final _uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
  static final _window = RegExp(r'^[0-9]{1,12}$');
  static final _mac = RegExp(r'^[0-9a-f]{20}$');

  /// The parts of [code], or null when it is not a `busin2` code.
  static ParsedQrCode? parse(String code) {
    if (code.length > 120) return null;
    final parts = code.split('.');
    if (parts.length != 4 || parts[0] != QrCodeGenerator.version) return null;
    if (!_uuid.hasMatch(parts[1]) || !_window.hasMatch(parts[2]) || !_mac.hasMatch(parts[3])) return null;
    return ParsedQrCode(studentId: parts[1], window: int.parse(parts[2]), mac: parts[3]);
  }

  /// Checks [code] at [now], as the server does: one window of tolerance either side, older is expired, newer is
  /// invalid. [dayKeyFor] gives the day key of a student for a school date, or null when the student is not on the
  /// list for that day.
  static QrCheck check({
    required String code,
    required DateTime now,
    required Uint8List? Function(String studentId, DateTime date) dayKeyFor,
    required DateTime Function(DateTime instant) schoolDate,
  }) {
    final parsed = parse(code);
    if (parsed == null) return QrCheck.invalid;
    final current = QrCodeGenerator.windowFor(now);
    if (parsed.window < current - 1) return QrCheck.expired;
    if (parsed.window > current + 1) return QrCheck.invalid;
    final key = dayKeyFor(parsed.studentId, schoolDate(QrCodeGenerator.windowStart(parsed.window)));
    if (key == null) return QrCheck.notOnList;
    final expected = QrCodeGenerator.mac(dayKey: key, studentId: parsed.studentId, window: parsed.window);
    return _sameText(expected, parsed.mac) ? QrCheck.valid : QrCheck.invalid;
  }

  // Compares every character, so the time taken does not depend on where the two differ.
  static bool _sameText(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
