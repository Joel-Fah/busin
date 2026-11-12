import '../geo_point.dart';
import '../json.dart';
import '../value_object.dart';

/// One boarding: a student scanned on a trip, ideally at a stop.
class Scan extends ValueObject {
  const Scan({
    required this.id,
    required this.schoolId,
    required this.tripId,
    required this.studentId,
    required this.subscriptionId,
    required this.scannedBy,
    required this.scannedAt,
    this.stopId,
    this.location,
    this.accuracyM,
  });

  factory Scan.fromJson(Map<String, dynamic> json) => Scan(
        id: reqString(json, 'id'),
        schoolId: reqString(json, 'school_id'),
        tripId: reqString(json, 'trip_id'),
        studentId: reqString(json, 'student_id'),
        subscriptionId: reqString(json, 'subscription_id'),
        stopId: optString(json, 'stop_id'),
        scannedBy: reqString(json, 'scanned_by'),
        scannedAt: reqTimestamp(json, 'scanned_at'),
        location: json['location'] == null
            ? null
            : GeoPoint.fromApi(json['location']),
        accuracyM: optDouble(json, 'accuracy_m'),
      );

  final String id;
  final String schoolId;
  final String tripId;
  final String studentId;
  final String subscriptionId;
  final String? stopId;
  final String scannedBy;
  final DateTime scannedAt;
  final GeoPoint? location;
  final double? accuracyM;

  @override
  List<Object?> get props => [
        id,
        schoolId,
        tripId,
        studentId,
        subscriptionId,
        stopId,
        scannedBy,
        scannedAt,
        location,
        accuracyM,
      ];
}
