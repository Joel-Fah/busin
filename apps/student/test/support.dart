import 'dart:async';
import 'dart:convert';

import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/area/area_providers.dart';
import 'package:busin_student/src/auth/auth_service.dart';
import 'package:busin_student/src/bus/bus_providers.dart';
import 'package:busin_student/src/config/app_config.dart';
import 'package:busin_student/src/bus/map_scene.dart';
import 'package:busin_student/src/offline/offline_providers.dart';
import 'package:busin_student/src/offline/pass_snapshot.dart';
import 'package:busin_student/src/providers.dart';
import 'package:busin_student/src/reminders/notification_providers.dart';
import 'package:busin_student/src/reminders/reminder_plan.dart';
import 'package:busin_student/src/reminders/reminder_scheduler.dart';
import 'package:busin_student/src/streaks/streak_providers.dart';
import 'package:busin_student/src/push/push_service.dart';
import 'package:busin_student/src/qr/qr_providers.dart';
import 'package:busin_student/src/qr/screen_security.dart';
import 'package:busin_student/src/qr/secret_store.dart';
import 'package:busin_student/src/school_clock.dart';
import 'package:busin_student/src/subscription/proof_picker.dart';
import 'package:busin_student/src/subscription/subscription_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

Profile profile({
  String id = 'u1',
  UserRole role = UserRole.student,
  AccountStatus status = AccountStatus.verified,
  bool complete = true,
  String? departmentId,
  String? programId,
  String? schoolId = 's1',
  bool streakOptIn = false,
}) =>
    Profile(
      id: id,
      schoolId: schoolId,
      streakOptIn: streakOptIn,
      email: '$id@school.edu',
      fullName: 'Test Person',
      matricule: complete ? 'ICT2026-0001' : null,
      phone: complete ? '677123456' : null,
      departmentId: departmentId,
      programId: programId,
      role: role,
      status: status,
      createdAt: DateTime.utc(2026, 11, 1),
      updatedAt: DateTime.utc(2026, 11, 1),
    );

/// A fake sign-in that also plays the server: [accounts] maps the Google account used to the profile it gets.
class FakeAuthService implements AuthService {
  FakeAuthService({String? signedInAs, this.failWith}) : _userId = signedInAs;

  String? _userId;
  SignInFailure? failWith;
  int signOuts = 0;
  final _changes = StreamController<String?>.broadcast();
  String nextUserId = 'u1';

  @override
  String? get currentUserId => _userId;

  @override
  Stream<String?> get userIdChanges async* {
    yield _userId;
    yield* _changes.stream;
  }

  @override
  Future<void> signInWithGoogle() async {
    if (failWith != null) throw SignInException(failWith!);
    _userId = nextUserId;
    _changes.add(_userId);
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    _userId = null;
    _changes.add(null);
  }
}

/// A small school: two faculties, each with its own departments, and two degree levels.
const testUnits = AcademicUnits(
  faculties: [Faculty(id: 'f1', name: 'Faculty of Computing', code: 'FOC'), Faculty(id: 'f2', name: 'Faculty of Business', code: 'FOB')],
  departments: [
    Department(id: 'd1', facultyId: 'f1', name: 'Computer Science', code: 'CSC'),
    Department(id: 'd2', facultyId: 'f1', name: 'Cybersecurity', code: 'CYS'),
    Department(id: 'd3', facultyId: 'f2', name: 'Accounting', code: 'ACC'),
  ],
  programs: [Program(id: 'p1', name: 'Bachelor'), Program(id: 'p2', name: 'Master')],
);

class FakeAcademic implements AcademicRepository {
  FakeAcademic([this.units = testUnits]);

  AcademicUnits units;

