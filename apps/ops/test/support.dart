import 'dart:async';

import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:busin_ops/src/providers.dart';
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

List<Override> overridesFor({required FakeAuth auth, required Map<String, Profile> profiles, required FakeTrips trips}) => [
      authServiceProvider.overrideWithValue(auth),
      profileRepositoryProvider.overrideWithValue(FakeProfiles(profiles)),
      schoolRepositoryProvider.overrideWithValue(FakeSchools()),
      tripsRepositoryProvider.overrideWithValue(trips),
      busesRepositoryProvider.overrideWithValue(FakeBuses()),
      nowProvider.overrideWithValue(() => morning),
    ];
