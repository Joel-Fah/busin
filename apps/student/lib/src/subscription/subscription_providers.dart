import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:flutter/painting.dart' show ImageProvider, NetworkImage;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../area/area_providers.dart';
import '../auth/access.dart';
import '../providers.dart';
import 'proof_picker.dart';
import 'subscription_overview.dart';

export 'subscription_overview.dart';

final stopsRepositoryProvider = Provider<StopsRepository>((ref) => ref.watch(repositoriesProvider).stops);
final semestersRepositoryProvider = Provider<SemestersRepository>((ref) => ref.watch(repositoriesProvider).semesters);
final subscriptionsRepositoryProvider = Provider<SubscriptionsRepository>((ref) => ref.watch(repositoriesProvider).subscriptions);
final proofsRepositoryProvider = Provider<ProofsRepository>((ref) => ref.watch(repositoriesProvider).proofs);
final schoolRepositoryProvider = Provider<SchoolRepository>((ref) => ref.watch(repositoriesProvider).schools);

final scansRepositoryProvider = Provider<ScansRepository>((ref) => ref.watch(repositoriesProvider).scans);
final tripsRepositoryProvider = Provider<TripsRepository>((ref) => ref.watch(repositoriesProvider).trips);

/// The student's school, for its time zone. Read once while the screen that needs it is alive.
final schoolProvider = FutureProvider.autoDispose<School>((ref) async {
  final access = ref.watch(accessProvider);
  if (access is! Allowed) throw StateError('Only an allowed student has a school here.');
  final userId = access.profile.id;
  final keeper = ref.watch(snapshotKeeperProvider);
  return serverOrSaved<School>(
    ref,
    source: 'school',
    // An allowed student is verified, and a verified account always has a school (ADR 0012).
    live: () => ref.watch(schoolRepositoryProvider).getSchool(access.profile.schoolId!),
    save: (school) => keeper.saveSchool(userId, school),
    saved: () async {
      final snapshot = await keeper.load(userId);
      final school = snapshot?.school;
      return school == null ? null : (value: school, savedAt: snapshot!.savedAt);
    },
  );
}, retry: noAutomaticRetry);

final schoolClockProvider = Provider<SchoolClock>((ref) => const SchoolClock());
final proofPickerProvider = Provider<ProofPicker>((ref) => ImagePickerProofPicker());

/// The stops a student can pick from. Read once for the session; it resets when the user changes.
final stopsProvider = FutureProvider<List<Stop>>((ref) async {
  if (ref.watch(authUserIdProvider).value == null) return const [];
  return ref.watch(stopsRepositoryProvider).listActiveStops();
}, retry: noAutomaticRetry);

/// Picks what to show for a semester: a live request wins; otherwise the newest of the rest. The
/// list arrives newest first.
Subscription? subscriptionToShow(List<Subscription> mine, String semesterId) {
  final inSemester = mine.where((s) => s.semesterId == semesterId).toList();
  for (final s in inSemester) {
    if (s.isLive) return s;
  }
  return inSemester.isEmpty ? null : inSemester.first;
}

final subscriptionOverviewProvider = FutureProvider.autoDispose<SubscriptionOverview>((ref) async {
  final access = ref.watch(accessProvider);
  if (access is! Allowed) throw StateError('The subscription page is only for an allowed student.');
  final profile = access.profile;
  final keeper = ref.watch(snapshotKeeperProvider);

  return serverOrSaved<SubscriptionOverview>(
    ref,
    source: 'overview',
    live: () async {
      final school = await ref.watch(schoolProvider.future);
      final today = ref.watch(schoolClockProvider).today(school.timezone, now: ref.read(nowProvider)());

      final semesters = ref.watch(semestersRepositoryProvider);
      var semester = await semesters.currentSemester(today);
      var upcoming = false;
      if (semester == null) {
        semester = await semesters.nextSemester(today);
        upcoming = semester != null;
      }
      if (semester == null) return const SubscriptionOverview.none();

      final mine = await ref.watch(subscriptionsRepositoryProvider).listForStudent(profile.id, page: const PageRequest(limit: 20));
      final subscription = subscriptionToShow(mine, semester.id);
      final stop = subscription == null ? null : await ref.watch(stopsRepositoryProvider).getStop(subscription.stopId);
      return SubscriptionOverview(semester: semester, upcoming: upcoming, subscription: subscription, stop: stop);
    },
    save: (overview) => keeper.saveOverview(profile.id, overview.toJson()),
    saved: () async {
      final snapshot = await keeper.load(profile.id);
      final overview = snapshot?.overview;
      return overview == null ? null : (value: SubscriptionOverview.fromJson(overview, savedAt: snapshot!.savedAt), savedAt: snapshot.savedAt);
    },
  );
}, retry: noAutomaticRetry);

