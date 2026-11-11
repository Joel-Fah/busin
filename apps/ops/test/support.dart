import 'dart:async';

import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'dart:typed_data';

import 'package:busin_ops/src/keys/roster.dart';
import 'package:busin_ops/src/providers.dart';
import 'package:busin_ops/src/queue/scan_queue.dart';
import 'package:busin_ops/src/scan/scan_providers.dart';
import 'package:busin_ops/src/scan/scanner_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

const schoolId = 's1';

Profile staff({String id = 'u1', UserRole role = UserRole.staff, AccountStatus status = AccountStatus.verified}) => Profile(
      id: id,
      schoolId: schoolId,
      email: '$id@school.edu',
      fullName: 'Sam Staff',
      role: role,
      status: status,
      createdAt: DateTime.utc(2026, 9, 1),
      updatedAt: DateTime.utc(2026, 9, 1),
    );

/// 07:00 at the school (Africa/Douala, UTC+1) on 12 November 2026.
final morning = DateTime.utc(2026, 11, 12, 6);

Trip trip(String id, {String bus = 'b1', String? driver, TripStatus status = TripStatus.scheduled, DateTime? at, String? startedBy}) => Trip(
      id: id,
      schoolId: schoolId,
      busId: bus,
      direction: TripDirection.inbound,
      status: status,
      scheduledStart: at ?? morning.add(const Duration(minutes: 30)),
      driverId: driver,
      startedBy: startedBy,
    );

class FakeAuth implements AuthService {
  FakeAuth({this.signedInAs});

  String? signedInAs;
  final _changes = StreamController<String?>.broadcast();
  int signOuts = 0;

  @override
  String? get currentUserId => signedInAs;

  @override
  Stream<String?> get userIdChanges async* {
    yield signedInAs;
    yield* _changes.stream;
  }

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {
    signOuts++;
    signedInAs = null;
    _changes.add(null);
  }
}

class FakeProfiles implements ProfileRepository {
  FakeProfiles(this.byId);
  final Map<String, Profile> byId;

  @override
  Future<Profile> getProfile(String userId) async => byId[userId] ?? (throw const NotFound('profile'));

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class FakeSchools implements SchoolRepository {
  @override
  Future<School> getSchool(String id) async => const School(id: schoolId, name: 'Test School', timezone: 'Africa/Douala', isActive: true);
}

class FakeTrips implements TripsRepository {
  FakeTrips(this.trips);

  final List<Trip> trips;
  final List<String> started = [];
  final List<String> ended = [];
  Object? startError;
  List<ManifestEntry> boarded = const [];

  @override
  Future<List<Trip>> listBetween({required DateTime from, required DateTime to}) async =>
      trips.where((t) => !t.scheduledStart.isBefore(from) && t.scheduledStart.isBefore(to)).toList();

  @override
  Future<Trip> getTrip(String tripId) async => trips.firstWhere((t) => t.id == tripId);

  @override
  Future<void> start(String tripId) async {
    if (startError != null) throw startError!;
    started.add(tripId);
    final i = trips.indexWhere((t) => t.id == tripId);
    final t = trips[i];
    trips[i] = trip(t.id, bus: t.busId, driver: t.driverId, status: TripStatus.active, at: t.scheduledStart, startedBy: 'u1');
  }

  @override
  Future<void> end(String tripId) async {
    ended.add(tripId);
    final i = trips.indexWhere((t) => t.id == tripId);
    final t = trips[i];
    trips[i] = trip(t.id, bus: t.busId, driver: t.driverId, status: TripStatus.completed, at: t.scheduledStart, startedBy: t.startedBy);
  }

