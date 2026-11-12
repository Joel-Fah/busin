import 'package:busin_core/busin_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../access.dart';
import '../providers.dart';

/// Today's trips at the school (its time zone), soonest first.
final todayTripsProvider = FutureProvider.autoDispose<List<Trip>>((ref) async {
  final school = await ref.watch(schoolProvider.future);
  final clock = ref.watch(schoolClockProvider);
  final today = clock.today(school.timezone, now: ref.read(nowProvider)());
  final from = clock.dayStart(school.timezone, today);
  final to = clock.dayStart(school.timezone, today.add(const Duration(days: 1)));
  return ref.watch(tripsRepositoryProvider).listBetween(from: from, to: to);
}, retry: noAutomaticRetry);

/// The buses of today's trips, by id (for their names and seats).
final todayBusesProvider = FutureProvider.autoDispose<Map<String, Bus>>((ref) async {
  final trips = await ref.watch(todayTripsProvider.future);
  final ids = {for (final trip in trips) trip.busId}.toList();
  final buses = await ref.watch(busesRepositoryProvider).listByIds(ids);
  return {for (final bus in buses) bus.id: bus};
}, retry: noAutomaticRetry);

/// One trip, fresh from the server.
final tripProvider = FutureProvider.autoDispose.family<Trip, String>((ref, id) => ref.watch(tripsRepositoryProvider).getTrip(id), retry: noAutomaticRetry);

/// The bus of one trip.
final tripBusProvider = FutureProvider.autoDispose.family<Bus?, String>((ref, id) async {
  final trip = await ref.watch(tripProvider(id).future);
  final buses = await ref.watch(busesRepositoryProvider).listByIds([trip.busId]);
  return buses.firstOrNull;
}, retry: noAutomaticRetry);

/// Who has boarded a trip.
final manifestProvider = FutureProvider.autoDispose.family<List<ManifestEntry>, String>(
  (ref, id) => ref.watch(tripsRepositoryProvider).manifest(id),
  retry: noAutomaticRetry,
);

/// Today's trips split for the list: the ones I am on the crew of (driver or assistant) first, then the others.
({List<Trip> mine, List<Trip> others}) splitTrips(List<Trip> trips, String userId) => (
      mine: [for (final t in trips) if (t.isCrew(userId)) t],
      others: [for (final t in trips) if (!t.isCrew(userId)) t],
    );

/// Why starting a trip was refused, worked out from what the app knows (the server says only "conflict").
enum StartRefusal { notToday, busBusy, notScheduled }

StartRefusal startRefusal({required Trip trip, required List<Trip> today, required bool isToday}) {
  if (!isToday) return StartRefusal.notToday;
  if (today.any((t) => t.id != trip.id && t.busId == trip.busId && t.status == TripStatus.active)) return StartRefusal.busBusy;
  return StartRefusal.notScheduled;
}

/// The signed-in staff member, for the trip rules.
({String userId, bool isAdmin})? staffOf(OpsAccess access) =>
    access is OpsAllowed ? (userId: access.profile.id, isAdmin: access.isAdmin) : null;
