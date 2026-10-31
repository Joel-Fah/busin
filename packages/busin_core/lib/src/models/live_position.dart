import '../enums.dart';
import '../geo_point.dart';
import '../json.dart';
import '../value_object.dart';

/// The latest known position of a bus.
class LivePosition extends ValueObject {
  const LivePosition({
    required this.busId,
    required this.schoolId,
    required this.location,
    required this.source,
    required this.recordedAt,
    this.tripId,
    this.speedMps,
    this.headingDeg,
    this.accuracyM,
  });

  factory LivePosition.fromJson(Map<String, dynamic> json) => LivePosition(
        busId: reqString(json, 'bus_id'),
        schoolId: reqString(json, 'school_id'),
        tripId: optString(json, 'trip_id'),
        location: GeoPoint.fromApi(json['location']),
        speedMps: optDouble(json, 'speed_mps'),
        headingDeg: optDouble(json, 'heading_deg'),
        accuracyM: optDouble(json, 'accuracy_m'),
        source: PositionSource.parse(json['source']),
        recordedAt: reqTimestamp(json, 'recorded_at'),
      );

  final String busId;
  final String schoolId;
  final String? tripId;
  final GeoPoint location;
  final double? speedMps;
  final double? headingDeg;
  final double? accuracyM;
  final PositionSource source;
  final DateTime recordedAt;

  /// True when the position is older than [maxAge] at [now].
  bool isStale(DateTime now, {Duration maxAge = const Duration(minutes: 2)}) =>
      now.difference(recordedAt) > maxAge;

  @override
  List<Object?> get props => [
        busId,
        schoolId,
        tripId,
        location,
        speedMps,
        headingDeg,
        accuracyM,
        source,
        recordedAt,
      ];
}