  @override
  Future<AcademicUnits> load() async => units;
}

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository(this.byId, {this.units = testUnits});

  final Map<String, Profile> byId;
  final AcademicUnits units;
  Object? error;

  /// When set, the profile is not given until this completes (a slow or unreachable backend).
  Completer<void>? hold;
  int reads = 0;

  @override
  Future<Profile> getProfile(String userId) async {
    reads++;
    if (hold != null) await hold!.future;
    if (error != null) throw error!;
    return byId[userId] ?? (throw const NotFound('profile'));
  }

  /// What was last saved, to check in tests.
  Map<String, String?>? lastUpdate;
  AcademicChoice? lastAcademic;

  @override
  Future<Profile> updateProfile(String userId, {String? fullName, String? phone, String? matricule, AcademicChoice? academic}) async {
    if (error != null) throw error!;
    lastUpdate = {'fullName': fullName, 'phone': phone, 'matricule': matricule, 'departmentId': academic?.departmentId, 'programId': academic?.programId};
    lastAcademic = academic;
    final old = byId[userId] ?? (throw const NotFound('profile'));
    final updated = Profile(
      id: old.id,
      schoolId: old.schoolId,
      email: old.email,
      fullName: fullName ?? old.fullName,
      avatarUrl: old.avatarUrl,
      phone: phone ?? old.phone,
      role: old.role,
      status: old.status,
      matricule: matricule ?? old.matricule,
      department: academic == null ? old.department : units.department(academic.departmentId)?.name,
      program: academic == null ? old.program : units.program(academic.programId)?.name,
      departmentId: academic == null ? old.departmentId : academic.departmentId,
      programId: academic == null ? old.programId : academic.programId,
      createdAt: old.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
    byId[userId] = updated;
    return updated;
  }
}

// ---------------------------------------------------------------- subscription fakes

Semester semester({String id = 'sem1', String start = '2026-09-01', String end = '2027-01-31'}) => Semester(
      id: id,
      schoolId: 's1',
      name: SemesterName.fall,
      year: 2026,
      startDate: DateTime.parse(start),
      endDate: DateTime.parse(end),
    );

Stop stop(String id, String name) => Stop(id: id, schoolId: 's1', name: name, location: GeoPoint(3.85, 11.5), active: true);

Subscription subscription({
  String id = 'sub1',
  String studentId = 'u1',
  String semesterId = 'sem1',
  String stopId = 'stop1',
  SubscriptionStatus status = SubscriptionStatus.pending,
  String? proofPath,
  String? note,
  DateTime? createdAt,
}) =>
    Subscription(
      id: id,
      schoolId: 's1',
      studentId: studentId,
      semesterId: semesterId,
      stopId: stopId,
      status: status,
      proofPath: proofPath,
      reviewNote: note,
      createdAt: createdAt ?? DateTime.utc(2026, 11, 3, 9),
      updatedAt: createdAt ?? DateTime.utc(2026, 11, 3, 9),
    );

/// The school, semester, stop and subscription repositories in one fake that remembers what was asked.
class FakeBackend implements SchoolRepository, SemestersRepository, StopsRepository, SubscriptionsRepository, ProofsRepository {
  FakeBackend({this.current, this.next, List<Stop>? stops, List<Subscription>? mine})
      : stops = stops ?? [stop('stop1', 'Carrefour Ekounou'), stop('stop2', 'Mvan'), stop('stop3', 'Biyem-Assi')],
        mine = mine ?? [];

  Semester? current;
  Semester? next;
  final List<Stop> stops;
  final List<Subscription> mine;

  /// Stops that are not in the active list but can still be fetched by id (a stop taken out of service).
  final Map<String, Stop> hiddenStops = {};

  /// Set to make every read fail (no connection, a refusal).
  Object? readError;

  /// Set to make the link to a stored proof fail.
  Object? proofError;

  /// Set to make the next request or upload fail.
  Object? requestError;
  Object? uploadError;

  final List<NewSubscription> requests = [];
  final List<Uint8List> uploads = [];
  DateTime? askedToday;

