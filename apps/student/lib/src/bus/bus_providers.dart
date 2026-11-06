import 'package:busin_core/busin_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/access.dart';
import '../providers.dart';
import '../subscription/subscription_providers.dart';

final busesRepositoryProvider = Provider<BusesRepository>((ref) => ref.watch(repositoriesProvider).buses);
final livePositionsRepositoryProvider = Provider<LivePositionsRepository>((ref) => ref.watch(repositoriesProvider).livePositions);

/// A bus that is on a trip right now.
class RunningBus {
  const RunningBus({required this.trip, this.bus});

  final Trip trip;
  final Bus? bus;

  String get busId => trip.busId;

  /// The number plate, or an empty string if the bus could not be read.
  String get plate => bus?.plate ?? '';
}

/// Whether this student may follow buses live. The database answers it (an approved subscription covering today), and
/// the positions themselves are refused to anyone else, so this only decides what the tab explains.
final canFollowBusesProvider = FutureProvider.autoDispose<bool>((ref) async {
  if (ref.watch(accessProvider) is! Allowed) return false;
  return ref.watch(livePositionsRepositoryProvider).canFollowBuses();
});

/// The buses on a trip right now at the student's school, with their plates. A school runs a handful at a time.
final runningBusesProvider = FutureProvider.autoDispose<List<RunningBus>>((ref) async {
  if (ref.watch(accessProvider) is! Allowed) return const [];
  final trips = await ref.watch(tripsRepositoryProvider).listActive();
  if (trips.isEmpty) return const [];
  final buses = await ref.watch(busesRepositoryProvider).listByIds({for (final t in trips) t.busId}.toList());
  final byId = {for (final b in buses) b.id: b};
  return [for (final t in trips) RunningBus(trip: t, bus: byId[t.busId])];
});

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
});

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
});

/// The live position of one bus. The subscription is filtered to that bus on the server, and it ends
/// when the screen goes away, so a phone never receives other buses' positions or keeps listening in the background.
final busPositionProvider = StreamProvider.autoDispose.family<LivePosition, String>(
  (ref, busId) => ref.watch(livePositionsRepositoryProvider).watchBus(busId),
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
});

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
