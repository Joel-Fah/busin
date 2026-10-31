import '../enums.dart';
import '../json.dart';
import '../value_object.dart';

/// A student's request for bus service in one semester, from one stop.
class Subscription extends ValueObject {
  const Subscription({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.semesterId,
    required this.stopId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.proofPath,
    this.reviewNote,
    this.reviewedBy,
    this.reviewedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: reqString(json, 'id'),
        schoolId: reqString(json, 'school_id'),
        studentId: reqString(json, 'student_id'),
        semesterId: reqString(json, 'semester_id'),
        stopId: reqString(json, 'stop_id'),
        status: SubscriptionStatus.parse(json['status']),
        proofPath: optString(json, 'proof_path'),
        reviewNote: optString(json, 'review_note'),
        reviewedBy: optString(json, 'reviewed_by'),
        reviewedAt: optTimestamp(json, 'reviewed_at'),
        createdAt: reqTimestamp(json, 'created_at'),
        updatedAt: reqTimestamp(json, 'updated_at'),
      );

  final String id;
  final String schoolId;
  final String studentId;
  final String semesterId;
  final String stopId;
  final SubscriptionStatus status;

  /// Path in the private `proofs` bucket; show it through a signed URL.
  final String? proofPath;
  final String? reviewNote;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// A student may have only one pending or approved request per semester.
  bool get isLive =>
      status == SubscriptionStatus.pending ||
      status == SubscriptionStatus.approved;

  @override
  List<Object?> get props => [
        id,
        schoolId,
        studentId,
        semesterId,
        stopId,
        status,
        proofPath,
        reviewNote,
        reviewedBy,
        reviewedAt,
        createdAt,
        updatedAt,
      ];
}

/// What a student sends to request a subscription. The status is always
/// `pending`: the database refuses anything else from a client.
class NewSubscription extends ValueObject {
  const NewSubscription({
    required this.schoolId,
    required this.studentId,
    required this.semesterId,
    required this.stopId,
    this.proofPath,
  });

  final String schoolId;
  final String studentId;
  final String semesterId;
  final String stopId;

  /// Must be `<schoolId>/<studentId>/<file>`, as the database requires.
  final String? proofPath;

  /// The proof path the database accepts for this student and a file name.
  static String proofPathFor({
    required String schoolId,
    required String studentId,
    required String fileName,
  }) =>
      '$schoolId/$studentId/$fileName';

  Map<String, dynamic> toJson() => {
        'school_id': schoolId,
        'student_id': studentId,
        'semester_id': semesterId,
        'stop_id': stopId,
        'proof_path': ?proofPath,
      };

  @override
  List<Object?> get props =>
      [schoolId, studentId, semesterId, stopId, proofPath];
}
