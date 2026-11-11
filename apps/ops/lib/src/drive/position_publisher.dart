import 'dart:async';

import 'package:busin_core/busin_core.dart';

/// Where sharing stands, for the trip screen.
enum ShareStatus {
  /// Positions go out.
  sharing,

  /// No connection right now; positions resume by themselves when it is back (old ones are not queued: only the
  /// current position matters).
  waiting,

  /// Stopped: turned off, the trip ended, or this phone may not share for this trip.
  stopped,
}

/// Sends the bus position for a running trip at most every [interval], from a stream of readings. Stops by itself
/// when the server says the trip is over or this phone may not share it.
class PositionPublisher {
  PositionPublisher({
    required this.tripId,
    required this.positions,
    required this.now,
    this.interval = const Duration(seconds: 10),
  });

  final String tripId;
  final LivePositionsRepository positions;
  final DateTime Function() now;
  final Duration interval;

  ShareStatus status = ShareStatus.sharing;
  DateTime? lastSentAt;
  bool _sending = false;

  /// Called on every change of [status] or [lastSentAt].
  void Function()? onChange;

  /// One reading from the phone. Returns whether it was sent.
  Future<bool> offer(({GeoPoint point, double accuracy, double? speed, double? heading}) fix) async {
    if (status == ShareStatus.stopped || _sending) return false;
    final at = now();
    final last = lastSentAt;
    if (last != null && at.difference(last) < interval) return false;
    _sending = true;
    try {
      await positions.publish(tripId: tripId, position: fix.point, speedMps: fix.speed, headingDeg: fix.heading, accuracyM: fix.accuracy);
      lastSentAt = at;
      status = ShareStatus.sharing;
      return true;
    } on Offline {
      status = ShareStatus.waiting;
      return false;
    } on NotAllowed {
      status = ShareStatus.stopped;
      return false;
    } on Conflict {
      // The trip is not running any more.
      status = ShareStatus.stopped;
      return false;
    } catch (_) {
      status = ShareStatus.waiting;
      return false;
    } finally {
      _sending = false;
      onChange?.call();
    }
  }

  void stop() {
    status = ShareStatus.stopped;
    onChange?.call();
  }
}