  @override
  Future<School> getSchool(String schoolId) async {
    if (readError != null) throw readError!;
    return const School(id: 's1', name: 'Test School', timezone: 'Africa/Douala', isActive: true);
  }

  @override
  Future<Semester?> currentSemester(DateTime today) async {
    if (readError != null) throw readError!;
    askedToday = today;
    return current;
  }

  @override
  Future<Semester?> nextSemester(DateTime today) async {
    if (readError != null) throw readError!;
    return next;
  }

  @override
  Future<List<Stop>> listActiveStops() async => stops;

  @override
  Future<Stop> getStop(String stopId) async {
    if (readError != null) throw readError!;
    final hidden = hiddenStops[stopId];
    if (hidden != null) return hidden;
    return stops.firstWhere((s) => s.id == stopId, orElse: () => throw const NotFound('stop'));
  }

  @override
  Future<List<Subscription>> listForStudent(String studentId, {PageRequest page = const PageRequest()}) async {
    if (readError != null) throw readError!;
    return mine.where((s) => s.studentId == studentId).toList();
  }

  @override
  Future<Subscription?> liveForSemester({required String studentId, required String semesterId}) async =>
      mine.where((s) => s.studentId == studentId && s.semesterId == semesterId && s.isLive).firstOrNull;

  /// What the live feed gives: the rows now, then whatever a test pushes with [emitLive].
  final _live = StreamController<List<Subscription>>.broadcast();
  int liveListeners = 0;

  void emitLive(List<Subscription> rows) => _live.add(rows);

  @override
  Stream<List<Subscription>> watchForStudent(String studentId) async* {
    liveListeners++;
    yield mine.where((s) => s.studentId == studentId).toList();
    yield* _live.stream;
  }

  /// What happened to the subscriptions, for the history (oldest first, as the server gives it).
  final List<SubscriptionEvent> events = [];

  @override
  Future<List<SubscriptionEvent>> eventsFor(List<String> subscriptionIds) async => events.where((e) => subscriptionIds.contains(e.subscriptionId)).toList();

  @override
  Future<Subscription> request(NewSubscription request) async {
    if (requestError != null) throw requestError!;
    requests.add(request);
    final created = subscription(id: 'new', studentId: request.studentId, semesterId: request.semesterId, stopId: request.stopId, proofPath: request.proofPath);
    mine.insert(0, created);
    events.add(SubscriptionEvent(id: events.length + 1, subscriptionId: created.id, action: SubscriptionEventAction.requested, createdAt: DateTime.utc(2026, 11, 3, 9)));
    return created;
  }

  @override
  Future<String> upload({required String schoolId, required String studentId, required Uint8List bytes, required String contentType}) async {
    if (uploadError != null) throw uploadError!;
    uploads.add(bytes);
    return '$schoolId/$studentId/file${uploads.length}.jpg';
  }

  @override
  Future<String> signedUrl(String path, {Duration expiresIn = const Duration(minutes: 10)}) async {
    if (proofError != null) throw proofError!;
    return 'http://localhost/proof/$path';
  }
}

class FakeProofPicker implements ProofPicker {
  FakeProofPicker([this.result]);

  PickedProof? result;
  ProofException? error;
  final List<ProofSource> asked = [];

  @override
  Future<PickedProof?> pick(ProofSource source) async {
    asked.add(source);
    if (error != null) throw error!;
    return result;
  }
}

/// A real 1x1 PNG, so the preview decodes in widget tests.
PickedProof samplePhoto() => PickedProof(
      bytes: base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='),
      contentType: 'image/png',
    );

// ---------------------------------------------------------------- history fakes

Scan scan(int n, {String tripId = 'trip1', String? stopId = 'stop1', required DateTime at}) => Scan(
      id: 'scan$n',
      schoolId: 's1',
      tripId: tripId,
      studentId: 'u1',
      subscriptionId: 'sub1',
      stopId: stopId,
      scannedBy: 'staff1',
      scannedAt: at,
    );

