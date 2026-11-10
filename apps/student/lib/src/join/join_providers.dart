import 'package:busin_core/busin_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/access.dart';
import '../providers.dart';
import '../subscription/subscription_providers.dart';

/// The schools the signed-in account may ask to join (only while it needs a school).
final openSchoolsProvider = FutureProvider.autoDispose<List<OpenSchool>>((ref) async {
  if (ref.watch(accessProvider) is! NeedsSchool) return const [];
  return ref.watch(joinRepositoryProvider).listOpenSchools();
}, retry: noAutomaticRetry);

/// The account's own request (or the last decline), while it is pending.
final myJoinRequestProvider = FutureProvider.autoDispose<JoinRequest?>((ref) async {
  final access = ref.watch(accessProvider);
  if (access is! NeedsSchool && access is! AwaitingSchool) return null;
  return ref.watch(joinRepositoryProvider).myRequest();
}, retry: noAutomaticRetry);

/// Asks to join a school, or withdraws the request (null), then reloads the profile so the access rules move the app on.
final requestSchoolProvider = Provider<Future<void> Function(String? schoolId)>((ref) {
  return (schoolId) async {
    await ref.read(joinRepositoryProvider).requestSchool(schoolId);
    ref.invalidate(profileProvider);
    ref.invalidate(myJoinRequestProvider);
  };
});

/// Whether a refusal was the "not again so soon" rule of request_school.
bool isTooSoon(Object error) => error is RepositoryException && error.message.contains('54000');

/// The school a student who joined with a school email is joining, for the "You are joining X" card on setup.
final setupSchoolProvider = FutureProvider.autoDispose<School?>((ref) async {
  final access = ref.watch(accessProvider);
  if (access is! NeedsSetup) return null;
  final schoolId = access.profile.schoolId;
  return schoolId == null ? null : ref.watch(schoolRepositoryProvider).getSchool(schoolId);
}, retry: noAutomaticRetry);
