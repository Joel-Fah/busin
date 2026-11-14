import 'package:busin_core/busin_core.dart';

import '../bus/eta.dart';

/// A stop with its approximate distance from the student's area, by road (the straight line times [roadFactor], as for
/// Show me), in kilometres rounded to 0.1. Null without an area.
typedef RankedStop = ({Stop stop, double? km});

/// The stops in the order the list shows them, each with its distance from [area] when there is one. The order is the
/// school's (by name); the nearest is only pointed out, never chosen (see [closestStop]).
List<RankedStop> stopsWithDistance(List<Stop> stops, GeoPoint? area) => [
      for (final stop in stops)
        (stop: stop, km: area == null ? null : (distanceMetres(area, stop.location) * roadFactor / 100).round() / 10),
    ];

/// The stop nearest to the area, to suggest. Null without an area or without stops.
RankedStop? closestStop(List<RankedStop> ranked) {
  RankedStop? best;
  for (final r in ranked) {
    if (r.km == null) continue;
    if (best == null || r.km! < best.km!) best = r;
  }
  return best;
}
