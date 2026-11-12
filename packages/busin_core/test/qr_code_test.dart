import 'dart:convert';
import 'dart:typed_data';

import 'package:busin_core/busin_core.dart';
import 'package:test/test.dart';

/// Secret used by the shared test vector: bytes 0x00 to 0x1f.
Uint8List vectorSecret() => Uint8List.fromList(List<int>.generate(32, (i) => i));

const studentId = 'a1000000-0000-4000-8000-000000000001';

/// Douala is UTC+1 all year: the school-local date of an instant.
DateTime douala(DateTime instant) {
  final local = instant.toUtc().add(const Duration(hours: 1));
  return DateTime(local.year, local.month, local.day);
}

/// Window 57000000 starts at 2024-03-09 16:00 UTC.
final vectorTime = DateTime.fromMillisecondsSinceEpoch(57000000 * 30 * 1000, isUtc: true);

void main() {
  group('QrCodeGenerator', () {
    test('reproduces the shared test vectors from docs/guides/qr-code-format.md', () {
      // Computed with Node crypto and also asserted by the database test 006_rotating_qr.test.sql.
      final key = QrCodeGenerator.dayKey(secret: vectorSecret(), date: DateTime(2024, 3, 9));
      expect(base64.encode(key), '2+iOc6ccORTN/5PUWz8vmJgxeWppubAPXM+vCy37KaU=');
      expect(QrCodeGenerator.mac(dayKey: key, studentId: studentId, window: 57000000), 'cef45af39487cc9ba62e');
    });

    test('builds the busin2 code with the day key of the school-local date', () {
      expect(
        QrCodeGenerator.generate(secret: vectorSecret(), studentId: studentId, now: vectorTime, schoolDate: douala),
        'busin2.$studentId.57000000.cef45af39487cc9ba62e',
      );
    });

    test('the date is the school\'s, not the phone\'s: 23:30 UTC is already the next day in Douala', () {
      final late = DateTime.utc(2024, 3, 9, 23, 30);
      final code = QrCodeGenerator.generate(secret: vectorSecret(), studentId: studentId, now: late, schoolDate: douala);
      final window = QrCodeGenerator.windowFor(late);
      final nextDay = QrCodeGenerator.dayKey(secret: vectorSecret(), date: DateTime(2024, 3, 10));
      expect(code.split('.').last, QrCodeGenerator.mac(dayKey: nextDay, studentId: studentId, window: window));
    });

    test('the window advances every 30 seconds', () {
      final start = DateTime.utc(2030, 1, 1, 0, 0, 0);
      expect(QrCodeGenerator.windowFor(start.add(const Duration(seconds: 29))), QrCodeGenerator.windowFor(start));
      expect(QrCodeGenerator.windowFor(start.add(const Duration(seconds: 30))), QrCodeGenerator.windowFor(start) + 1);
      expect(QrCodeGenerator.windowStart(QrCodeGenerator.windowFor(start)), start);
    });

    test('a different window, day or secret gives a different mac', () {
      final key = QrCodeGenerator.dayKey(secret: vectorSecret(), date: DateTime(2024, 3, 9));
      final base = QrCodeGenerator.mac(dayKey: key, studentId: studentId, window: 1);
      expect(QrCodeGenerator.mac(dayKey: key, studentId: studentId, window: 2), isNot(base));
      final otherDay = QrCodeGenerator.dayKey(secret: vectorSecret(), date: DateTime(2024, 3, 10));
      expect(QrCodeGenerator.mac(dayKey: otherDay, studentId: studentId, window: 1), isNot(base));
      final otherSecret = QrCodeGenerator.dayKey(secret: Uint8List(32), date: DateTime(2024, 3, 9));
      expect(QrCodeGenerator.mac(dayKey: otherSecret, studentId: studentId, window: 1), isNot(base));
    });

    test('decodes a 32 byte base64 key and rejects other lengths', () {
      expect(QrCodeGenerator.decodeSecret(base64.encode(vectorSecret())), vectorSecret());
      expect(() => QrCodeGenerator.decodeSecret(base64.encode(Uint8List(16))), throwsFormatException);
    });

    test('reports the seconds left in the current window', () {
      expect(QrCodeGenerator.secondsRemaining(DateTime.utc(2030, 1, 1, 0, 0, 0)), 30);
      expect(QrCodeGenerator.secondsRemaining(DateTime.utc(2030, 1, 1, 0, 0, 29)), 1);
    });
  });

  group('QrCodeVerifier', () {
    final todayKey = QrCodeGenerator.dayKey(secret: vectorSecret(), date: DateTime(2024, 3, 9));
    Uint8List? keys(String id, DateTime date) => id == studentId && date == DateTime(2024, 3, 9) ? todayKey : null;
    String codeAt(DateTime at, {String id = studentId}) =>
        QrCodeGenerator.generate(secret: vectorSecret(), studentId: id, now: at, schoolDate: douala);
    QrCheck check(String code, {DateTime? now}) =>
        QrCodeVerifier.check(code: code, now: now ?? vectorTime, dayKeyFor: keys, schoolDate: douala);

    test('a current code of a student on today\'s list is valid, offline', () {
      expect(check(codeAt(vectorTime)), QrCheck.valid);
    });

    test('one window of tolerance either side, as on the server', () {
      final code = codeAt(vectorTime);
      expect(check(code, now: vectorTime.add(const Duration(seconds: 30))), QrCheck.valid);
      expect(check(code, now: vectorTime.subtract(const Duration(seconds: 30))), QrCheck.valid);
      expect(check(code, now: vectorTime.add(const Duration(seconds: 60))), QrCheck.expired);
      expect(check(code, now: vectorTime.subtract(const Duration(seconds: 60))), QrCheck.invalid);
    });

    test('a tampered or foreign code is invalid', () {
      final code = codeAt(vectorTime);
      expect(check('${code.substring(0, code.length - 1)}${code.endsWith('0') ? '1' : '0'}'), QrCheck.invalid);
      expect(check('busin1.$studentId.57000000.c73e53d52fa5fb670e54'), QrCheck.invalid);
      expect(check(studentId), QrCheck.invalid);
      expect(check('https://example.com'), QrCheck.invalid);
    });

    test('a well-formed code of someone not on today\'s list is reported as such', () {
      expect(check(codeAt(vectorTime, id: 'b1000000-0000-4000-8000-000000000009')), QrCheck.notOnList);
    });

    test('parses the parts of a code', () {
      final parsed = QrCodeVerifier.parse(codeAt(vectorTime))!;
      expect(parsed.studentId, studentId);
      expect(parsed.window, 57000000);
      expect(QrCodeVerifier.parse('busin2.not-a-uuid.1.abc'), isNull);
    });
  });
}
