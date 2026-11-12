import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:busin_data/busin_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'access.dart';
import 'keys/roster.dart';
import 'offline/ops_snapshot.dart';

/// Set once at start-up (see main.dart). Tests override the providers below it instead.
final appConfigProvider = Provider<AppConfig>((ref) => throw UnimplementedError('appConfigProvider is overridden at start-up'));

final supabaseClientProvider = Provider<SupabaseClient>((ref) => throw UnimplementedError('supabaseClientProvider is overridden at start-up'));

final authServiceProvider = Provider<AuthService>((ref) => throw UnimplementedError('authServiceProvider is overridden at start-up'));

/// A failed read is not retried by itself: each screen has its own Try again.
Duration? noAutomaticRetry(int retryCount, Object error) => null;

final repositoriesProvider = Provider<SupabaseRepositories>((ref) => SupabaseRepositories(ref.watch(supabaseClientProvider)));

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ref.watch(repositoriesProvider).profiles);
final schoolRepositoryProvider = Provider<SchoolRepository>((ref) => ref.watch(repositoriesProvider).schools);
final tripsRepositoryProvider = Provider<TripsRepository>((ref) => ref.watch(repositoriesProvider).trips);
final busesRepositoryProvider = Provider<BusesRepository>((ref) => ref.watch(repositoriesProvider).buses);

/// The time, a function so tests can stand still.
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final schoolClockProvider = Provider<SchoolClock>((ref) => const SchoolClock());

/// The signed-in user's id, or null. Everything that holds user data watches this, so it resets on sign-out.
final authUserIdProvider = StreamProvider<String?>((ref) => ref.watch(authServiceProvider).userIdChanges);

/// Where the copy that lets the app open offline is kept (secure storage).
final opsSnapshotStoreProvider = Provider<OpsSnapshotStore>((ref) => SecureOpsSnapshotStore());

final opsSnapshotKeeperProvider = Provider<OpsSnapshotKeeper>((ref) => OpsSnapshotKeeper(ref.watch(opsSnapshotStoreProvider), ref.watch(nowProvider)));

/// The signed-in user's own profile, read from the server. Only when the server cannot be reached is the copy saved on the
/// phone used instead (so the app opens offline); a server answer, even a refusal, always wins over it.
final profileProvider = FutureProvider<Profile?>((ref) async {
  final userId = ref.watch(authUserIdProvider).value;
  if (userId == null) return null;
  final keeper = ref.watch(opsSnapshotKeeperProvider);
  return serverOrSaved<Profile?>(
    ref,
    source: 'profile',
    live: () => ref.watch(profileRepositoryProvider).getProfile(userId),
    // Only an active staff member or administrator keeps a copy: anything else is wiped, so a blocked account cannot open
    // offline.
    save: (profile) => profile != null && profile.role != UserRole.student && profile.status == AccountStatus.verified ? keeper.saveProfile(userId, profile) : keeper.clear(userId),
    saved: () async {
      final snapshot = await keeper.load(userId);
      final profile = snapshot?.profile;
      return profile == null ? null : (value: profile, savedAt: snapshot!.savedAt);
    },
  );
}, retry: noAutomaticRetry);

/// Looks again at the signed-in person's profile and reloads the app's access when the role, the status (suspended,
/// pending) or the school changed on the server. Called when the app returns to the foreground, when the server reports
/// a change, and when a call is refused. Quiet: nothing flickers when nothing changed, and without a connection nothing
/// is assumed.
final accountRecheckProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final access = ref.read(accessProvider);
    final current = access is OpsAllowed ? access.profile : ref.read(profileProvider).value;
    if (current == null) return;
    final changed = await accountChanged(repository: ref.read(profileRepositoryProvider), current: current);
    if (changed == true) ref.invalidate(profileProvider);
  };
});

/// What the app may show. The router and every guarded screen read this.
final accessProvider = Provider<OpsAccess>((ref) {
  // A reload in the background keeps what is in hand: only the first read, or a different person, counts as loading.
  final session = held(ref.watch(authUserIdProvider));
  final profile = held(ref.watch(profileProvider), belongs: (p) => p == null || p.id == session.value);
  return opsAccessFor(
    sessionLoading: session.loading,
    userId: session.value,
    profileLoading: profile.loading,
    profileError: profile.error,
    profile: profile.value,
  );
});

/// The staff member's school (its time zone decides what "today" is).
final schoolProvider = FutureProvider<School>((ref) async {
  final access = ref.watch(accessProvider);
  if (access is! OpsAllowed) throw StateError('Only staff have a school here.');
  final userId = access.profile.id;
  final keeper = ref.watch(opsSnapshotKeeperProvider);
  return serverOrSaved<School>(
    ref,
    source: 'school',
    live: () => ref.watch(schoolRepositoryProvider).getSchool(access.profile.schoolId!),
    save: (school) => keeper.saveSchool(userId, school),
    saved: () async {
      final snapshot = await keeper.load(userId);
      final school = snapshot?.school;
      return school == null || school.id != access.profile.schoolId ? null : (value: school, savedAt: snapshot!.savedAt);
    },
  );
}, retry: noAutomaticRetry);

/// Signs out and forgets today's day keys and the copy kept for opening offline. The scan queue is kept: scans are never dropped (the screens refuse to sign
/// out while some wait to be sent).
final signOutProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await ref.read(rosterStoreProvider).clear();
    await ref.read(opsSnapshotKeeperProvider).clearAll();
    await ref.read(authServiceProvider).signOut();
  };
});

/// Where today's day keys are kept on the phone (secure storage).
final rosterStoreProvider = Provider<RosterStore>((ref) => SecureRosterStore());
