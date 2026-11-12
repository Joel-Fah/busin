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

  /// The name of the crew member whose phone leads the position while this phone's fixes are set aside by the
  /// server (ADR 0019); null when this phone leads or nobody does. This phone takes over by itself when the leader
  /// has been quiet for 30 seconds: its next fix is then kept.
  String? standbyFor;
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
      final kept = await positions.publish(tripId: tripId, position: fix.point, speedMps: fix.speed, headingDeg: fix.heading, accuracyM: fix.accuracy);
      lastSentAt = at;
      status = ShareStatus.sharing;
      if (kept) {
        standbyFor = null;
      } else {
        // Set aside: because another phone leads, or only because the fix was imprecise. Ask which.
        await _askWhoLeads();
      }
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

  Future<void> _askWhoLeads() async {
    try {
      final holder = await positions.positionHolder(tripId);
      standbyFor = holder != null && !holder.isMe ? (holder.name.isEmpty ? holder.holderId : holder.name) : null;
    } catch (_) {
      // Without the answer the last one stands; the next fix asks again.
    }
  }

  void stop() {
    status = ShareStatus.stopped;
    standbyFor = null;
    onChange?.call();
  }
}
