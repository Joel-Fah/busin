import '../enums.dart';
import '../json.dart';
import '../value_object.dart';
import 'billing.dart';

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
    this.paymentMode = PaymentMode.full,
    this.periodStart,
    this.periodEnd,
    this.billingPeriod,
    this.amountXaf,
    this.installmentPlan,
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
        paymentMode: PaymentMode.tryParse(json['payment_mode']) ?? PaymentMode.full,
        periodStart: optDate(json, 'period_start'),
        periodEnd: optDate(json, 'period_end'),
        billingPeriod: BillingPeriod.tryParse(json['billing_period']),
        amountXaf: optInt(json, 'amount_xaf'),
        installmentPlan: InstallmentPlan.tryParse(json['installment_plan']),
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

  /// How the student pays it (ADR 0022).
  final PaymentMode paymentMode;

  /// The month a monthly subscription covers (both dates included). Null for a subscription of the whole semester.
  final DateTime? periodStart;
  final DateTime? periodEnd;

  /// The school's billing when it was asked for: the period, the price and the plan. Null for older subscriptions.
  final BillingPeriod? billingPeriod;
  final int? amountXaf;
  final InstallmentPlan? installmentPlan;

  /// The last day it covers: its month's last day, or else [semesterEnd].
  DateTime coversUntil(DateTime semesterEnd) => periodEnd ?? semesterEnd;

  /// Whether it covers [day] (a date at midnight UTC, as the API gives dates), within its semester's dates.
  bool covers(DateTime day, {required DateTime semesterStart, required DateTime semesterEnd}) =>
      !day.isBefore(periodStart ?? semesterStart) && !day.isAfter(periodEnd ?? semesterEnd);

  /// The same shape the API returns, so [Subscription.fromJson] reads it back.
  Map<String, dynamic> toJson() => {
        'id': id,
        'school_id': schoolId,
        'student_id': studentId,
        'semester_id': semesterId,
        'stop_id': stopId,
        'status': status.name,
        'proof_path': proofPath,
        'review_note': reviewNote,
        'reviewed_by': reviewedBy,
        'reviewed_at': reviewedAt?.toUtc().toIso8601String(),
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'payment_mode': paymentMode.name,
        'period_start': periodStart == null ? null : formatDate(periodStart!),
        'period_end': periodEnd == null ? null : formatDate(periodEnd!),
        'billing_period': billingPeriod?.name,
        'amount_xaf': amountXaf,
        'installment_plan': installmentPlan?.code,
      };

  /// A student may have only one pending or approved request per period (a semester, or a month).
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
        paymentMode,
        periodStart,
        periodEnd,
        billingPeriod,
        amountXaf,
        installmentPlan,
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
    required this.proofPath,
    this.paymentMode = PaymentMode.full,
    this.periodStart,
  });

  final String schoolId;
  final String studentId;
  final String semesterId;
  final String stopId;

  /// The uploaded proof of payment. Required: the database refuses a request without one that exists in storage.
  /// Must be `<schoolId>/<studentId>/<file>`.
  final String proofPath;

  /// How the student pays. Installments only where the school offers a plan.
  final PaymentMode paymentMode;

  /// For monthly billing, the first day of the month asked for (this month or the next). The server works out the
  /// end and the price; a client never sends them.
  final DateTime? periodStart;

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
        'proof_path': proofPath,
        'payment_mode': paymentMode.name,
        if (periodStart != null) 'period_start': formatDate(periodStart!),
      };

  @override
  List<Object?> get props =>
      [schoolId, studentId, semesterId, stopId, proofPath, paymentMode, periodStart];
}
