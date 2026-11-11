import 'package:busin_core/busin_core.dart';

import 'eta.dart';

/// What the followed bus just did, in short. Shown one at a time on My bus; a newer one replaces it. Never stored.
enum BusUpdateKind { following, atStop, leftStop, stopped, moving, nearMyStop, passedMyStop, signalLost, signalBack, tripEnded }

class BusUpdate {
  const BusUpdate(this.kind, {required this.at, required this.seq, this.stopName, this.since, this.minutes});

  final BusUpdateKind kind;

  /// When it was noticed.
  final DateTime at;

  /// Grows with every update, so the screen knows a new one arrived even when the kind repeats.
  final int seq;

  /// The stop it is about (at a stop, left it).
  final String? stopName;

  /// Since when it holds (stopped, no signal): the screen counts the minutes from it.
  final DateTime? since;

  /// About how many minutes away (near my stop).
  final int? minutes;
}

/// Within this of a stop the bus is at it; it has left once further than [leftStopAfterMetres].
const atStopWithinMetres = arrivedWithinMetres;
const leftStopAfterMetres = 120.0;

/// Standing: slower than this, and within [stillWithinMetres] of where it stopped, for [stoppedAfter].
const stillBelowMps = 1.0;
const stillWithinMetres = 30.0;
const stoppedAfter = Duration(seconds: 90);

/// Near my stop: this many minutes away or less, said once per trip.
const nearMyStopMinutes = 3;

/// Passed my stop: it came within [reachedMyStopWithinMetres] of it (a bus sending every 10 s can skip past the 80 m
/// circle) and is now this far away, and moving away. Leaving my stop is said only this way, not as "left the stop".
const reachedMyStopWithinMetres = 150.0;
const passedMyStopAfterMetres = 300.0;

/// Turns the positions of one bus into short updates. Pure: it is given the time, so it is tested without a clock.
///
/// Feed it each new position with [onPosition], call [onTick] now and then (for "no signal"), and [onTripEnded] when the
/// trip is no longer running. Each returns the update to show, or null when nothing worth saying happened. When several
/// things happen at once the most useful is said: signal back, then passed or near my stop, then a stop, then stopped or
/// moving, then "following".
class BusUpdateDetector {
  BusUpdateDetector({required List<Stop> stops, this.myStop}) : _stops = [for (final s in stops) if (s.active) s];

  final List<Stop> _stops;
  final Stop? myStop;

  int _seq = 0;
  String? _tripId;
  LivePosition? _last;
  bool _started = false;
  bool _signalLost = false;

  Stop? _atStop;

  GeoPoint? _stillAnchor;
  DateTime? _stillSince;
  bool _stoppedSaid = false;

  bool _nearSaid = false;
  bool _reachedMine = false;
  bool _passedSaid = false;
  double? _lastMineDistance;

  BusUpdate _make(BusUpdateKind kind, DateTime now, {String? stopName, DateTime? since, int? minutes}) =>
      BusUpdate(kind, at: now, seq: ++_seq, stopName: stopName, since: since, minutes: minutes);

  void _resetTrip(String? tripId) {
    _tripId = tripId;
    _started = false;
    _atStop = null;
    _stillAnchor = null;
    _stillSince = null;
    _stoppedSaid = false;
    _nearSaid = false;
    _reachedMine = false;
    _passedSaid = false;
    _lastMineDistance = null;
  }

  Stop? _stopWithin(GeoPoint at, double metres) {
    Stop? best;
    var bestDistance = metres;
    for (final stop in _stops) {
      final d = distanceMetres(at, stop.location);
      if (d <= bestDistance) {
        best = stop;
        bestDistance = d;
      }
    }
    return best;
  }

  /// A new position of the bus.
  BusUpdate? onPosition(LivePosition position, DateTime now) {
    if (_last != null && !position.recordedAt.isAfter(_last!.recordedAt)) return null;
    if (position.tripId != _tripId) _resetTrip(position.tripId);
    _last = position;
    final at = position.location;
    final candidates = <BusUpdate? Function()>[];

    // Signal back.
    if (_signalLost) {
      _signalLost = false;
      candidates.add(() => _make(BusUpdateKind.signalBack, now));
    }

    // My stop: passed, or near.
    final mine = myStop;
    if (mine != null) {
      final d = distanceMetres(at, mine.location);
      if (d <= reachedMyStopWithinMetres) _reachedMine = true;
      final movingAway = _lastMineDistance != null && d > _lastMineDistance!;
      if (_reachedMine && !_passedSaid && d >= passedMyStopAfterMetres && movingAway) {
        _passedSaid = true;
        candidates.add(() => _make(BusUpdateKind.passedMyStop, now, stopName: mine.name));
      }
      final eta = estimateEta(bus: at, stop: mine.location, speedMps: position.speedMps);
      if (!_nearSaid && !_reachedMine && eta != null && !eta.arriving && eta.minutes <= nearMyStopMinutes) {
        _nearSaid = true;
        candidates.add(() => _make(BusUpdateKind.nearMyStop, now, stopName: mine.name, minutes: eta.minutes));
      }
      _lastMineDistance = d;
    }

    // Stops: arrived at one, or left it.
    final previousStop = _atStop;
    if (previousStop != null && distanceMetres(at, previousStop.location) > leftStopAfterMetres) {
      _atStop = null;
      if (previousStop.id != mine?.id) candidates.add(() => _make(BusUpdateKind.leftStop, now, stopName: previousStop.name));
    }
    final here = _stopWithin(at, atStopWithinMetres);
    if (here != null && here.id != _atStop?.id) {
      _atStop = here;
      candidates.add(() => _make(BusUpdateKind.atStop, now, stopName: here.name));
    }

    // Standing still (not at a stop, where standing is normal), or moving again.
    final slow = (position.speedMps ?? 0) < stillBelowMps;
    final anchor = _stillAnchor;
    if (slow && anchor != null && distanceMetres(at, anchor) <= stillWithinMetres) {
      if (!_stoppedSaid && _atStop == null && now.difference(_stillSince!) >= stoppedAfter) {
        _stoppedSaid = true;
        final since = _stillSince!;
        candidates.add(() => _make(BusUpdateKind.stopped, now, since: since));
      }
    } else {
      if (_stoppedSaid) candidates.add(() => _make(BusUpdateKind.moving, now));
      _stoppedSaid = false;
      _stillAnchor = slow ? at : null;
      _stillSince = slow ? position.recordedAt : null;
    }

    if (!_started) {
      _started = true;
      candidates.add(() => _make(BusUpdateKind.following, now));
    }

    if (candidates.isEmpty) return null;
    // The first one added is the most useful.
    return candidates.first();
  }

  /// The time passed without a new position: says "no signal" once when the last one gets too old.
  BusUpdate? onTick(DateTime now) {
    final last = _last;
    if (last == null || _signalLost) return null;
    final age = now.difference(last.recordedAt);
    if (age < const Duration(minutes: 2)) return null;
    _signalLost = true;
    return _make(BusUpdateKind.signalLost, now, since: last.recordedAt);
  }

  /// The trip is no longer running.
  BusUpdate onTripEnded(DateTime now) => _make(BusUpdateKind.tripEnded, now);
}
