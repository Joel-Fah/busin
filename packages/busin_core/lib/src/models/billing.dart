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

  /// The fewest days apart two parts may be.
  static const minDaysApart = 14;

  /// The fewest days of the semester, from the day a student asks, this plan needs: two weeks per part.
  int get minDays => minDaysApart * percents.length;

  /// The days a student asking on [today] has on the bus: from [today] (or the semester's first day, if later) to
  /// [semesterEnd], both included. Dates only; the times are ignored.
  static int daysLeft(DateTime today, DateTime semesterStart, DateTime semesterEnd) {
    final from = _day(today).isAfter(_day(semesterStart)) ? _day(today) : _day(semesterStart);
    return _day(semesterEnd).difference(from).inDays + 1;
  }

  /// Whether this plan is offered to a student asking on [today]: its parts must fit two weeks apart before the semester
  /// ends. Later, a student pays in full. The server checks the same (`installments_too_late`).
  bool fits(DateTime today, DateTime semesterStart, DateTime semesterEnd) => daysLeft(today, semesterStart, semesterEnd) >= minDays;

  /// When each part falls due for a student asking on [today]: part 1 that day, part k at (k - 1) / n of the way through
  /// the student's own time (from [today], or the semester's first day if later, to its last day). The server places
  /// them the same way.
  List<DateTime> dueDates(DateTime today, DateTime semesterStart, DateTime semesterEnd) {
    final n = percents.length;
    final from = _day(today).isAfter(_day(semesterStart)) ? _day(today) : _day(semesterStart);
    final days = daysLeft(today, semesterStart, semesterEnd).clamp(1, 1 << 30);
    return [for (var k = 1; k <= n; k++) k == 1 ? _day(today) : DateTime.utc(from.year, from.month, from.day + (k - 1) * days ~/ n)];
  }

  static DateTime _day(DateTime d) => DateTime.utc(d.year, d.month, d.day);
}
