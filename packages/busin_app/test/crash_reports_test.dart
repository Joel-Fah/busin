import 'dart:async';
import 'dart:io';

import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expected outcomes are not crashes; real bugs and unexpected server errors are', () {
    expect(isReportable(const Offline('no network')), isFalse);
    expect(isReportable(const NotAllowed('refused')), isFalse);
    expect(isReportable(const SocketException('down')), isFalse);
    expect(isReportable(TimeoutException('slow')), isFalse);
    expect(isReportable(const Unexpected('odd answer')), isTrue);
    expect(isReportable(StateError('bug')), isTrue);
    expect(isReportable(RangeError(3)), isTrue);
  });

  test('personal data is taken out of an error text before it is sent', () {
    const raw = 'Key (email)=(Jane.Doe@ictuniversity.edu.cm) for 1e614036-427a-45a3-ab6e-6ce0278f9764 '
        'phone +237 677 12 34 56 at 3.8346295, 11.4722868 code busin2.abc.123.def token eyJhbGciOiJIUzI1NiIsInR5cCI6.eyJzdWIiOiIxMjM0NTY3OD.SflKxwRJSMeKKF2QT4fwpMe';
    final cleaned = redactForReport(raw);
    for (final secret in ['Jane.Doe', 'ictuniversity', '1e614036', '677 12', '3.8346295', '11.4722868', 'busin2.abc', 'eyJhbGci']) {
      expect(cleaned, isNot(contains(secret)), reason: secret);
    }
    expect(cleaned, contains('<email>'));
    expect(cleaned, contains('<id>'));
    expect(cleaned, contains('<number>'));
    expect(cleaned, contains('<code>'));
  });

  test('a reported error keeps its type and loses what was personal', () {
    final error = ReportedError(StateError('Bad state for student@school.edu'));
    expect(error.toString(), 'StateError: Bad state: Bad state for <email>');
  });

  test('a debug build or one without Firebase reports nothing', () async {
    expect(await startCrashReports(app: 'student', release: false), isA<NoCrashReporter>());
    expect(await startCrashReports(app: 'student', release: true), isA<NoCrashReporter>(), reason: 'no Firebase in tests');
  });
}
