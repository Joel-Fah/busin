import '../enums.dart';
import '../json.dart';
import '../value_object.dart';

/// One run of one bus.
class Trip extends ValueObject {
  const Trip({
    required this.id,
    required this.schoolId,
    required this.busId,
    required this.direction,
    required this.status,
    required this.scheduledStart,
    this.driverId,
    this.startedAt,
    this.endedAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: reqString(json, 'id'),
        schoolId: reqString(json, 'school_id'),
        busId: reqString(json, 'bus_id'),
        driverId: optString(json, 'driver_id'),
        direction: TripDirection.parse(json['direction']),
        status: TripStatus.parse(json['status']),
        scheduledStart: reqTimestamp(json, 'scheduled_start'),
        startedAt: optTimestamp(json, 'started_at'),
        endedAt: optTimestamp(json, 'ended_at'),
      );

  final String id;
  final String schoolId;
  final String busId;
  final String? driverId;
  final TripDirection direction;
  final TripStatus status;
  final DateTime scheduledStart;
  final DateTime? startedAt;
  final DateTime? endedAt;

  /// Scans are only accepted on an active trip.
  bool get acceptsScans => status == TripStatus.active;

  @override
  List<Object?> get props => [
        id,
        schoolId,
        busId,
        driverId,
        direction,
        status,
        scheduledStart,
        startedAt,
        endedAt,
      ];
}
