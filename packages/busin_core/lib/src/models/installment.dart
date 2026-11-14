import '../json.dart';
import '../value_object.dart';

/// Where a part of a subscription paid in installments stands (ADR 0022).
enum InstallmentStatus {
  /// Not paid yet; the student can send a proof.
  due,

  /// A proof was sent and waits for the school.
  submitted,
  paid,

  /// The school did not accept the proof; the student can send another.
  rejected;

  static InstallmentStatus parse(Object? raw) =>
      values.firstWhere((v) => v.name == raw, orElse: () => throw FormatException('Unknown installment status: $raw'));
}

/// One part of a subscription paid in installments. Part 1 is the request's own proof, settled with the request.
class Installment extends ValueObject {
  const Installment({
    required this.id,
    required this.subscriptionId,
    required this.seq,
    required this.percent,
    required this.amountXaf,
    required this.dueDate,
    required this.status,
    this.proofPath,
    this.reviewNote,
  });

  factory Installment.fromJson(Map<String, dynamic> json) => Installment(
        id: reqString(json, 'id'),
        subscriptionId: reqString(json, 'subscription_id'),
        seq: reqInt(json, 'seq'),
        percent: reqInt(json, 'percent'),
        amountXaf: reqInt(json, 'amount_xaf'),
        dueDate: reqDate(json, 'due_date'),
        status: InstallmentStatus.parse(json['status']),
        proofPath: optString(json, 'proof_path'),
        reviewNote: optString(json, 'review_note'),
      );

  final String id;
  final String subscriptionId;

  /// 1 for the first part.
  final int seq;
  final int percent;
  final int amountXaf;

  /// The school day it is due.
  final DateTime dueDate;
  final InstallmentStatus status;
  final String? proofPath;

  /// Why the school did not accept the last proof.
  final String? reviewNote;

  /// Whether the student can send a proof for it now. Part 1 goes with the request itself.
  bool get open => seq > 1 && (status == InstallmentStatus.due || status == InstallmentStatus.rejected);

  /// Due on or before [today] (a school date) and not paid or waiting.
  bool overdue(DateTime today) => open && !dueDate.isAfter(today);

  Map<String, dynamic> toJson() => {
        'id': id,
        'subscription_id': subscriptionId,
        'seq': seq,
        'percent': percent,
        'amount_xaf': amountXaf,
        'due_date': formatDate(dueDate),
        'status': status.name,
        'proof_path': proofPath,
        'review_note': reviewNote,
      };

  @override
  List<Object?> get props => [id, subscriptionId, seq, percent, amountXaf, dueDate, status, proofPath, reviewNote];
}

/// One receipt a student sent for a part, with the school's decision (ADR 0022). Every receipt is kept, so the
/// subscription's history shows each payment. A part marked paid at the office has a receipt without a proof.
class InstallmentReceipt extends ValueObject {
  const InstallmentReceipt({
    required this.id,
    required this.subscriptionId,
    required this.seq,
    required this.sentAt,
    this.proofPath,
    this.decision,
    this.note,
    this.decidedAt,
  });

  factory InstallmentReceipt.fromJson(Map<String, dynamic> json) => InstallmentReceipt(
        id: reqString(json, 'id'),
        subscriptionId: reqString(json, 'subscription_id'),
        seq: reqInt(json, 'seq'),
        proofPath: optString(json, 'proof_path'),
        sentAt: reqTimestamp(json, 'sent_at'),
        // Only paid or rejected; anything else is read as not decided rather than guessed.
        decision: switch (json['decision']) {
          'paid' => InstallmentStatus.paid,
          'rejected' => InstallmentStatus.rejected,
          _ => null,
        },
        note: optString(json, 'note'),
        decidedAt: optTimestamp(json, 'decided_at'),
      );

  final String id;
  final String subscriptionId;
  final int seq;
  final String? proofPath;
  final DateTime sentAt;

  /// [InstallmentStatus.paid] or [InstallmentStatus.rejected]; null while the school has not decided.
  final InstallmentStatus? decision;
  final String? note;
  final DateTime? decidedAt;

  @override
  List<Object?> get props => [id, subscriptionId, seq, proofPath, sentAt, decision, note, decidedAt];
}
