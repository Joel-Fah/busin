import '../json.dart';
import '../value_object.dart';

/// One boarding on a trip, as staff see it on the manifest (`trip_manifest`).
class ManifestEntry extends ValueObject {
  const ManifestEntry({
    required this.scanId,
    required this.studentId,
    required this.fullName,
    required this.scannedAt,
    this.avatarUrl,
    this.matricule,
    this.stopId,
  });

  factory ManifestEntry.fromJson(Map<String, dynamic> json) => ManifestEntry(
        scanId: reqString(json, 'scan_id'),
        studentId: reqString(json, 'student_id'),
        fullName: reqString(json, 'full_name'),
        avatarUrl: optString(json, 'avatar_url'),
        matricule: optString(json, 'matricule'),
        stopId: optString(json, 'stop_id'),
        scannedAt: reqTimestamp(json, 'scanned_at'),
      );

  final String scanId;
  final String studentId;
  final String fullName;
  final String? avatarUrl;
  final String? matricule;
  final String? stopId;
  final DateTime scannedAt;

  @override
  List<Object?> get props => [scanId, studentId, fullName, avatarUrl, matricule, stopId, scannedAt];
}