Trip trip(String id, TripDirection direction) => Trip(
      id: id,
      schoolId: 's1',
      busId: 'bus1',
      direction: direction,
      status: TripStatus.completed,
      scheduledStart: DateTime.utc(2026, 11, 1, 6),
    );

/// The student's scans (newest first, as the server returns them) and the trips they were on.
class FakeHistory implements ScansRepository, TripsRepository {
  FakeHistory({List<Scan>? scans, List<Trip>? trips})
      : scans = scans ?? [],
        trips = trips ?? [trip('trip1', TripDirection.inbound), trip('trip2', TripDirection.outbound)];

  final List<Scan> scans;
  final List<Trip> trips;

  /// What the live "newest boarding" feed delivers; a test adds a scan to announce a boarding.
  final StreamController<Scan?> latest = StreamController<Scan?>.broadcast();

  /// How many rides this semester the count answers.
  int ridesThisSemester = 3;

  @override
  Stream<Scan?> watchLatestForStudent(String studentId) => latest.stream;

  @override
  Future<int> countForStudentSince(String studentId, DateTime since) async => ridesThisSemester;

  /// Trips running now, for the live bus tab.
  final List<Trip> active = [];
  int activeLookups = 0;
  Object? activeError;

  /// Offsets asked for, in order.
  final List<int> offsets = [];
  final List<int> limits = [];
  int tripLookups = 0;

  /// Makes the first request for this offset (and only that one) fail.
  int? failOnceAtOffset;
  Object? failAlways;

  /// When set, the first page is not given until this completes (to look at the waiting state).
  Completer<void>? hold;

  @override
  Future<List<Scan>> listForStudent(String studentId, {PageRequest page = const PageRequest()}) async {
    if (hold != null) await hold!.future;
    offsets.add(page.offset);
    limits.add(page.limit);
    if (failAlways != null) throw failAlways!;
    if (failOnceAtOffset == page.offset) {
      failOnceAtOffset = null;
      throw const Offline('down');
    }
    return scans.skip(page.offset).take(page.limit).toList();
  }

  @override
  Future<List<Trip>> listActive() async {
    activeLookups++;
    if (activeError != null) throw activeError!;
    return List.of(active);
  }

  @override
  Future<List<Trip>> listByIds(List<String> tripIds) async {
    tripLookups++;
    return trips.where((t) => tripIds.contains(t.id)).toList();
  }

  @override
  Future<ScanOutcome> recordScan({required String tripId, required String code, String? stopId, GeoPoint? location, double? accuracyMeters}) =>
      throw UnimplementedError();

  @override
  Future<List<Scan>> listForTrip(String tripId, {PageRequest page = const PageRequest()}) => throw UnimplementedError();

  @override
  Future<List<Trip>> listForDriver(String driverId, {required DateTime from, required DateTime to}) => throw UnimplementedError();

  @override
  Future<Trip> getTrip(String tripId) => throw UnimplementedError();
}

// ---------------------------------------------------------------- push fakes

class FakePushService implements PushService {
  FakePushService({this.available = true, this.current = PushPermission.notAsked, this.onRequest = PushPermission.granted, this.currentToken = 'fcm-token-of-this-phone-0001'});

  @override
  bool available;

  PushPermission current;

  /// What the person answers when asked.
  PushPermission onRequest;
  String? currentToken;
  PushMessage? launched;

  int requests = 0;
  int forgets = 0;
  final List<String> log = [];

  final refreshes = StreamController<String>.broadcast();
  final tapped = StreamController<PushMessage>.broadcast();
  final arrived = StreamController<PushMessage>.broadcast();

  @override
  Future<PushPermission> permission() async => current;

  @override
  Future<PushPermission> requestPermission() async {
    requests++;
    current = onRequest;
    return onRequest;
  }

  @override
  Future<String?> token() async => current == PushPermission.granted ? currentToken : null;

