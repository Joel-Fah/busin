import 'package:busin_core/busin_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/access.dart';
import '../providers.dart';
import '../school_clock.dart';
import 'proof_picker.dart';

final stopsRepositoryProvider = Provider<StopsRepository>((ref) => ref.watch(repositoriesProvider).stops);
final semestersRepositoryProvider = Provider<SemestersRepository>((ref) => ref.watch(repositoriesProvider).semesters);
final subscriptionsRepositoryProvider = Provider<SubscriptionsRepository>((ref) => ref.watch(repositoriesProvider).subscriptions);
final proofsRepositoryProvider = Provider<ProofsRepository>((ref) => ref.watch(repositoriesProvider).proofs);
final schoolRepositoryProvider = Provider<SchoolRepository>((ref) => ref.watch(repositoriesProvider).schools);

final schoolClockProvider = Provider<SchoolClock>((ref) => const SchoolClock());
final proofPickerProvider = Provider<ProofPicker>((ref) => ImagePickerProofPicker());

/// The stops a student can pick from. Read once for the session; it resets when the user changes.
final stopsProvider = FutureProvider<List<Stop>>((ref) async {
  if (ref.watch(authUserIdProvider).value == null) return const [];
  return ref.watch(stopsRepositoryProvider).listActiveStops();
});

/// Where a student stands for the semester that matters now.
class SubscriptionOverview {
  const SubscriptionOverview({this.semester, this.upcoming = false, this.subscription, this.stop});

  /// No semester is open or coming.
  const SubscriptionOverview.none() : this();

  /// The current semester, or the next one when none is running.
  final Semester? semester;

  /// True when [semester] has not started yet.
  final bool upcoming;

  /// The student's pending or approved request, or else the latest one that ended in rejection or expiry.
  final Subscription? subscription;

  /// The stop of [subscription].
  final Stop? stop;
}

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

  final school = await ref.watch(schoolRepositoryProvider).getSchool(profile.schoolId);
  final today = ref.watch(schoolClockProvider).today(school.timezone);

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
});

/// A short-lived address to show a stored proof. Fetched when the proof is on screen and not kept.
final proofUrlProvider = FutureProvider.autoDispose.family<String, String>(
  (ref, path) => ref.watch(proofsRepositoryProvider).signedUrl(path),
);

/// Why a request could not be sent, as the screen explains it.
enum SubscribeFailure { alreadyRequested, offline, rejectedFile, other }

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
    final path = await _ref.read(proofsRepositoryProvider).upload(
          schoolId: profile.schoolId,
          studentId: profile.id,
          bytes: proof.bytes,
          contentType: proof.contentType,
        );
    await _ref.read(subscriptionsRepositoryProvider).request(
          NewSubscription(schoolId: profile.schoolId, studentId: profile.id, semesterId: semester.id, stopId: stop.id, proofPath: path),
        );
    _ref.invalidate(subscriptionOverviewProvider);
  }
}

final subscriptionServiceProvider = Provider<SubscriptionService>(SubscriptionService.new);

SubscribeFailure failureFor(Object error) => switch (error) {
      Conflict() => SubscribeFailure.alreadyRequested,
      Offline() => SubscribeFailure.offline,
      Invalid() => SubscribeFailure.rejectedFile,
      _ => SubscribeFailure.other,
    };
