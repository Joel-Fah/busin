import 'dart:async';
import 'dart:io';

import 'package:busin_core/busin_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Crash reports from the phone apps (ADR 0025): Firebase Crashlytics, in release builds only, with no personal data.
///
/// * Only release builds send anything; debug runs and tests never do (collection is also off in the Android manifest
///   until this turns it on).
/// * A report carries the app (`student` or `ops`), the role and the app version Crashlytics adds itself. Never a name,
///   an email, a user id, a code, a position or a token.
/// * Error texts are passed through [redactForReport] (emails, long numbers and ids taken out) before they leave.
/// * What the app expects is not a crash: no connection, a refusal, a conflict ([isReportable]).
abstract interface class CrashReporter {
  /// The person's role once it is known (`student`, `staff`, `admin`), or null after signing out.
  Future<void> setRole(String? role);
}

/// Used when the build has no Firebase configuration, and in debug builds and tests.
class NoCrashReporter implements CrashReporter {
  const NoCrashReporter();

  @override
  Future<void> setRole(String? role) async {}
}

/// Whether an error is worth a report. Expected outcomes are not: the server could not be reached, or it said no.
bool isReportable(Object error) => switch (error) {
      Unexpected() => true,
      RepositoryException() => false,
      SocketException() || TimeoutException() || HttpException() || HandshakeException() => false,
      _ => true,
    };

final _email = RegExp(r'[^\s@<>()"]+@[^\s@<>()"]+\.[A-Za-z]{2,}');
final _uuid = RegExp(r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b');
final _token = RegExp(r'\b[A-Za-z0-9_\-]{24,}\.[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}\b');
final _boardingCode = RegExp(r'\bbusin\d\.[^\s]+');
final _longNumber = RegExp(r'\+?\d[\d ]{6,}\d');
final _coordinates = RegExp(r'-?\d{1,3}\.\d{3,}');

/// [text] without the personal data an error message may carry: emails, ids, tokens, boarding codes, phone numbers and
/// coordinates are replaced by what they are. Kept short.
String redactForReport(String text) {
  final cleaned = text
      .replaceAll(_boardingCode, '<code>')
      .replaceAll(_token, '<token>')
      .replaceAll(_email, '<email>')
      .replaceAll(_uuid, '<id>')
      .replaceAll(_longNumber, '<number>')
      .replaceAll(_coordinates, '<coordinate>');
  return cleaned.length > 500 ? '${cleaned.substring(0, 500)}...' : cleaned;
}

/// What is sent in place of the original error: its type and its redacted message, so nothing personal it held leaves.
class ReportedError implements Exception {
  ReportedError(Object error) : description = '${error.runtimeType}: ${redactForReport(error.toString())}';

  final String description;

  @override
  String toString() => description;
}

/// Starts crash reporting for [app] (`student` or `ops`). Call it after Firebase has been started (the push service
/// does that); without Firebase, or in a debug build, it gives back [NoCrashReporter] and changes nothing.
///
/// With the build flag `BUSIN_CRASH_TEST=true` a release build also sends one non-fatal test report, to switch the
/// project's Crashlytics dashboard on and check the set-up (`--dart-define=BUSIN_CRASH_TEST=true`).
Future<CrashReporter> startCrashReports({required String app, String? role, bool release = kReleaseMode}) async {
  if (!release || Firebase.apps.isEmpty) {
    if (Firebase.apps.isNotEmpty) {
      // Debug runs: make sure nothing is sent, whatever the manifest says.
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false).catchError((Object _) {});
    }
    return const NoCrashReporter();
  }
  try {
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(true);
    await crashlytics.setCustomKey('app', app);
    if (role != null) await crashlytics.setCustomKey('role', role);

    final previousFlutter = FlutterError.onError;
    FlutterError.onError = (details) {
      previousFlutter?.call(details);
      if (!isReportable(details.exception)) return;
      unawaited(crashlytics.recordError(ReportedError(details.exception), details.stack, fatal: true, printDetails: false));
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      if (isReportable(error)) unawaited(crashlytics.recordError(ReportedError(error), stack, fatal: true, printDetails: false));
      // Handled: the app keeps running where it can.
      return true;
    };

    if (const bool.fromEnvironment('BUSIN_CRASH_TEST')) {
      await crashlytics.recordError(ReportedError(StateError('Crashlytics test report from the $app app')), StackTrace.current, reason: 'set-up check');
    }
    return _FirebaseCrashReporter(crashlytics);
  } catch (_) {
    // Crash reporting must never stop the app from starting.
    return const NoCrashReporter();
  }
}

class _FirebaseCrashReporter implements CrashReporter {
  _FirebaseCrashReporter(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> setRole(String? role) => _crashlytics.setCustomKey('role', role ?? 'signed-out').catchError((Object _) {});
}