  @override
  Stream<String> get tokenRefreshes => refreshes.stream;

  @override
  Stream<PushMessage> get taps => tapped.stream;

  @override
  Future<PushMessage?> launchedBy() async => launched;

  @override
  Stream<PushMessage> get foreground => arrived.stream;

  @override
  Future<void> forgetToken() async {
    forgets++;
    log.add('forgetToken');
  }
}

class RegisteredToken {
  const RegisteredToken(this.token, this.platform, this.locale);

  final String token;
  final String platform;
  final String locale;
}

class FakeDeviceTokens implements DeviceTokensRepository {
  final List<RegisteredToken> registered = [];
  final List<String> unregistered = [];
  Object? error;

  @override
  Future<void> register({required String token, required String platform, required String locale}) async {
    if (error != null) throw error!;
    registered.add(RegisteredToken(token, platform, locale));
  }

  @override
  Future<void> unregister(String token) async {
    if (error != null) throw error!;
    unregistered.add(token);
  }
}

// ---------------------------------------------------------------- live bus fakes

Trip activeTrip(String id, String busId, {TripDirection direction = TripDirection.inbound, int minutesAgo = 10}) => Trip(
      id: id,
      schoolId: 's1',
      busId: busId,
      direction: direction,
      status: TripStatus.active,
      scheduledStart: DateTime.utc(2026, 11, 5, 11),
      startedAt: DateTime.utc(2026, 11, 5, 12).subtract(Duration(minutes: minutesAgo)),
    );

Bus bus(String id, String plate, {String? name}) => Bus(id: id, schoolId: 's1', plate: plate, name: name, capacity: 50, inService: true);

LivePosition position(String busId, double lat, double lng, {required DateTime at, double? speed, double? heading}) => LivePosition(
      busId: busId,
      schoolId: 's1',
      location: GeoPoint(lat, lng),
      source: PositionSource.phone,
      recordedAt: at,
      speedMps: speed,
      headingDeg: heading,
    );

class FakeBuses implements BusesRepository {
  FakeBuses([List<Bus>? buses]) : buses = buses ?? [bus('bus1', 'DEMO-101'), bus('bus2', 'DEMO-102')];

  final List<Bus> buses;

  @override
  Future<List<Bus>> listByIds(List<String> busIds) async => buses.where((b) => busIds.contains(b.id)).toList();
}

/// Live positions by bus. A test pushes positions with [emit]; [subscribed] shows which buses were listened to.
class FakeLive implements LivePositionsRepository {
  /// Whether the signed-in student may follow buses (an approved subscription covering today).
  bool canFollow = true;
  Object? canFollowError;
  int canFollowChecks = 0;

  @override
  Future<bool> canFollowBuses() async {
    canFollowChecks++;
    if (canFollowError != null) throw canFollowError!;
    return canFollow;
  }

  final Map<String, StreamController<LivePosition>> _controllers = {};
  final List<String> subscribed = [];
  final List<String> cancelled = [];

  StreamController<LivePosition> _controller(String busId) => _controllers.putIfAbsent(busId, StreamController<LivePosition>.broadcast);

  void emit(LivePosition p) => _controller(p.busId).add(p);

  void fail(String busId, Object error) => _controller(busId).addError(error);

  @override
  Future<LivePosition?> latestForBus(String busId) async => null;

  @override
  Stream<LivePosition> watchBus(String busId) {
    subscribed.add(busId);
    late StreamController<LivePosition> mine;
    mine = StreamController<LivePosition>(
      onListen: () => _controller(busId).stream.listen(mine.add, onError: mine.addError),
      onCancel: () => cancelled.add(busId),
    );
    return mine.stream;
  }
}

/// Stands in for the native map: shows the scene as text and remembers every scene and recenter request.
class FakeMapSurface {
  final List<MapScene> scenes = [];
  int recenters = 0;

  /// What the real map would write: whether the bus is inside the visible part of the map.
  ValueNotifier<bool>? busInView;
  ValueListenable<int>? _listening;

