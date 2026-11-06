import 'package:busin_core/busin_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/access.dart';
import '../providers.dart';
import '../subscription/subscription_providers.dart';

/// One boarding as the History tab shows it.
class HistoryEntry {
  const HistoryEntry({required this.scan, required this.when, this.direction, this.stopName});

  final Scan scan;

  /// When it happened, as the clock on the school's wall read, with no zone.
  final DateTime when;
  final TripDirection? direction;
  final String? stopName;
}

/// Boardings on one calendar day at the school, newest first.
class HistoryDay {
  const HistoryDay(this.day, this.entries);

  final DateTime day;
  final List<HistoryEntry> entries;
}

/// Groups newest-first entries by the day they happened at the school. Keeps the order.
List<HistoryDay> groupByDay(List<HistoryEntry> entries) {
  final days = <HistoryDay>[];
  for (final entry in entries) {
    final day = DateTime(entry.when.year, entry.when.month, entry.when.day);
    if (days.isNotEmpty && days.last.day == day) {
      days.last.entries.add(entry);
    } else {
      days.add(HistoryDay(day, [entry]));
    }
  }
  return days;
}

class HistoryState {
  const HistoryState({required this.entries, required this.hasMore, this.loadingMore = false, this.loadMoreFailed = false});

  final List<HistoryEntry> entries;
  final bool hasMore;
  final bool loadingMore;
  final bool loadMoreFailed;

  HistoryState copyWith({List<HistoryEntry>? entries, bool? hasMore, bool? loadingMore, bool? loadMoreFailed}) => HistoryState(
        entries: entries ?? this.entries,
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
        loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      );
}

/// A page is as many rows as fit a few screens: enough to feel instant, small enough to be cheap.
const historyPageSize = 20;

/// The student's boardings, a page at a time. Reading the first page happens when the tab is first built;
/// [loadMore] adds the next as the list is scrolled. It resets with the user.
class ScanHistory extends AsyncNotifier<HistoryState> {
  @override
  Future<HistoryState> build() async {
    final access = ref.watch(accessProvider);
    if (access is! Allowed) throw StateError('History is only for an allowed student.');
    final entries = await _page(access.profile.id, 0);
    return HistoryState(entries: entries, hasMore: entries.length == historyPageSize);
  }

  /// Loads the next page. After a failed page only an explicit [retry] tries again, so scrolling cannot
  /// hammer a server that just refused.
  Future<void> loadMore({bool retry = false}) async {
    final current = state.value;
    final access = ref.read(accessProvider);
    if (current == null || access is! Allowed || !current.hasMore || current.loadingMore) return;
    if (current.loadMoreFailed && !retry) return;

    state = AsyncData(current.copyWith(loadingMore: true, loadMoreFailed: false));
    try {
      final more = await _page(access.profile.id, current.entries.length);
      state = AsyncData(HistoryState(entries: [...current.entries, ...more], hasMore: more.length == historyPageSize));
    } catch (_) {
      // Keep what is on screen and offer a retry at the end of the list.
      state = AsyncData(current.copyWith(loadingMore: false, loadMoreFailed: true));
    }
  }

  Future<List<HistoryEntry>> _page(String studentId, int offset) async {
    final scans = await ref.read(scansRepositoryProvider).listForStudent(studentId, page: PageRequest(limit: historyPageSize, offset: offset));
    if (scans.isEmpty) return const [];

    final school = await ref.read(schoolProvider.future);
    final clock = ref.read(schoolClockProvider);

    // One request for the trips of this page, and the cached stop list for names.
    final trips = await ref.read(tripsRepositoryProvider).listByIds({for (final s in scans) s.tripId}.toList());
    final directionOf = {for (final t in trips) t.id: t.direction};
    final stops = await ref.read(stopsProvider.future);
    final nameOf = {for (final s in stops) s.id: s.name};

    return [
      for (final scan in scans)
        HistoryEntry(
          scan: scan,
          when: clock.wallClock(school.timezone, scan.scannedAt),
          direction: directionOf[scan.tripId],
          stopName: scan.stopId == null ? null : (nameOf[scan.stopId] ?? await _stopName(scan.stopId!)),
        ),
    ];
  }

  /// A stop that is no longer active is not in the cached list; ask for it by id and live without it if refused.
  Future<String?> _stopName(String id) async {
    try {
      return (await ref.read(stopsRepositoryProvider).getStop(id)).name;
    } catch (_) {
      return null;
    }
  }
}

final scanHistoryProvider = AsyncNotifierProvider.autoDispose<ScanHistory, HistoryState>(ScanHistory.new);