  @override
  Future<List<ManifestEntry>> manifest(String tripId) async => boarded;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class FakeBuses implements BusesRepository {
  @override
  Future<List<Bus>> listByIds(List<String> busIds) async => [
        for (final id in busIds) Bus(id: id, schoolId: schoolId, plate: 'LT-$id', name: 'Bus ${id.toUpperCase()}', capacity: 50, inService: true),
      ];
}

/// A student's secret, made from a seed.
Uint8List secretOf(int seed) => Uint8List.fromList(List<int>.generate(32, (i) => (i + seed) % 256));

DateTime doualaDate(DateTime instant) {
  final local = instant.toUtc().add(const Duration(hours: 1));
  return DateTime(local.year, local.month, local.day);
}

/// The code a student shows at [at].
String codeOf(String studentId, int seed, {DateTime? at}) =>
    QrCodeGenerator.generate(secret: secretOf(seed), studentId: studentId, now: at ?? morning, schoolDate: doualaDate);

RiderKey riderKey(String studentId, int seed, String name) => RiderKey(
      studentId: studentId,
      dayKey: QrCodeGenerator.dayKey(secret: secretOf(seed), date: DateTime(2026, 11, 12)),
      fullName: name,
      matricule: 'M$seed',
      day: DateTime.utc(2026, 11, 12),
    );

class FakeQr implements QrRepository {
  FakeQr(this.riders);
  List<RiderKey> riders;
  Object? error;
  int downloads = 0;

  @override
  Future<List<RiderKey>> staffDayKeys() async {
    downloads++;
    if (error != null) throw error!;
    return riders;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class FakeRosterStore implements RosterStore {
  final Map<String, Roster> saved = {};
  int clears = 0;

  @override
  Future<Roster?> load(String userId) async => saved[userId];

  @override
  Future<void> save(String userId, Roster roster) async => saved[userId] = roster;

  @override
  Future<void> clear() async {
    clears++;
    saved.clear();
  }
}

class FakeScans implements ScansRepository {
  ScanOutcome answer = const ScanRefused(ScanFailure.noActiveSubscription);
  Object? error;
  final List<({String code, DateTime? at, String? clientId, String? stopId})> sent = [];

  @override
  Future<ScanOutcome> recordScan({
    required String tripId,
    required String code,
    String? stopId,
    GeoPoint? location,
    double? accuracyMeters,
    DateTime? scannedAt,
    String? clientId,
  }) async {
    if (error != null) throw error!;
    sent.add((code: code, at: scannedAt, clientId: clientId, stopId: stopId));
    return answer;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class FakeStops implements StopsRepository {
  @override
  Future<List<Stop>> listActiveStops() async => [Stop(id: 'stop1', schoolId: schoolId, name: 'Mendong market', location: GeoPoint(3.82, 11.477), active: true)];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class FakePositions implements LocationFeed {
  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Stream<Fix> watch() => Stream.value((point: GeoPoint(3.8201, 11.4771), accuracy: 8.0));
}

/// The stand-in camera: tests call [feed] with what it "reads".
late void Function(String code) feed;

Widget fakeCamera(BuildContext context, void Function(String code) onCode) {
  feed = onCode;
  return const SizedBox.expand();
}

List<Override> overridesFor({
  required FakeAuth auth,
  required Map<String, Profile> profiles,
  required FakeTrips trips,
  FakeQr? qr,
  FakeRosterStore? rosters,
  ScanQueue? queue,
  FakeScans? scans,
  bool online = true,
}) =>
    [
      qrRepositoryProvider.overrideWithValue(qr ?? FakeQr(const [])),
      rosterStoreProvider.overrideWithValue(rosters ?? FakeRosterStore()),
      scanQueueProvider.overrideWithValue(queue ?? MemoryScanQueue()),
      scansRepositoryProvider.overrideWithValue(scans ?? FakeScans()),
      stopsRepositoryProvider.overrideWithValue(FakeStops()),
      locationFeedProvider.overrideWithValue(FakePositions()),
      scannerViewProvider.overrideWithValue(fakeCamera),
      connectivityProvider.overrideWith((ref) => Stream.value(online)),
      authServiceProvider.overrideWithValue(auth),
      profileRepositoryProvider.overrideWithValue(FakeProfiles(profiles)),
      schoolRepositoryProvider.overrideWithValue(FakeSchools()),
      tripsRepositoryProvider.overrideWithValue(trips),
      busesRepositoryProvider.overrideWithValue(FakeBuses()),
      nowProvider.overrideWithValue(() => morning),
    ];
