import 'dart:async';

import 'package:busin_core/busin_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/access.dart';
import '../providers.dart';
import '../subscription/subscription_providers.dart';
import 'bus_updates.dart';

final busesRepositoryProvider = Provider<BusesRepository>((ref) => ref.watch(repositoriesProvider).buses);
final livePositionsRepositoryProvider = Provider<LivePositionsRepository>((ref) => ref.watch(repositoriesProvider).livePositions);

/// A bus that is on a trip right now.
class RunningBus {
  const RunningBus({required this.trip, this.bus});

  final Trip trip;
  final Bus? bus;

  String get busId => trip.busId;

  /// What the bus is called (its name, or its plate), or an empty string if the bus could not be read.
  String get label => bus?.label ?? '';
}

/// Whether this student may follow buses live. The database answers it (an approved subscription covering today), and
/// the positions themselves are refused to anyone else, so this only decides what the tab explains.
final canFollowBusesProvider = FutureProvider.autoDispose<bool>((ref) async {
  if (ref.watch(accessProvider) is! Allowed) return false;
  return ref.watch(livePositionsRepositoryProvider).canFollowBuses();
}, retry: noAutomaticRetry);

/// The buses on a trip right now at the student's school, with their names or plates. A school runs a handful at a time.
final runningBusesProvider = FutureProvider.autoDispose<List<RunningBus>>((ref) async {
  if (ref.watch(accessProvider) is! Allowed) return const [];
  final trips = await ref.watch(tripsRepositoryProvider).listActive();
  if (trips.isEmpty) return const [];
  final buses = await ref.watch(busesRepositoryProvider).listByIds({for (final t in trips) t.busId}.toList());
  final byId = {for (final b in buses) b.id: b};
  return [for (final t in trips) RunningBus(trip: t, bus: byId[t.busId])];
}, retry: noAutomaticRetry);

/// The bus the student picked by hand, if any.
class SelectedBus extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String busId) => state = busId;
}

final selectedBusIdProvider = NotifierProvider.autoDispose<SelectedBus, String?>(SelectedBus.new);

/// Which running bus to show when the student has not chosen: the one on the trip they boarded last, if it is
/// still running, otherwise the one that started most recently.
final defaultBusIdProvider = FutureProvider.autoDispose<String?>((ref) async {
  final access = ref.watch(accessProvider);
  if (access is! Allowed) return null;
  final running = await ref.watch(runningBusesProvider.future);
  if (running.isEmpty) return null;

  final latest = await ref.watch(scansRepositoryProvider).listForStudent(access.profile.id, page: const PageRequest(limit: 1));
  if (latest.isNotEmpty) {
    for (final r in running) {
      if (r.trip.id == latest.first.tripId) return r.busId;
    }
  }
  return running.first.busId;
}, retry: noAutomaticRetry);

/// The bus on screen: the student's pick if it is still running, otherwise the default.
final currentBusProvider = FutureProvider.autoDispose<RunningBus?>((ref) async {
  final running = await ref.watch(runningBusesProvider.future);
  if (running.isEmpty) return null;
  final selected = ref.watch(selectedBusIdProvider);
  if (selected != null) {
    for (final r in running) {
      if (r.busId == selected) return r;
    }
  }
  final fallback = await ref.watch(defaultBusIdProvider.future);
  return running.firstWhere((r) => r.busId == fallback, orElse: () => running.first);
}, retry: noAutomaticRetry);

/// The live position of one bus. The subscription is filtered to that bus on the server, and it ends
/// when the screen goes away, so a phone never receives other buses' positions or keeps listening in the background.
final busPositionProvider = StreamProvider.autoDispose.family<LivePosition, String>(
  (ref, busId) => ref.watch(livePositionsRepositoryProvider).watchBus(busId),
  retry: noAutomaticRetry,
);

/// The student's own stop (from their live subscription), to mark on the map.
final myStopProvider = FutureProvider.autoDispose<Stop?>((ref) async {
  final access = ref.watch(accessProvider);
  if (access is! Allowed) return null;
  final mine = await ref.watch(subscriptionsRepositoryProvider).listForStudent(access.profile.id, page: const PageRequest(limit: 20));
  final live = mine.where((s) => s.isLive).firstOrNull;
  if (live == null) return null;
  final stops = await ref.watch(stopsProvider.future);
  return stops.where((s) => s.id == live.stopId).firstOrNull;
}, retry: noAutomaticRetry);