/// How a proof's address becomes a picture. The network in the app; a test swaps in a picture it has in memory.
final proofImageProvider = Provider<ImageProvider Function(String address)>((ref) => NetworkImage.new);

/// A short-lived address to show a stored proof. Fetched when the proof is on screen and not kept.
final proofUrlProvider = FutureProvider.autoDispose.family<String, String>(
  (ref, path) => ref.watch(proofsRepositoryProvider).signedUrl(path),
  // A failure is shown (with Try again) at once, not retried behind the scenes while the proof silently stays hidden.
  retry: noAutomaticRetry,
);

/// Why a request could not be sent, as the screen explains it.
enum SubscribeFailure { alreadyRequested, offline, rejectedFile, proofRequired, semesterEnded, unavailable, other }

/// The storage refused the photo itself (its type or size): the only failure that is about the file.
class ProofRejected implements Exception {
  const ProofRejected(this.cause);

  final RepositoryException cause;
}

/// Uploads the proof, then sends the request. The proof goes first because the request needs its path;
/// if the request then fails the file stays, unreferenced, in the student's own private folder.
class SubscriptionService {
  SubscriptionService(this._ref);

  final Ref _ref;

  Future<void> submit({
    required Profile profile,
    required Semester semester,
    required Stop stop,
    required PickedProof proof,
  }) async {
    // Only an allowed student subscribes, and a verified account always has a school (ADR 0012).
    final schoolId = profile.schoolId!;
    final String path;
    try {
      path = await _ref.read(proofsRepositoryProvider).upload(
            schoolId: schoolId,
            studentId: profile.id,
            bytes: proof.bytes,
            contentType: proof.contentType,
          );
    } on Invalid catch (e) {
      // Only here is a refusal about the photo; a refused request below is about the semester, the stop or the rules.
      throw ProofRejected(e);
    }
    await _ref.read(subscriptionsRepositoryProvider).request(
          NewSubscription(schoolId: schoolId, studentId: profile.id, semesterId: semester.id, stopId: stop.id, proofPath: path),
        );
    _ref.invalidate(subscriptionOverviewProvider);
  }
}

final subscriptionServiceProvider = Provider<SubscriptionService>(SubscriptionService.new);

SubscribeFailure failureFor(Object error) => switch (error) {
      // The server's own short reasons first (`proof_required`, `proof_missing`, `semester_ended`).
      Conflict(reason: 'semester_ended') => SubscribeFailure.semesterEnded,
      Invalid(reason: 'proof_required' || 'proof_missing') => SubscribeFailure.proofRequired,
      // The semester or the stop was removed meanwhile (the screen showed an old list).
      Invalid(reason: 'missing_reference') => SubscribeFailure.unavailable,
      Conflict() => SubscribeFailure.alreadyRequested,
      Offline() => SubscribeFailure.offline,
      // Only a refusal of the upload itself is about the file; any other Invalid is not.
      ProofRejected() => SubscribeFailure.rejectedFile,
      _ => SubscribeFailure.other,
    };

/// Where a signed-in student should land when the app opens: on the boarding code if they already have an approved
/// subscription (that is what they need at the door), otherwise on the subscription tab. Any trouble reading it falls back
/// to the subscription tab, which explains and can retry.
final landingPathProvider = FutureProvider.autoDispose<String>((ref) async {
  // Right after setup, My area is offered once (ADR 0023); a new student has no pass to show yet.
  if (ref.watch(areaIntroPendingProvider)) return '/area?intro=1';
  try {
    final overview = await ref.watch(subscriptionOverviewProvider.future);
    final school = await ref.watch(schoolProvider.future);
    final today = ref.watch(schoolClockProvider).today(school.timezone, now: ref.read(nowProvider)());
    // A copy saved on the phone opens the code only while its semester is running; a fresh answer is taken as it is.
    return overview.passUsable(today) ? '/qr' : '/subscription';
  } catch (_) {
    return '/subscription';
  }
}, retry: noAutomaticRetry);
