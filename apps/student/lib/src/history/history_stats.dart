import 'history_providers.dart';

/// The two numbers at the top of the history, worked out from the boardings that are loaded (the newest ones).
class HistoryStats {
  const HistoryStats({required this.thisWeek, this.topStop, this.topStopCount = 0});

  /// Boardings in the last seven days, today included.
  final int thisWeek;

  /// The stop used most often, with how often; null when no boarding names a stop.
  final String? topStop;
  final int topStopCount;
}

/// [today] is the calendar day at the school (no time of day), as [HistoryEntry.when] is the school's wall clock.
HistoryStats statsFor(List<HistoryEntry> entries, DateTime today) {
  final first = today.subtract(const Duration(days: 6));
  var week = 0;
  final counts = <String, int>{};
  final order = <String>[];
  for (final e in entries) {
    final day = DateTime(e.when.year, e.when.month, e.when.day);
    if (!day.isBefore(first) && !day.isAfter(today)) week++;
    final name = e.stopName;
    if (name != null) {
      if (!counts.containsKey(name)) order.add(name);
      counts[name] = (counts[name] ?? 0) + 1;
    }
  }
  String? top;
  var best = 0;
  // On a tie the stop used most recently wins (entries are newest first, so it is met first).
  for (final name in order) {
    if (counts[name]! > best) {
      best = counts[name]!;
      top = name;
    }
  }
  return HistoryStats(thisWeek: week, topStop: top, topStopCount: best);
}

/// What one day looked like, for the summary beside the list.
class DaySummary {
  const DaySummary({required this.count, required this.first, required this.last, required this.stops});

  final int count;

  /// Earliest and latest boarding of the day (wall clock).
  final DateTime first;
  final DateTime last;

  /// The stops used, in the order they were first used that day, without repeats.
  final List<String> stops;
}

DaySummary summarizeDay(HistoryDay day) {
  // Entries are newest first.
  final chronological = day.entries.reversed.toList();
  final stops = <String>[];
  for (final e in chronological) {
    final name = e.stopName;
    if (name != null && !stops.contains(name)) stops.add(name);
  }
  return DaySummary(count: day.entries.length, first: chronological.first.when, last: chronological.last.when, stops: stops);
}
