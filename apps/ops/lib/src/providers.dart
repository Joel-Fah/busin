import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:busin_data/busin_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'access.dart';
import 'keys/roster.dart';

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

/// The signed-in user's own profile, from the server.
final profileProvider = FutureProvider<Profile?>((ref) async {
  final userId = ref.watch(authUserIdProvider).value;
  if (userId == null) return null;
  return ref.watch(profileRepositoryProvider).getProfile(userId);
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
  final session = ref.watch(authUserIdProvider);
  final profile = ref.watch(profileProvider);
  return opsAccessFor(
    sessionLoading: session.isLoading,
    userId: session.value,
    profileLoading: profile.isLoading,
    profileError: profile.error,
    profile: profile.value,
  );
});

/// The staff member's school (its time zone decides what "today" is).
final schoolProvider = FutureProvider<School>((ref) async {
  final access = ref.watch(accessProvider);
  if (access is! OpsAllowed) throw StateError('Only staff have a school here.');
  return ref.watch(schoolRepositoryProvider).getSchool(access.profile.schoolId!);
}, retry: noAutomaticRetry);

/// Signs out and forgets today's day keys. The scan queue is kept: scans are never dropped (the screens refuse to sign
/// out while some wait to be sent).
final signOutProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await ref.read(rosterStoreProvider).clear();
    await ref.read(authServiceProvider).signOut();
  };
});

/// Where today's day keys are kept on the phone (secure storage).
final rosterStoreProvider = Provider<RosterStore>((ref) => SecureRosterStore());
