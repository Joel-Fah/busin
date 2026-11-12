import 'package:busin_app/busin_app.dart';
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

/// What the sheet that starts a trip nobody scheduled offers (ADR 0020). The Today screen shows its button only when the
/// school allows it.
final fieldTripOptionsProvider = FutureProvider.autoDispose<FieldTripOptions>(
  (ref) => ref.watch(tripsRepositoryProvider).fieldTripOptions(),
  retry: noAutomaticRetry,
);

/// The trip just started in the field: its screen offers sharing the position when it opens, as starting a listed trip
/// does.
class ShareOffer extends Notifier<String?> {
  @override
  String? build() => null;

  void offer(String tripId) => state = tripId;
  void clear() => state = null;
}

final shareOfferProvider = NotifierProvider<ShareOffer, String?>(ShareOffer.new);

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

/// Whether a trip is scheduled for the school's today (its own timezone). The server refuses to start any other day
/// (`trip_not_today`), so the app does not offer Start for one.
bool tripIsToday({required SchoolClock clock, required String zone, required DateTime scheduledStart, required DateTime now}) =>
    clock.today(zone, now: scheduledStart) == clock.today(zone, now: now);

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
