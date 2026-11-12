import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../access.dart';
import '../providers.dart';

/// How far ahead "Coming up" looks.
const upcomingWeeks = 4;

/// How many weeks the stats cover.
const statsWeeks = 12;

/// The Monday of [day]'s week (a plain date, as [SchoolClock.today] gives).
DateTime mondayOf(DateTime day) {
  final date = DateTime(day.year, day.month, day.day);
  return date.subtract(Duration(days: date.weekday - DateTime.monday));
}

/// Items grouped by their week at the school (Monday to Sunday), in the order given; [at] says when each one is.
List<({DateTime monday, List<T> items})> groupByWeek<T>(Iterable<T> items, DateTime Function(T item) at, {required String zone, SchoolClock clock = const SchoolClock()}) {
  final groups = <({DateTime monday, List<T> items})>[];
  for (final item in items) {
    final monday = mondayOf(clock.today(zone, now: at(item)));
    if (groups.isEmpty || groups.last.monday != monday) groups.add((monday: monday, items: <T>[]));
    groups.last.items.add(item);
  }
  return groups;
}

/// "This week", "Next week", "Last week", or "Week of 23 Nov".
String weekLabel(BuildContext context, DateTime monday, {required DateTime thisMonday}) {
  final l10n = BusinL10n.of(context);
  final weeks = (DateTime.utc(monday.year, monday.month, monday.day).difference(DateTime.utc(thisMonday.year, thisMonday.month, thisMonday.day)).inDays / 7).round();
  return switch (weeks) {
    0 => l10n.opsWeekThis,
    1 => l10n.opsWeekNext,
    -1 => l10n.opsWeekLast,
    _ => l10n.opsWeekOf(MaterialLocalizations.of(context).formatShortMonthDay(monday)),
  };
}

/// The Monday of this week at the school.
final thisMondayProvider = Provider.autoDispose<DateTime>((ref) {
  final zone = ref.watch(schoolProvider).value?.timezone ?? 'UTC';
  return mondayOf(ref.watch(schoolClockProvider).today(zone, now: ref.read(nowProvider)()));
});

/// The trips assigned to me after today, for the next [upcomingWeeks] weeks, soonest first.
final upcomingTripsProvider = FutureProvider.autoDispose<List<Trip>>((ref) async {
  final access = ref.watch(accessProvider);
  if (access is! OpsAllowed) return const [];
  final school = await ref.watch(schoolProvider.future);
  final clock = ref.watch(schoolClockProvider);
  final today = clock.today(school.timezone, now: ref.read(nowProvider)());
  final from = clock.dayStart(school.timezone, today.add(const Duration(days: 1)));
  final to = clock.dayStart(school.timezone, today.add(const Duration(days: 1 + upcomingWeeks * 7)));
  return ref.watch(tripsRepositoryProvider).listForCrew(access.profile.id, from: from, to: to);
}, retry: noAutomaticRetry);

/// The buses of the trips coming up, by id.
final upcomingBusesProvider = FutureProvider.autoDispose<Map<String, Bus>>((ref) async {
  final trips = await ref.watch(upcomingTripsProvider.future);
  final ids = {for (final trip in trips) trip.busId}.toList();
  if (ids.isEmpty) return const {};
  final buses = await ref.watch(busesRepositoryProvider).listByIds(ids);
  return {for (final bus in buses) bus.id: bus};
}, retry: noAutomaticRetry);

/// My past trips, loaded a page at a time as the list scrolls.
class TripHistory {
  const TripHistory({this.items = const [], this.done = false, this.loadingMore = false, this.moreFailed = false});

  final List<TripHistoryEntry> items;

  /// Everything is loaded.
  final bool done;
  final bool loadingMore;

  /// The last attempt at the next page failed (offline, for example); the list offers to try again.
  final bool moreFailed;

  TripHistory copyWith({List<TripHistoryEntry>? items, bool? done, bool? loadingMore, bool? moreFailed}) => TripHistory(
        items: items ?? this.items,
        done: done ?? this.done,
        loadingMore: loadingMore ?? this.loadingMore,
        moreFailed: moreFailed ?? this.moreFailed,
      );
}

class TripHistoryNotifier extends AsyncNotifier<TripHistory> {
  static const pageSize = 20;

  @override
  Future<TripHistory> build() async {
    final access = ref.watch(accessProvider);
    if (access is! OpsAllowed) return const TripHistory(done: true);
    final school = await ref.watch(schoolProvider.future);
    final clock = ref.watch(schoolClockProvider);
    // Today's trips are on the Trips tab; history starts before today.
    final before = clock.dayStart(school.timezone, clock.today(school.timezone, now: ref.read(nowProvider)()));
    final page = await ref.watch(tripsRepositoryProvider).myHistory(before: before, limit: pageSize);
    return TripHistory(items: page, done: page.length < pageSize);
  }

  /// The next page, after the oldest trip loaded.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.done || current.loadingMore || current.items.isEmpty) return;
    state = AsyncData(current.copyWith(loadingMore: true, moreFailed: false));
    try {
      final page = await ref.read(tripsRepositoryProvider).myHistory(before: current.items.last.scheduledStart, limit: pageSize);
      // Two trips can share a start time: one already shown is not added twice.
      final known = {for (final e in current.items) e.id};
      state = AsyncData(current.copyWith(items: [...current.items, ...page.where((e) => !known.contains(e.id))], done: page.length < pageSize, loadingMore: false));
    } catch (_) {
      state = AsyncData(current.copyWith(loadingMore: false, moreFailed: true));
    }
  }
}

final tripHistoryProvider = AsyncNotifierProvider.autoDispose<TripHistoryNotifier, TripHistory>(TripHistoryNotifier.new, retry: noAutomaticRetry);

/// My last [statsWeeks] weeks, oldest first.
final myStatsProvider = FutureProvider.autoDispose<List<WeekStats>>((ref) {
  if (ref.watch(accessProvider) is! OpsAllowed) return const [];
  return ref.watch(tripsRepositoryProvider).myStats(weeks: statsWeeks);
}, retry: noAutomaticRetry);

/// Whether punctuality went up, down or held: the last 4 weeks against the 4 before, when both have timed trips.
enum Trend { up, down, steady }

Trend? punctualityTrend(List<WeekStats> weeks) {
  if (weeks.length < 8) return null;
  final recent = StatsSummary(weeks.sublist(weeks.length - 4)).punctuality;
  final before = StatsSummary(weeks.sublist(weeks.length - 8, weeks.length - 4)).punctuality;
  if (recent == null || before == null) return null;
  final change = recent - before;
  if (change >= 0.05) return Trend.up;
  if (change <= -0.05) return Trend.down;
  return Trend.steady;
}

/// "45 min" or "2 h 05 min".
String durationLabel(BusinL10n l10n, int minutes) {
  if (minutes < 60) return l10n.opsMinutes(minutes);
  return l10n.opsHoursMinutes(minutes ~/ 60, minutes % 60);
}
