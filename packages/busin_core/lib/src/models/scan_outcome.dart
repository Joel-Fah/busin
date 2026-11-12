import '../enums.dart';
import '../json.dart';
import '../value_object.dart';

/// The student details a scanner shows after a successful scan.
class StudentSummary extends ValueObject {
  const StudentSummary({required this.fullName, this.avatarUrl, this.matricule});

  factory StudentSummary.fromJson(Map<String, dynamic> json) => StudentSummary(
        fullName: reqString(json, 'full_name'),
        avatarUrl: optString(json, 'avatar_url'),
        matricule: optString(json, 'matricule'),
      );

  final String fullName;
  final String? avatarUrl;
  final String? matricule;

  @override
  List<Object?> get props => [fullName, avatarUrl, matricule];
}

/// The result of submitting a scanned code to `record_qr_scan`.
///
/// Refusals that staff should see (bad code, no subscription) come back as data.
/// Problems with the caller or the trip come back as API errors instead.
sealed class ScanOutcome extends ValueObject {
  const ScanOutcome();

  factory ScanOutcome.fromJson(Map<String, dynamic> json) {
    final valid = json['valid'];
    if (valid is! bool) {
      throw FormatException('Field "valid" must be a boolean, got: $valid');
    }
    if (!valid) {
      return ScanRefused(ScanFailure.parse(json['reason']));
    }
    final student = json['student'];
    if (student is! Map<String, dynamic>) {
      throw FormatException('Field "student" must be an object, got: $student');
    }
    return ScanAccepted(
      student: StudentSummary.fromJson(student),
      duplicate: json['duplicate'] == true,
      scanId: optString(json, 'scan_id'),
    );
  }
}

/// The boarding was accepted. [duplicate] is true when this student was already
/// scanned on the trip, so no new row was created.
class ScanAccepted extends ScanOutcome {
  const ScanAccepted({
    required this.student,
    required this.duplicate,
    this.scanId,
  });

  final StudentSummary student;
  final bool duplicate;
  final String? scanId;

  @override
  List<Object?> get props => [student, duplicate, scanId];
}

/// The scan was refused for [reason].
class ScanRefused extends ScanOutcome {
  const ScanRefused(this.reason);

  final ScanFailure reason;

  @override
  List<Object?> get props => [reason];
}
