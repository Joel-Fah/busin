import 'package:busin_core/busin_core.dart';
import 'package:busin_data/busin_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/access.dart';
import 'auth/auth_service.dart';
import 'config/app_config.dart';

/// Set once at start-up (see main.dart). Tests override the providers below it instead.
final appConfigProvider = Provider<AppConfig>((ref) => throw UnimplementedError('appConfigProvider is overridden at start-up'));

final supabaseClientProvider = Provider<SupabaseClient>((ref) => throw UnimplementedError('supabaseClientProvider is overridden at start-up'));

final authServiceProvider = Provider<AuthService>((ref) => throw UnimplementedError('authServiceProvider is overridden at start-up'));

final repositoriesProvider = Provider<SupabaseRepositories>((ref) => SupabaseRepositories(ref.watch(supabaseClientProvider)));

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ref.watch(repositoriesProvider).profiles);

/// The signed-in user's id, or null. Everything that holds user data watches this, so it resets on sign-out.
final authUserIdProvider = StreamProvider<String?>((ref) => ref.watch(authServiceProvider).userIdChanges);

/// The signed-in user's own profile, read from the server (never from anything the device stored).
final profileProvider = FutureProvider<Profile?>((ref) async {
  final userId = ref.watch(authUserIdProvider).value;
  if (userId == null) return null;
  return ref.watch(profileRepositoryProvider).getProfile(userId);
});

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
