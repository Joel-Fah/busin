import 'package:busin_core/busin_core.dart';

/// The rules of school billing the student app needs (ADR 0022), kept pure so each case is a unit test. Dates from the
/// API are UTC midnights; the school's day ([SchoolClock.today]) is a local date: both are compared as calendar days.

DateTime calendarDay(DateTime day) => DateTime.utc(day.year, day.month, day.day);

bool sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

/// A live subscription still counts while its month (or its semester) has not ended. A monthly one whose month is over
/// leaves room to ask for the next.
bool stillRunning(Subscription s, DateTime today) => s.periodEnd == null || !s.periodEnd!.isBefore(calendarDay(today));

/// The months a student may ask for: this month and the next, when they overlap the semester and have no live request.
List<DateTime> monthChoices({required Semester semester, required DateTime today, required Iterable<Subscription> live}) {
  final thisMonth = DateTime.utc(today.year, today.month);
  final candidates = [thisMonth, DateTime.utc(today.year, today.month + 1)];
  return [
    for (final month in candidates)
      if (!month.isAfter(semester.endDate) &&
          !DateTime.utc(month.year, month.month + 1, 0).isBefore(semester.startDate) &&
          !live.any((s) => s.periodStart != null && sameMonth(s.periodStart!, month)))
        month,
  ];
}

/// What the student pays now, given how they pay: the whole price, or the first part of the plan.
int dueNow({required int price, InstallmentPlan? plan, required PaymentMode mode}) =>
    mode == PaymentMode.installments && plan != null ? plan.split(price).first : price;
