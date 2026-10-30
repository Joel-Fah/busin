import 'dart:convert';
import 'dart:typed_data';

import 'package:busin_core/busin_core.dart';
import 'package:test/test.dart';

/// Secret used by the shared test vector: bytes 0x00 to 0x1f.
Uint8List vectorSecret() => Uint8List.fromList(List<int>.generate(32, (i) => i));

const studentId = 'a1000000-0000-4000-8000-000000000001';

void main() {
  group('QrCodeGenerator', () {
    test('reproduces the shared test vector from docs/guides/qr-code-format.md', () {
      // The vector was computed with Node crypto and is also asserted by the
      // database test 006_rotating_qr.test.sql.
      expect(
        QrCodeGenerator.mac(
          secret: vectorSecret(),
          studentId: studentId,
          window: 57000000,
        ),
        'c73e53d52fa5fb670e54',
      );
    });

    test('builds the busin1 code format', () {
      // 57000000 windows * 30 seconds
      final at = DateTime.fromMillisecondsSinceEpoch(57000000 * 30 * 1000, isUtc: true);
      expect(
        QrCodeGenerator.generate(secret: vectorSecret(), studentId: studentId, now: at),
        'busin1.$studentId.57000000.c73e53d52fa5fb670e54',
      );
    });

    test('the window advances every 30 seconds', () {
      final start = DateTime.utc(2030, 1, 1, 0, 0, 0);
      expect(
        QrCodeGenerator.windowFor(start.add(const Duration(seconds: 29))),
        QrCodeGenerator.windowFor(start),
      );
      expect(
        QrCodeGenerator.windowFor(start.add(const Duration(seconds: 30))),
        QrCodeGenerator.windowFor(start) + 1,
      );
    });

    test('a different window or secret gives a different mac', () {
      final base = QrCodeGenerator.mac(
        secret: vectorSecret(), studentId: studentId, window: 1);
      expect(
        QrCodeGenerator.mac(secret: vectorSecret(), studentId: studentId, window: 2),
        isNot(base),
      );
      expect(
        QrCodeGenerator.mac(
          secret: Uint8List(32), studentId: studentId, window: 1),
        isNot(base),
      );
    });

    test('decodes a 32 byte base64 secret and rejects other lengths', () {
      final encoded = base64.encode(vectorSecret());
      expect(QrCodeGenerator.decodeSecret(encoded), vectorSecret());
      expect(
        () => QrCodeGenerator.decodeSecret(base64.encode(Uint8List(16))),
        throwsFormatException,
      );
    });

    test('reports the seconds left in the current window', () {
      expect(QrCodeGenerator.secondsRemaining(DateTime.utc(2030, 1, 1, 0, 0, 0)), 30);
      expect(QrCodeGenerator.secondsRemaining(DateTime.utc(2030, 1, 1, 0, 0, 29)), 1);
    });
  });
}
