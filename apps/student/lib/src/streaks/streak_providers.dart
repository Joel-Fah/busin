import 'dart:convert';

import 'package:busin_core/busin_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/access.dart';
import '../providers.dart';
import '../push/push_providers.dart';
import '../subscription/subscription_providers.dart';

final streaksRepositoryProvider = Provider<StreaksRepository>((ref) => ref.watch(repositoriesProvider).streaks);

/// Where the last streak is kept on the phone, to show it while offline.
String savedStreakKey(String userId) => 'streak.$userId';

/// The running semester's id when the student keeps a streak, otherwise null.
final _streakSemesterProvider = FutureProvider.autoDispose<String?>((ref) async {
  final access = ref.watch(accessProvider);
  if (access is! Allowed || !access.profile.streakOptIn) return null;
  final overview = await ref.watch(subscriptionOverviewProvider.future);
  return overview.upcoming ? null : overview.semester?.id;
}, retry: noAutomaticRetry);

/// The student's streak this semester, or null when they do not keep one. Offline, the last one seen is shown.
final streakProvider = FutureProvider.autoDispose<Streak?>((ref) async {
  final semesterId = await ref.watch(_streakSemesterProvider.future);
  if (semesterId == null) return null;
  final userId = (ref.read(accessProvider) as Allowed).profile.id;
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  try {
    final streak = await ref.watch(streaksRepositoryProvider).streak(semesterId);
    if (streak != null) await prefs.setString(savedStreakKey(userId), jsonEncode(streak.toJson()));
    return streak;
  } on Offline {
    final saved = prefs.getString(savedStreakKey(userId));
    if (saved == null) rethrow;
    return Streak.fromJson(jsonDecode(saved) as Map<String, dynamic>);
  }
}, retry: noAutomaticRetry);

/// The days of the semester for the calendar.
final rideDaysProvider = FutureProvider.autoDispose<List<RideDay>>((ref) async {
  final semesterId = await ref.watch(_streakSemesterProvider.future);
  if (semesterId == null) return const [];
  return ref.watch(streaksRepositoryProvider).rideDays(semesterId);
}, retry: noAutomaticRetry);

/// Turns streaks on or off, then reloads the profile so the app follows.
final setStreakOptInProvider = Provider<Future<void> Function(bool on)>((ref) {
  return (on) async {
    await ref.read(streaksRepositoryProvider).setOptIn(on);
    ref.invalidate(profileProvider);
  };
});

/// How the student appears on the leaderboard: first name and the initial of the last, as the server shows it.
String leaderboardName(String fullName) {
  final words = fullName.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '';
  if (words.length == 1) return words.first;
  return '${words.first} ${words.last.characters.first.toUpperCase()}.';
}

extension on String {
  Iterable<String> get characters => runes.map(String.fromCharCode);
}
