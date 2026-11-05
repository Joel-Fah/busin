import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/auth/auth_service.dart';
import 'package:busin_student/src/providers.dart';
import 'package:busin_student/src/school_clock.dart';
import 'package:busin_student/src/subscription/proof_picker.dart';
import 'package:busin_student/src/subscription/subscription_providers.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

Profile profile({
  String id = 'u1',
  UserRole role = UserRole.student,
  AccountStatus status = AccountStatus.verified,
}) =>
    Profile(
      id: id,
      schoolId: 's1',
      email: '$id@school.edu',
      fullName: 'Test Person',
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

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository(this.byId);

  final Map<String, Profile> byId;
  Object? error;

  @override
  Future<Profile> getProfile(String userId) async {
    if (error != null) throw error!;
    return byId[userId] ?? (throw const NotFound('profile'));
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
      createdAt: DateTime.utc(2026, 11, 3, 9),
      updatedAt: DateTime.utc(2026, 11, 3, 9),
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

  /// Set to make the next request or upload fail.
  Object? requestError;
  Object? uploadError;

  final List<NewSubscription> requests = [];
  final List<Uint8List> uploads = [];
  DateTime? askedToday;

  @override
  Future<School> getSchool(String schoolId) async => const School(id: 's1', name: 'Test School', timezone: 'Africa/Douala', isActive: true);

  @override
  Future<Semester?> currentSemester(DateTime today) async {
    askedToday = today;
    return current;
  }

  @override
  Future<Semester?> nextSemester(DateTime today) async => next;

  @override
  Future<List<Stop>> listActiveStops() async => stops;

  @override
  Future<Stop> getStop(String stopId) async => stops.firstWhere((s) => s.id == stopId);

  @override
  Future<List<Subscription>> listForStudent(String studentId, {PageRequest page = const PageRequest()}) async => mine.where((s) => s.studentId == studentId).toList();

  @override
  Future<Subscription?> liveForSemester({required String studentId, required String semesterId}) async =>
      mine.where((s) => s.studentId == studentId && s.semesterId == semesterId && s.isLive).firstOrNull;

  @override
  Future<Subscription> request(NewSubscription request) async {
    if (requestError != null) throw requestError!;
    requests.add(request);
    final created = subscription(id: 'new', studentId: request.studentId, semesterId: request.semesterId, stopId: request.stopId, proofPath: request.proofPath);
    mine.insert(0, created);
    return created;
  }

  @override
  Future<String> upload({required String schoolId, required String studentId, required Uint8List bytes, required String contentType}) async {
    if (uploadError != null) throw uploadError!;
    uploads.add(bytes);
    return '$schoolId/$studentId/file${uploads.length}.jpg';
  }

  @override
  Future<String> signedUrl(String path, {Duration expiresIn = const Duration(minutes: 10)}) async => 'http://localhost/proof/$path';
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

List<Override> overridesFor(
  FakeAuthService auth,
  FakeProfileRepository profiles, {
  FakeBackend? backend,
  FakeProofPicker? picker,
}) {
  final b = backend ?? FakeBackend();
  return [
    authServiceProvider.overrideWithValue(auth),
    profileRepositoryProvider.overrideWithValue(profiles),
    schoolRepositoryProvider.overrideWithValue(b),
    semestersRepositoryProvider.overrideWithValue(b),
    stopsRepositoryProvider.overrideWithValue(b),
    subscriptionsRepositoryProvider.overrideWithValue(b),
    proofsRepositoryProvider.overrideWithValue(b),
    proofPickerProvider.overrideWithValue(picker ?? FakeProofPicker()),
    schoolClockProvider.overrideWithValue(const SchoolClock()),
  ];
}