  MapSurfaceBuilder get builder => (context, scene, recenter, busInView) {
        scenes.add(scene);
        this.busInView = busInView;
        // The screen rebuilds the surface often; listen to the one notifier once.
        if (!identical(_listening, recenter)) {
          _listening = recenter;
          recenter.addListener(() => recenters++);
        }
        final bus = scene.bus;
        return Center(
          key: const ValueKey('fake-map'),
          child: Text('map stops=${scene.stops.length} mine=${scene.myStopId ?? '-'} bus=${bus == null ? '-' : '${bus.latitude},${bus.longitude}'}'),
        );
      };
}

// ---------------------------------------------------------------- boarding code fakes

/// Bytes 0 to 31: the secret from the QR test vector.
Uint8List testSecret() => Uint8List.fromList(List.generate(32, (i) => i));

/// The saved copy in memory.
class FakeSnapshotStore implements SnapshotStore {
  final Map<String, PassSnapshot> kept = {};
  bool failWrites = false;

  @override
  Future<PassSnapshot?> read(String userId) async => kept[userId];

  @override
  Future<void> write(PassSnapshot snapshot) async {
    if (failWrites) throw StateError('disk full');
    kept[snapshot.userId] = snapshot;
  }

  @override
  Future<void> delete(String userId) async => kept.remove(userId);

  @override
  Future<void> deleteAll() async => kept.clear();
}

class FakeSecretStore implements SecretStore {
  final Map<String, Uint8List> data = {};
  int deleteAllCalls = 0;

  @override
  Future<Uint8List?> read(String userId) async => data[userId];

  @override
  Future<void> write(String userId, Uint8List secret) async => data[userId] = secret;

  final List<String> deleted = [];

  @override
  Future<void> delete(String userId) async {
    deleted.add(userId);
    data.remove(userId);
  }

  @override
  Future<void> deleteAll() async {
    deleteAllCalls++;
    data.clear();
  }
}

class FakeScreenSecurity implements ScreenSecurity {
  FakeScreenSecurity({this.supported = true});

  @override
  final bool supported;

  /// Every value the app asked for, in order.
  final List<bool> calls = [];

  @override
  Future<void> setSecure(bool secure) async => calls.add(secure);
}

class FakeQr implements QrRepository {
  FakeQr({Uint8List? secret}) : secret = secret ?? testSecret();

  Uint8List secret;
  Object? error;
  int fetches = 0;

  /// When set, the secret is not given until this completes (to look at the waiting state).
  Completer<void>? hold;

  @override
  Future<Uint8List> fetchSecret() async {
    fetches++;
    if (hold != null) await hold!.future;
    if (error != null) throw error!;
    return secret;
  }

  @override
  Future<Uint8List> rotateSecret() async => secret;
}

/// A clock the test moves by hand.
class TestClock {
  TestClock(this.now);

  DateTime now;

  DateTime call() => now;
}

/// The public settings a test app is built with (nothing is reached over the network).
const testConfig = AppConfig(supabaseUrl: 'http://127.0.0.1:54321', publishableKey: 'test', googleServerClientId: 'test', environment: 'test');

