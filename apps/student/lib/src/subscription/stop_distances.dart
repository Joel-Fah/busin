import 'package:busin_core/busin_core.dart';

import '../bus/eta.dart';

/// A stop with its approximate distance from the student's area, by road (the straight line times [roadFactor], as for
/// Show me), in kilometres rounded to 0.1. Null without an area.
typedef RankedStop = ({Stop stop, double? km});

/// The stops in the order the list shows them, each with its distance from [area] when there is one: nearest first when
/// the student gave their area (stops at the same distance keep the school's order), else the school's order (by name).
/// The nearest is only pointed out, never chosen (see [closestStop]).
List<RankedStop> stopsWithDistance(List<Stop> stops, GeoPoint? area) {
  final ranked = [
    for (final stop in stops)
      (stop: stop, km: area == null ? null : (distanceMetres(area, stop.location) * roadFactor / 100).round() / 10),
  ];
  if (area == null) return ranked;
  // A stable sort: the school's order breaks ties.
  final order = {for (var i = 0; i < ranked.length; i++) ranked[i].stop.id: i};
  return ranked..sort((a, b) {
    final byKm = a.km!.compareTo(b.km!);
    return byKm != 0 ? byKm : order[a.stop.id]!.compareTo(order[b.stop.id]!);
  });
}

/// The stop nearest to the area, to suggest. Null without an area or without stops.
RankedStop? closestStop(List<RankedStop> ranked) {
  RankedStop? best;
  for (final r in ranked) {
    if (r.km == null) continue;
    if (best == null || r.km! < best.km!) best = r;
  }
  return best;
}
