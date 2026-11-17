/// Mobile money payments (ADR 0029): the operators, Cameroonian numbers, a payment and where it stands, the price of each
/// way of paying, and why a payment did not go through. The server starts and finishes every payment; the apps only ask
/// for it and follow it.
library;

import '../json.dart';
import '../value_object.dart';

/// The mobile money operators BusIn takes, by pawaPay's code.
enum MobileMoneyOperator {
  mtn('MTN_MOMO_CMR'),
  orange('ORANGE_CMR');

  const MobileMoneyOperator(this.code);

  final String code;

  static MobileMoneyOperator? tryParse(Object? raw) {
    for (final v in values) {
      if (v.code == raw) return v;
    }
    return null;
  }

  static MobileMoneyOperator parse(Object? raw) => tryParse(raw) ?? (throw FormatException('Unknown operator: $raw'));
}

/// Cameroonian mobile numbers as pawaPay takes them (2376XXXXXXXX). The server applies the same rules.
abstract final class MobileMoneyNumber {
  /// The number in pawaPay's form from what a person typed ("6 53 45 67 89", "+237 653456789", "00237653456789"), or
  /// null when it is not a Cameroonian mobile number.
  static String? normalize(String input) {
    var digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.length == 9) digits = '237$digits';
    return RegExp(r'^2376[0-9]{8}$').hasMatch(digits) ? digits : null;
  }

  static const _mtn = ['650', '651', '652', '653', '654', '67', '680', '681', '682', '683'];
  static const _orange = ['655', '656', '657', '658', '659', '69'];

  /// The operator a number most likely belongs to, from its range, as it is typed (three digits are enough). A first
  /// guess only: numbers move between operators, so the server asks pawaPay before paying, and the payer can change it.
  static MobileMoneyOperator? guessOperator(String input) {
    var digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    // Local numbers start with 6, so a leading 2376 is the country code, even half typed.
    if (digits.startsWith('2376')) digits = digits.substring(3);
    if (_mtn.any(digits.startsWith)) return MobileMoneyOperator.mtn;
    if (_orange.any(digits.startsWith)) return MobileMoneyOperator.orange;
    return null;
  }

  /// The number as a person reads it: 6 53 45 67 89.
  static String display(String msisdn) {
    final local = msisdn.startsWith('237') ? msisdn.substring(3) : msisdn;
    if (local.length != 9) return msisdn;
    return '${local[0]} ${local.substring(1, 3)} ${local.substring(3, 5)} ${local.substring(5, 7)} ${local.substring(7)}';
  }
}

/// What a payment pays for.
enum PaymentPurpose {
  /// A pending request, in full or its first part.
  subscription,

  /// A later installment part.
  installment;
}

enum PaymentStatus {
  initiated('initiated'),
  accepted('accepted'),
  processing('processing'),
  inReconciliation('in_reconciliation'),
  completed('completed'),
  failed('failed'),

  /// Something BusIn has to check by hand (an amount that does not match, an unknown answer). Nothing for the payer to do.
  needsAttention('needs_attention');

  const PaymentStatus(this.code);

  final String code;

  static PaymentStatus parse(Object? raw) =>
      values.firstWhere((v) => v.code == raw, orElse: () => throw FormatException('Unknown payment status: $raw'));

  /// Waiting for the payer's PIN, or for the operator.
  bool get waiting => this == initiated || this == accepted || this == processing || this == inReconciliation;
}

/// Why a payment did not go through, as the apps explain it. From pawaPay's failure codes; anything else is [other].
enum PaymentFailure {
  /// The PIN was not entered in time, or the prompt was declined.
  notApproved,
  insufficientBalance,

  /// The number has no account with this operator.
  payerNotFound,
  limitReached,

  /// Another payment is waiting on the payer's phone.
  otherPending,
  operatorDown,
  amountOutOfBounds,
  invalidNumber,

  /// It never reached the operator.
  notReached,
  other;

  static PaymentFailure fromCode(String? code) => switch (code) {
        'PAYMENT_NOT_APPROVED' => notApproved,
        'INSUFFICIENT_BALANCE' => insufficientBalance,
        'PAYER_NOT_FOUND' => payerNotFound,
        'PAYER_LIMIT_REACHED' || 'WALLET_LIMIT_REACHED' => limitReached,
        'PAYMENT_IN_PROGRESS' => otherPending,
        'PROVIDER_TEMPORARILY_UNAVAILABLE' => operatorDown,
        'AMOUNT_OUT_OF_BOUNDS' => amountOutOfBounds,
        'INVALID_PHONE_NUMBER' => invalidNumber,
        'NOT_FOUND' => notReached,
        _ => other,
      };
}

