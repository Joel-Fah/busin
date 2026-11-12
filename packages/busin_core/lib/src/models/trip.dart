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
    this.startedBy,
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
        startedBy: optString(json, 'started_by'),
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

  /// Who started the trip (null until it starts).
  final String? startedBy;

  /// Scans are only accepted on an active trip.
  bool get acceptsScans => status == TripStatus.active;

  /// Whether [userId] may start or end this trip, as the server decides (`start_trip`, `end_trip`): the staff member
  /// assigned to it, anyone on staff when nobody is assigned, and admins always. Ending is also open to whoever
  /// started it.
  bool canRun(String userId, {required bool isAdmin}) =>
      isAdmin || driverId == null || driverId == userId || (status == TripStatus.active && startedBy == userId);

  /// Whether [userId] shares this bus's position (`publish_position`): the assignee, or whoever started it when
  /// nobody is assigned, or an admin.
  bool sharesPosition(String userId, {required bool isAdmin}) =>
      isAdmin || driverId == userId || (driverId == null && startedBy == userId);

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
        startedBy,
      ];
}