// ---------------------------------------------------------------- plain helpers

/// How long ago a position was recorded. Never negative (a phone clock a little behind the server's).
Duration positionAge(LivePosition position, DateTime now) {
  final age = now.difference(position.recordedAt);
  return age.isNegative ? Duration.zero : age;
}

/// A position older than this means the bus has probably lost signal.
const stalePositionAfter = Duration(minutes: 2);

bool isStale(Duration age) => age >= stalePositionAfter;

/// Metres per second to whole kilometres per hour; null when the speed is unknown or the bus is standing.
int? speedKmh(double? metresPerSecond) {
  if (metresPerSecond == null) return null;
  final kmh = (metresPerSecond * 3.6).round();
  return kmh <= 0 ? null : kmh;
}

// ---------------------------------------------------------------- live updates

/// How often "no signal" is checked between positions.
const updateTick = Duration(seconds: 15);

/// The short updates of each running trip (bus_updates.dart), newest first, at most [keptUpdates] per trip, with the
/// detector that keeps track of what the bus did. Kept for the app's life (not the tab's), so switching tabs and coming
/// back finds them again; a trip's entry goes when it ends, and everything goes on sign-out. Never stored or pushed.
class BusUpdateLog extends Notifier<Map<String, List<BusUpdate>>> {
  final _detectors = <String, BusUpdateDetector>{};

  @override
  Map<String, List<BusUpdate>> build() {
    // Another person signed in (or nobody): nothing of the previous one's follows them.
    ref.watch(authUserIdProvider.select((user) => user.value));
    _detectors.clear();
    return const {};
  }

  /// The detector of [tripId], made with [make] the first time.
  BusUpdateDetector detectorFor(String tripId, BusUpdateDetector Function() make) => _detectors.putIfAbsent(tripId, make);

  void add(String tripId, BusUpdate update) => state = {...state, tripId: [update, ...(state[tripId] ?? const []).take(keptUpdates - 1)]};

  /// The trip ended: its updates and detector go.
  void forget(String tripId) {
    _detectors.remove(tripId);
    if (state.containsKey(tripId)) state = {...state}..remove(tripId);
  }
}

const keptUpdates = 5;

final busUpdateLogProvider = NotifierProvider<BusUpdateLog, Map<String, List<BusUpdate>>>(BusUpdateLog.new);

/// Feeds [busUpdateLogProvider] from one followed bus while My bus shows it: each position, and a check for "no news"
/// every [updateTick]. Dropped when the tab is hidden (the live position stops with it); the log stays. When the bus
/// falls silent the running trips are read again, so the screen learns soon if the trip has ended.
class BusUpdateFeeder extends Notifier<int> {
  BusUpdateFeeder(this.key);

  final ({String busId, String tripId}) key;

  @override
  int build() {
    DateTime now() => ref.read(nowProvider)();
    final log = ref.read(busUpdateLogProvider.notifier);
    // Made with the first position, when the stops are known; kept in the log so a return to the tab carries on.
    BusUpdateDetector detector() => log.detectorFor(
          key.tripId,
          () => BusUpdateDetector(stops: ref.read(stopsProvider).value ?? const [], myStop: ref.read(myStopProvider).value),
        );
    ref.listen(busPositionProvider(key.busId), (_, next) {
      final position = next.value;
      if (position == null) return;
      final update = detector().onPosition(position, now());
      if (update != null) log.add(key.tripId, update);
    }, fireImmediately: true);
    final timer = Timer.periodic(updateTick, (_) {
      final update = detector().onTick(now());
      if (update == null) return;
      log.add(key.tripId, update);
      ref.invalidate(runningBusesProvider);
    });
    ref.onDispose(timer.cancel);
    return 0;
  }
}

final busUpdateFeederProvider =
    NotifierProvider.autoDispose.family<BusUpdateFeeder, int, ({String busId, String tripId})>(BusUpdateFeeder.new);

/// The updates of one trip, newest first.
final busUpdatesProvider = Provider.family<List<BusUpdate>, String>((ref, tripId) => ref.watch(busUpdateLogProvider)[tripId] ?? const []);

/// Asks the map to move to the student (Show me): each new number is one request.
class FocusMe extends Notifier<int> {
  @override
  int build() => 0;

  void request() => state++;
}

final focusMeProvider = NotifierProvider<FocusMe, int>(FocusMe.new);