/// One mobile money payment, as the payer reads it. The amounts were fixed when it started.
class Payment extends ValueObject {
  const Payment({
    required this.id,
    required this.purpose,
    required this.amountXaf,
    required this.feeXaf,
    required this.totalXaf,
    required this.operator,
    required this.payerMasked,
    required this.status,
    required this.createdAt,
    this.subscriptionId,
    this.installmentId,
    this.failureCode,
    this.providerTxn,
    this.receiptNo,
    this.refunded = false,
    this.completedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: reqString(json, 'id'),
        purpose: PaymentPurpose.values.byName(reqString(json, 'purpose')),
        subscriptionId: optString(json, 'subscription_id'),
        installmentId: optString(json, 'installment_id'),
        amountXaf: reqInt(json, 'amount_xaf'),
        feeXaf: reqInt(json, 'fee_xaf'),
        totalXaf: reqInt(json, 'total_xaf'),
        operator: MobileMoneyOperator.parse(json['provider']),
        payerMasked: reqString(json, 'payer_masked'),
        status: PaymentStatus.parse(json['status']),
        failureCode: optString(json, 'failure_code'),
        providerTxn: optString(json, 'provider_txn'),
        receiptNo: optString(json, 'receipt_no'),
        refunded: json['outcome'] == 'refunded',
        createdAt: reqTimestamp(json, 'created_at'),
        completedAt: optTimestamp(json, 'completed_at'),
      );

  final String id;
  final PaymentPurpose purpose;
  final String? subscriptionId;
  final String? installmentId;

  /// What goes to the school, the mobile money fee on top, and what the payer was asked for.
  final int amountXaf;
  final int feeXaf;
  final int totalXaf;
  final MobileMoneyOperator operator;

  /// The payer's number, partly hidden (2376*****789).
  final String payerMasked;
  final PaymentStatus status;
  final String? failureCode;

  /// The operator's transaction id, as it shows on the payer's own receipt.
  final String? providerTxn;

  /// BusIn's receipt number, once paid.
  final String? receiptNo;

  /// Paid, but the request could no longer take it: it is being refunded in full.
  final bool refunded;
  final DateTime createdAt;
  final DateTime? completedAt;

  PaymentFailure? get failure => status == PaymentStatus.failed ? PaymentFailure.fromCode(failureCode) : null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'purpose': purpose.name,
        'subscription_id': subscriptionId,
        'installment_id': installmentId,
        'amount_xaf': amountXaf,
        'fee_xaf': feeXaf,
        'total_xaf': totalXaf,
        'provider': operator.code,
        'payer_masked': payerMasked,
        'status': status.code,
        'failure_code': failureCode,
        'provider_txn': providerTxn,
        'receipt_no': receiptNo,
        'outcome': refunded ? 'refunded' : null,
        'created_at': createdAt.toUtc().toIso8601String(),
        'completed_at': completedAt?.toUtc().toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        purpose,
        subscriptionId,
        installmentId,
        amountXaf,
        feeXaf,
        totalXaf,
        operator,
        payerMasked,
        status,
        failureCode,
        providerTxn,
        receiptNo,
        refunded,
        createdAt,
        completedAt,
      ];
}

/// What paying one thing by mobile money costs with one operator. [feeXaf] and [totalXaf] are null when that operator
/// cannot be used now.
class PaymentQuote extends ValueObject {
  const PaymentQuote({required this.operator, required this.amountXaf, this.feeXaf, this.totalXaf});

  factory PaymentQuote.fromJson(Map<String, dynamic> json) => PaymentQuote(
        operator: MobileMoneyOperator.parse(json['provider']),
        amountXaf: reqInt(json, 'amount_xaf'),
        feeXaf: optInt(json, 'fee_xaf'),
        totalXaf: optInt(json, 'total_xaf'),
      );

  final MobileMoneyOperator operator;
  final int amountXaf;
  final int? feeXaf;
  final int? totalXaf;

  bool get available => totalXaf != null;

  @override
  List<Object?> get props => [operator, amountXaf, feeXaf, totalXaf];
}

/// What a subscription costs paying one way: by receipt ([operator] null) or by mobile money with an operator.
class PriceLine extends ValueObject {
  const PriceLine({required this.studentPays, required this.chargeXaf, required this.transactionCost, this.operator});

  factory PriceLine.fromJson(Map<String, dynamic> json) {
    final method = reqString(json, 'method');
    return PriceLine(
      operator: method == 'receipt' ? null : MobileMoneyOperator.parse(method),
      studentPays: reqInt(json, 'student_pays'),
      chargeXaf: reqInt(json, 'busin_charge'),
      transactionCost: reqInt(json, 'transaction_cost'),
    );
  }

  final MobileMoneyOperator? operator;
  final int studentPays;
  final int chargeXaf;
  final int transactionCost;

  @override
  List<Object?> get props => [operator, studentPays, chargeXaf, transactionCost];
}

/// The ways a student's school lets them pay, from its price lines: mobile money is offered when an operator has a line.
extension PriceLines on List<PriceLine> {
  bool get offersMobileMoney => any((l) => l.operator != null);

  PriceLine? get receipt => where((l) => l.operator == null).firstOrNull;

  PriceLine? forOperator(MobileMoneyOperator operator) => where((l) => l.operator == operator).firstOrNull;
}
