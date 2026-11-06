import 'package:busin_core/busin_core.dart';
import 'package:busin_data/busin_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/access.dart';
import 'auth/auth_service.dart';
import 'config/app_config.dart';
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

final languageCodeProvider = Provider<String Function()>((ref) => systemLanguageCode);

final pushRegistrarProvider = Provider<PushRegistrar>(
  (ref) => PushRegistrar(
    push: ref.watch(pushServiceProvider),
    tokens: ref.watch(deviceTokensRepositoryProvider),
    languageCode: ref.watch(languageCodeProvider),
    platform: defaultTargetPlatform,
  ),
);

final repositoriesProvider = Provider<SupabaseRepositories>((ref) => SupabaseRepositories(ref.watch(supabaseClientProvider)));

final academicRepositoryProvider = Provider<AcademicRepository>((ref) => ref.watch(repositoriesProvider).academic);
final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ref.watch(repositoriesProvider).profiles);

/// The signed-in user's id, or null. Everything that holds user data watches this, so it resets on sign-out.
final authUserIdProvider = StreamProvider<String?>((ref) => ref.watch(authServiceProvider).userIdChanges);

/// The signed-in user's own profile, read from the server (never from anything the device stored).
final profileProvider = FutureProvider<Profile?>((ref) async {
  final userId = ref.watch(authUserIdProvider).value;
  if (userId == null) return null;
  return ref.watch(profileRepositoryProvider).getProfile(userId);
});

/// The faculties, departments and degree levels a student chooses from. Read once for the session; resets with the user.
final academicUnitsProvider = FutureProvider<AcademicUnits>((ref) async {
  if (ref.watch(authUserIdProvider).value == null) return const AcademicUnits();
  return ref.watch(academicRepositoryProvider).load();
});

/// Whether the logo is drawn when the app opens. Tests switch it off.
final introEnabledProvider = Provider<bool>((ref) => true);

/// Whether the opening animation has finished (or was skipped). It plays once per cold start; until then the router
/// keeps the splash screen up, whatever the access state says.
class IntroDone extends Notifier<bool> {
  @override
  bool build() => !ref.watch(introEnabledProvider);

  void finish() => state = true;
}

final introDoneProvider = NotifierProvider<IntroDone, bool>(IntroDone.new);

/// What the app may show. The router and every guarded screen read this.
final accessProvider = Provider<AccessState>((ref) {
  final session = ref.watch(authUserIdProvider);
  final profile = ref.watch(profileProvider);
  return accessFor(
    sessionLoading: session.isLoading,
    userId: session.value,
    profileLoading: profile.isLoading,
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
    await ref.read(authServiceProvider).signOut();
  };
});
