import 'dart:math' as math;

import 'package:busin_core/busin_core.dart';

import '../keys/roster.dart';

/// What the phone decides at the door, before (or without) the server.
sealed class ScanDecision {
  const ScanDecision();
}

/// A genuine, current code of a student on today's list: let them on and queue the scan.
class Admit extends ScanDecision {
  const Admit(this.rider);
  final RiderKey rider;
}

/// Already scanned on this trip from this phone.
class AlreadyOnBoard extends ScanDecision {
  const AlreadyOnBoard(this.rider);
  final RiderKey rider;
}

enum RefusalKind { invalid, expired, notOnList, noKeys }

/// Refused on the phone.
class Refuse extends ScanDecision {
  const Refuse(this.kind);
  final RefusalKind kind;
}

/// The phone cannot decide (no list for today, or a student not on it) but there is a connection: ask the server.
class AskServer extends ScanDecision {
  const AskServer();
}

/// The decision for [code] (ADR 0014): checked with today's day keys, so it works offline. [boarded] are the students
/// this phone already let on for the trip.
ScanDecision decideScan({
  required String code,
  required DateTime now,
  required Roster? roster,
  required DateTime Function(DateTime instant) schoolDate,
  required Set<String> boarded,
  required bool online,
}) {
  final parsed = QrCodeVerifier.parse(code);
  if (parsed == null) return const Refuse(RefusalKind.invalid);
  final today = schoolDate(now);
  if (roster == null || !roster.isFor(today)) {
    return online ? const AskServer() : const Refuse(RefusalKind.noKeys);
  }
  final check = QrCodeVerifier.check(code: code, now: now, dayKeyFor: roster.keyFor, schoolDate: schoolDate);
  switch (check) {
    case QrCheck.invalid:
      return const Refuse(RefusalKind.invalid);
    case QrCheck.expired:
      return const Refuse(RefusalKind.expired);
    case QrCheck.notOnList:
      // Approved after this phone downloaded the list? The server knows.
      return online ? const AskServer() : const Refuse(RefusalKind.notOnList);
    case QrCheck.valid:
      final rider = roster.rider(parsed.studentId)!;
      return boarded.contains(rider.studentId) ? AlreadyOnBoard(rider) : Admit(rider);
  }
}

/// The nearest active stop to a position, within [maxMeters] (the bus is at a stop when it scans), or null.
Stop? nearestStop(List<Stop> stops, GeoPoint at, {double maxMeters = 300}) {
  Stop? best;
  var bestDistance = maxMeters;
  for (final stop in stops) {
    final d = metresBetween(at, stop.location);
    if (d <= bestDistance) {
      best = stop;
      bestDistance = d;
    }
  }
  return best;
}

/// Great-circle distance in metres.
double metresBetween(GeoPoint a, GeoPoint b) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(b.latitude - a.latitude);
  final dLng = rad(b.longitude - a.longitude);
  final h = math.pow(math.sin(dLat / 2), 2) + math.cos(rad(a.latitude)) * math.cos(rad(b.latitude)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(h));
}
