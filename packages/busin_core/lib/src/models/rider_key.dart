import 'dart:typed_data';

import '../json.dart';
import '../qr_code.dart';
import '../value_object.dart';

/// One of today's riders on a staff phone (ADR 0014): the day key that checks their code offline, and what the result
/// card at the door shows. Comes from `staff_day_keys`; valid for [day] only.
class RiderKey extends ValueObject {
  const RiderKey({
    required this.studentId,
    required this.dayKey,
    required this.fullName,
    required this.day,
    this.avatarUrl,
    this.matricule,
    this.stopId,
  });

  factory RiderKey.fromJson(Map<String, dynamic> json) => RiderKey(
        studentId: reqString(json, 'student_id'),
        dayKey: QrCodeGenerator.decodeSecret(reqString(json, 'day_key')),
        fullName: reqString(json, 'full_name'),
        avatarUrl: optString(json, 'avatar_url'),
        matricule: optString(json, 'matricule'),
        stopId: optString(json, 'stop_id'),
        day: reqDate(json, 'day'),
      );

  final String studentId;
  final Uint8List dayKey;
  final String fullName;
  final String? avatarUrl;
  final String? matricule;
  final String? stopId;

  /// The school day the key is for.
  final DateTime day;

  @override
  List<Object?> get props => [studentId, ...dayKey, fullName, avatarUrl, matricule, stopId, day];
}
