import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:flutter/painting.dart' show ImageProvider, NetworkImage;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/access.dart';
import '../providers.dart';
import 'billing_choices.dart';
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

/// Picks what to show for a semester: a live request wins (the earliest month first, with monthly billing); otherwise the
/// newest of the rest. A monthly subscription whose month has ended is no longer live: then nothing is shown and the form
/// offers the new month. The list arrives newest first. [today] is the school's day.
Subscription? subscriptionToShow(List<Subscription> mine, String semesterId, {DateTime? today}) {
  final inSemester = mine.where((s) => s.semesterId == semesterId).toList();
  final live = liveRequests(inSemester, today);
  if (live.isNotEmpty) return live.first;
  if (inSemester.isEmpty) return null;
  final newest = inSemester.first;
  return newest.isLive ? null : newest;
}

/// The pending and approved requests that have not ended, earliest month first (a whole-semester one comes first).
List<Subscription> liveRequests(Iterable<Subscription> mine, DateTime? today) {
  final live = [for (final s in mine) if (s.isLive && (today == null || stillRunning(s, today))) s];
  live.sort((a, b) => (a.periodStart ?? DateTime.utc(0)).compareTo(b.periodStart ?? DateTime.utc(0)));
  return live;
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
      final subscription = subscriptionToShow(mine, semester.id, today: today);
      final stop = subscription == null ? null : await ref.watch(stopsRepositoryProvider).getStop(subscription.stopId);
      final live = liveRequests(mine.where((s) => s.semesterId == semester!.id), today);
      return SubscriptionOverview(semester: semester, upcoming: upcoming, subscription: subscription, stop: stop, live: live);
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
enum SubscribeFailure { alreadyRequested, offline, rejectedFile, proofRequired, semesterEnded, periodEnded, billingNotSet, unavailable, other }

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
    PaymentMode paymentMode = PaymentMode.full,
    DateTime? month,
    bool refresh = true,
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
          NewSubscription(
            schoolId: schoolId,
            studentId: profile.id,
            semesterId: semester.id,
            stopId: stop.id,
            proofPath: path,
            paymentMode: paymentMode,
            periodStart: month == null ? null : DateTime.utc(month.year, month.month),
          ),
        );
    // The caller may ask something first (keep the way of paying?) and reload the overview itself.
    if (refresh) _ref.invalidate(subscriptionOverviewProvider);
  }
}

final subscriptionServiceProvider = Provider<SubscriptionService>(SubscriptionService.new);

SubscribeFailure failureFor(Object error) => switch (error) {
      // The server's own short reasons first (`proof_required`, `proof_missing`, `semester_ended`).
      Conflict(reason: 'semester_ended') => SubscribeFailure.semesterEnded,
      Conflict(reason: 'period_ended') => SubscribeFailure.periodEnded,
      Conflict(reason: 'billing_not_set') => SubscribeFailure.billingNotSet,
      // The school changed its billing meanwhile (a month, or installments no longer offered): read it again.
      Invalid(reason: 'installments_not_offered' || 'month_required' || 'month_not_allowed') => SubscribeFailure.unavailable,
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
