/// School billing (ADR 0022): how students are billed, how they pay, and the installment plans a school may offer.
library;

/// How often a student pays: once a semester, or each calendar month (then each subscription covers one month).
enum BillingPeriod {
  semester,
  month;

  static BillingPeriod parse(Object? raw) => values.firstWhere((v) => v.name == raw, orElse: () => throw FormatException('Unknown billing period: $raw'));
  static BillingPeriod? tryParse(Object? raw) => raw == null ? null : parse(raw);
}

/// How a student pays a subscription: all at once, or in the parts of the school's plan.
enum PaymentMode {
  full,
  installments;

  static PaymentMode parse(Object? raw) => values.firstWhere((v) => v.name == raw, orElse: () => throw FormatException('Unknown payment mode: $raw'));
  static PaymentMode? tryParse(Object? raw) => raw == null ? null : parse(raw);
}

/// The installment plans a school can offer for a semester. The percentages of the price, part by part.
enum InstallmentPlan {
  halves('50-50', [50, 50]),
  thirds('40-30-30', [40, 30, 30]),
  smallLast('30-60-10', [30, 60, 10]);

  const InstallmentPlan(this.code, this.percents);

  /// As stored, for example `40-30-30`.
  final String code;
  final List<int> percents;

  static InstallmentPlan parse(Object? raw) =>
      values.firstWhere((v) => v.code == raw, orElse: () => throw FormatException('Unknown installment plan: $raw'));
  static InstallmentPlan? tryParse(Object? raw) => raw == null ? null : parse(raw);

  /// The amount of each part, in whole units, adding up to [total] exactly: each part is rounded down and the last one
  /// takes what is left. The server splits the same way.
  List<int> split(int total) {
    final parts = [for (final percent in percents.take(percents.length - 1)) total * percent ~/ 100];
    return [...parts, total - parts.fold(0, (sum, part) => sum + part)];
  }
}
