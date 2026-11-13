import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:busin_data/busin_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/access.dart';
import 'reminders/notification_providers.dart';
import 'offline/pass_snapshot.dart';
import 'push/push_registrar.dart';
import 'push/push_service.dart';
import 'qr/secret_store.dart';

/// Set once at start-up (see main.dart). Tests override the providers below it instead.
final appConfigProvider = Provider<AppConfig>((ref) => throw UnimplementedError('appConfigProvider is overridden at start-up'));

final supabaseClientProvider = Provider<SupabaseClient>((ref) => throw UnimplementedError('supabaseClientProvider is overridden at start-up'));

final authServiceProvider = Provider<AuthService>((ref) => throw UnimplementedError('authServiceProvider is overridden at start-up'));

final secretStoreProvider = Provider<SecretStore>((ref) => SecureSecretStore());

/// Firebase Cloud Messaging, or a stand-in that does nothing when this build has no Firebase configuration.
final pushServiceProvider = Provider<PushService>((ref) => const NoPushService());

final deviceTokensRepositoryProvider = Provider<DeviceTokensRepository>((ref) => ref.watch(repositoriesProvider).deviceTokens);

/// The language notifications should come in: the one chosen on the profile, else the phone's.
final languageCodeProvider = Provider<String Function()>((ref) => () => ref.read(localeProvider)?.languageCode ?? systemLanguageCode());

final pushRegistrarProvider = Provider<PushRegistrar>(
  (ref) => PushRegistrar(
    push: ref.watch(pushServiceProvider),
    tokens: ref.watch(deviceTokensRepositoryProvider),
    languageCode: ref.watch(languageCodeProvider),
    platform: defaultTargetPlatform,
  ),
);

/// What every provider that asks the server does when it fails: nothing more. Riverpod would otherwise ask again up to ten
/// times with growing pauses, which hammers a server that just said no (or says "not allowed") and keeps the loading screen
/// up for a minute when the backend is unreachable. Each screen has its own Try again for a failure.
Duration? noAutomaticRetry(int retryCount, Object error) => null;

final repositoriesProvider = Provider<SupabaseRepositories>((ref) => SupabaseRepositories(ref.watch(supabaseClientProvider)));

final academicRepositoryProvider = Provider<AcademicRepository>((ref) => ref.watch(repositoriesProvider).academic);
final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ref.watch(repositoriesProvider).profiles);
final joinRepositoryProvider = Provider<JoinRepository>((ref) => ref.watch(repositoriesProvider).joining);

/// The signed-in user's id, or null. Everything that holds user data watches this, so it resets on sign-out.
/// The time, a function so tests can stand still.
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Where the saved copy of the pass facts lives, and the one that keeps it (see `offline/pass_snapshot.dart`).
final snapshotStoreProvider = Provider<SnapshotStore>((ref) => SecureSnapshotStore());
final snapshotKeeperProvider = Provider<SnapshotKeeper>((ref) => SnapshotKeeper(ref.watch(snapshotStoreProvider), () => ref.read(nowProvider)()));

final authUserIdProvider = StreamProvider<String?>((ref) => ref.watch(authServiceProvider).userIdChanges);

/// Looks again at the signed-in person's profile and reloads the app's access when the role, the status (suspended,
/// pending) or the school changed on the server. Called when the app returns to the foreground and when the server
/// reports a change. Quiet: nothing flickers when nothing changed, and without a connection nothing is assumed.
final accountRecheckProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final current = ref.read(profileProvider).value;
    if (current == null) return;
    final changed = await accountChanged(repository: ref.read(profileRepositoryProvider), current: current);
    if (changed == true) ref.invalidate(profileProvider);
  };
});

/// The signed-in user's own profile, read from the server. Only when the server cannot be reached is the copy saved on the
/// phone used instead (so the app can open offline); a server answer, even a refusal, always wins over it.
final profileProvider = FutureProvider<Profile?>((ref) async {
  final userId = ref.watch(authUserIdProvider).value;
  if (userId == null) return null;
  final keeper = ref.watch(snapshotKeeperProvider);
  return serverOrSaved<Profile?>(
    ref,
    source: 'profile',
    live: () => ref.watch(profileRepositoryProvider).getProfile(userId),
    // Only a verified student keeps a copy: anything else is cleared, so a blocked account cannot open offline.
    save: (profile) => profile != null && profile.role == UserRole.student && profile.status == AccountStatus.verified ? keeper.saveProfile(userId, profile) : keeper.clear(userId),
    saved: () async {
      final snapshot = await keeper.load(userId);
      final profile = snapshot?.profile;
      return profile == null ? null : (value: profile, savedAt: snapshot!.savedAt);
    },
  );
}, retry: noAutomaticRetry);

/// The faculties, departments and degree levels a student chooses from. Read once for the session; resets with the user.
final academicUnitsProvider = FutureProvider<AcademicUnits>((ref) async {
  if (ref.watch(authUserIdProvider).value == null) return const AcademicUnits();
  return ref.watch(academicRepositoryProvider).load();
}, retry: noAutomaticRetry);

/// Whether the logo is drawn when the app opens. Tests switch it off.
final introEnabledProvider = Provider<bool>((ref) => true);

/// Whether the opening animation has finished (or was skipped). It plays once per cold start; until then the router
/// keeps the splash screen up, whatever the access state says.
class IntroDone extends Notifier<bool> {
  @override
  bool build() => !ref.watch(introEnabledProvider);

  void finish() {
    state = true;
    // The mark that was just drawn travels to its place on the next screen, once.
    ref.read(logoHandoffProvider.notifier).arm();
  }
}

final introDoneProvider = NotifierProvider<IntroDone, bool>(IntroDone.new);

/// True from the end of the opening animation until the first screen after it has taken the mark and moved it to its
/// corner. Only that one arrival does it: coming back to sign-in after signing out does not.
class LogoHandoff extends Notifier<bool> {
  @override
  bool build() => false;

  void arm() => state = true;

  void consume() => state = false;
}

final logoHandoffProvider = NotifierProvider<LogoHandoff, bool>(LogoHandoff.new);

/// What the app may show. The router and every guarded screen read this.
final accessProvider = Provider<AccessState>((ref) {
  // A reload in the background keeps what is in hand: only the first read, or a different person, counts as loading.
  final session = held(ref.watch(authUserIdProvider));
  final profile = held(ref.watch(profileProvider), belongs: (p) => p == null || p.id == session.value);
  return accessFor(
    sessionLoading: session.loading,
    userId: session.value,
    profileLoading: profile.loading,
    profileError: profile.error,
    profile: profile.value,
  );
});

/// Signs out and forgets what must not outlive the session: this phone's push registration and the boarding
/// secret go before the session does, so a phone handed to someone else holds nothing of the last student's.
final signOutProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    // While still signed in, so the server accepts removing this phone.
    await ref.read(pushRegistrarProvider).forget();
    await ref.read(secretStoreProvider).deleteAll();
    await ref.read(snapshotKeeperProvider).clearAll();
    // Reminders belong to this student: the next person on this phone must not get them.
    await ref.read(reminderSchedulerProvider).replace(const [], timeZone: 'UTC', text: (_) => (title: '', body: ''));
    await ref.read(authServiceProvider).signOut();
  };
});
