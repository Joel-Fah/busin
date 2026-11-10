import 'package:busin_core/busin_core.dart';

enum ReminderKind { morning, evening }

/// One reminder to show at a wall-clock time at the school (no zone: the scheduler places it in the school's zone).
class PlannedReminder {
  const PlannedReminder({required this.id, required this.kind, required this.at});

  /// Stable within a plan: the kind and the day's offset from today, so a new plan replaces the old one cleanly.
  final int id;
  final ReminderKind kind;
  final DateTime at;

  @override
  String toString() => 'PlannedReminder($id, $kind, $at)';
}

/// How many days ahead reminders are placed. The app plans again whenever it opens or a preference changes, so two
/// weeks covers a student who does not open it for a while, and stays far below the platform's limit of pending alarms.
const reminderHorizonDays = 14;

/// The reminders for the coming days: only on the student's riding days, only inside the semester, only the kinds
/// switched on, and only times still to come. [now] is the wall clock at the school.
List<PlannedReminder> planReminders({
  required NotificationPreferences preferences,
  required DateTime semesterStart,
  required DateTime semesterEnd,
  required DateTime now,
  int days = reminderHorizonDays,
}) {
  final start = DateTime(semesterStart.year, semesterStart.month, semesterStart.day);
  final end = DateTime(semesterEnd.year, semesterEnd.month, semesterEnd.day);
  final plan = <PlannedReminder>[];
  for (var offset = 0; offset < days; offset++) {
    final day = DateTime(now.year, now.month, now.day + offset);
    if (day.isBefore(start) || day.isAfter(end)) continue;
    if (!preferences.ridingDays.contains(day.weekday)) continue;
    for (final kind in ReminderKind.values) {
      final on = kind == ReminderKind.morning ? preferences.morningOn : preferences.eveningOn;
      if (!on) continue;
      final time = kind == ReminderKind.morning ? preferences.morningTime : preferences.eveningTime;
      final at = DateTime(day.year, day.month, day.day, time.hour, time.minute);
      if (!at.isAfter(now)) continue;
      plan.add(PlannedReminder(id: (kind.index + 1) * 100 + offset, kind: kind, at: at));
    }
  }
  return plan;
}