List<Override> overridesFor(
  FakeAuthService auth,
  FakeProfileRepository profiles, {
  FakeAcademic? academic,
  FakeBackend? backend,
  FakeProofPicker? picker,
  FakeHistory? history,
  FakePushService? push,
  FakeDeviceTokens? deviceTokens,
  String languageCode = 'en',
  FakeBuses? buses,
  FakeLive? live,
  FakeMapSurface? map,
  FakeQr? qr,
  FakeJoin? join,
  FakeNotificationPreferences? notificationPreferences,
  FakeReminderScheduler? reminders,
  FakeStreaks? streaks,
  FakeAreas? areas,
  FakeLocator? locator,
  FakeSecretStore? store,
  FakeScreenSecurity? security,
  TestClock? clock,
  FakeSnapshotStore? snapshots,
  Stream<bool>? connectivity,
  Duration? gateTimeout,
  Duration? copyWait,
}) {
  final b = backend ?? FakeBackend();
  final h = history ?? FakeHistory();
  return [
    appConfigProvider.overrideWithValue(testConfig),
    introEnabledProvider.overrideWithValue(false),
    snapshotStoreProvider.overrideWithValue(snapshots ?? FakeSnapshotStore()),
    connectivityProvider.overrideWith((ref) => connectivity ?? Stream<bool>.value(true)),
    // No limit unless a test asks for one: a held read must not leave a timer behind.
    gateTimeoutProvider.overrideWithValue(gateTimeout),
    copyWaitProvider.overrideWithValue(copyWait),
    authServiceProvider.overrideWithValue(auth),
    profileRepositoryProvider.overrideWithValue(profiles),
    joinRepositoryProvider.overrideWithValue(join ?? FakeJoin(profiles)),
    notificationPreferencesRepositoryProvider.overrideWithValue(notificationPreferences ?? FakeNotificationPreferences()),
    reminderSchedulerProvider.overrideWithValue(reminders ?? FakeReminderScheduler()),
    streaksRepositoryProvider.overrideWithValue(streaks ?? FakeStreaks(profiles)),
    areaRepositoryProvider.overrideWithValue(areas ?? FakeAreas()),
    areaLocatorProvider.overrideWithValue(locator ?? FakeLocator(const LocationFailed())),
    academicRepositoryProvider.overrideWithValue(academic ?? FakeAcademic()),
    schoolRepositoryProvider.overrideWithValue(b),
    semestersRepositoryProvider.overrideWithValue(b),
    stopsRepositoryProvider.overrideWithValue(b),
    subscriptionsRepositoryProvider.overrideWithValue(b),
    proofsRepositoryProvider.overrideWithValue(b),
    proofPickerProvider.overrideWithValue(picker ?? FakeProofPicker()),
    schoolClockProvider.overrideWithValue(const SchoolClock()),
    scansRepositoryProvider.overrideWithValue(h),
    tripsRepositoryProvider.overrideWithValue(h),
    pushServiceProvider.overrideWithValue(push ?? FakePushService(available: false)),
    deviceTokensRepositoryProvider.overrideWithValue(deviceTokens ?? FakeDeviceTokens()),
    languageCodeProvider.overrideWithValue(() => languageCode),
    busesRepositoryProvider.overrideWithValue(buses ?? FakeBuses()),
    livePositionsRepositoryProvider.overrideWithValue(live ?? FakeLive()),
    mapSurfaceBuilderProvider.overrideWithValue((map ?? FakeMapSurface()).builder),
    qrRepositoryProvider.overrideWithValue(qr ?? FakeQr()),
    secretStoreProvider.overrideWithValue(store ?? FakeSecretStore()),
    screenSecurityProvider.overrideWithValue(security ?? FakeScreenSecurity()),
    if (clock != null) nowProvider.overrideWithValue(clock.call),
  ];
}

/// Joining a school (ADR 0012), done the way the server does it: asking sets the profile's school (still pending),
/// withdrawing clears it.
class FakeJoin implements JoinRepository {
  FakeJoin(this.profiles, {this.schools = const [], this.request});

  final FakeProfileRepository profiles;
  List<OpenSchool> schools;
  JoinRequest? request;
  Object? error;
  final List<String?> asked = [];

  @override
  Future<List<OpenSchool>> listOpenSchools() async {
    if (error != null) throw error!;
    return schools;
  }

  @override
  Future<JoinRequest?> myRequest() async => request;

  @override
  Future<void> requestSchool(String? schoolId) async {
    if (error != null) throw error!;
    asked.add(schoolId);
    for (final entry in profiles.byId.entries.toList()) {
      final p = entry.value;
      profiles.byId[entry.key] = Profile(
        id: p.id,
        schoolId: schoolId,
        email: p.email,
        fullName: p.fullName,
        role: p.role,
        status: p.status,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
      );
    }
    final school = schools.where((s) => s.id == schoolId).firstOrNull;
    request = schoolId == null ? null : JoinRequest(schoolId: schoolId, schoolName: school?.name, requestedAt: DateTime.utc(2026, 11, 11, 8));
  }
}

class FakeNotificationPreferences implements NotificationPreferencesRepository {
  FakeNotificationPreferences([this.stored = const NotificationPreferences()]);

  NotificationPreferences stored;
  Object? error;
  int saves = 0;

  @override
  Future<NotificationPreferences> load() async => stored;

  @override
  Future<void> save(NotificationPreferences preferences) async {
    if (error != null) throw error!;
    saves++;
    stored = preferences;
  }
}

class FakeReminderScheduler implements ReminderScheduler {
  List<PlannedReminder> placed = const [];
  String? zone;
  int replaced = 0;
  bool allow = true;

  @override
  Future<void> replace(List<PlannedReminder> plan, {required String timeZone, required ReminderText Function(ReminderKind kind) text}) async {
    replaced++;
    placed = plan;
    zone = timeZone;
    for (final reminder in plan) {
      final words = text(reminder.kind);
      assert(words.title.isNotEmpty && words.body.isNotEmpty);
    }
  }

  @override
  Future<bool> requestPermission() async => allow;
}

/// Streaks done the way the server does them: opting in flips the profile's flag; the streak and the days are set by the test.
class FakeStreaks implements StreaksRepository {
  FakeStreaks(this.profiles, {this.current, this.days = const [], this.board = const []});

  final FakeProfileRepository profiles;
  Streak? current;
  List<RideDay> days;
  Object? error;
  final List<bool> optIns = [];

  @override
  Future<void> setOptIn(bool on) async {
    optIns.add(on);
    for (final entry in profiles.byId.entries.toList()) {
      final p = entry.value;
      profiles.byId[entry.key] = Profile(
        id: p.id,
        schoolId: p.schoolId,
        email: p.email,
        fullName: p.fullName,
        role: p.role,
        status: p.status,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
        phone: p.phone,
        matricule: p.matricule,
        streakOptIn: on,
      );
    }
  }

  @override
  Future<List<RideDay>> rideDays(String semesterId) async => days;

  @override
  Future<Streak?> streak(String semesterId) async {
    if (error != null) throw error!;
    return current;
  }

  List<LeaderboardEntry> board;

  @override
  Future<List<LeaderboardEntry>> leaderboard(String semesterId, {int limit = 50}) async => board;
}

class FakeAreas implements AreaRepository {
  FakeAreas({this.area, this.places = const []});

  StudentArea? area;
  List<PlaceResult> places;
  Object? saveError;
  Object? searchError;
  final List<({double lat, double lng, String label, AreaSource source})> saved = [];
  final List<String> queries = [];

  @override
  Future<StudentArea?> myArea() async => area;

  @override
  Future<void> setArea({required double lat, required double lng, required String label, required AreaSource source}) async {
    if (saveError != null) throw saveError!;
    saved.add((lat: lat, lng: lng, label: label, source: source));
    area = StudentArea(label: label, lat: lat, lng: lng, source: source, updatedAt: DateTime.utc(2026, 11, 11));
  }

  @override
  Future<void> clearArea() async => area = null;

  @override
  Future<List<PlaceResult>> searchPlaces(String query, {required String languageCode}) async {
    queries.add(query);
    if (searchError != null) throw searchError!;
    return places;
  }
}

class FakeLocator implements AreaLocator {
  FakeLocator(this.result);

  LocatorResult result;
  int reads = 0;
  int settingsOpened = 0;

  @override
  Future<LocatorResult> readOnce() async {
    reads++;
    return result;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}
