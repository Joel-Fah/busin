import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';
import 'src/auth/secure_session_storage.dart';
import 'src/auth/supabase_auth_service.dart';
import 'src/config/app_config.dart';
import 'src/push/push_service.dart';
import 'src/providers.dart';
import 'src/settings/appearance.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  if (!config.isComplete) {
    // A build without its configuration is a developer mistake, not something a student should ever see.
    runApp(_MissingConfig(missing: config.missing));
    return;
  }

  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.publishableKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureSessionStorage(),
      // Sign-in uses the Google ID token, so no deep link is involved.
      detectSessionInUri: false,
    ),
    // No silent retries of failed reads: with no connection the answer must come at once, so the app can use the pass saved
    // on the phone instead of waiting half a minute. Every screen has its own Try again.
    postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
  );
  final client = Supabase.instance.client;
  // Without Firebase configured this is a stand-in that does nothing, and the app works the same otherwise.
  final push = await FirebasePushService.tryCreate();
  // Read before the first frame, so the chosen theme and language are there from the start (no flash of the other one).
  final preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      retry: noAutomaticRetry,
      overrides: [
        appPreferencesProvider.overrideWithValue(preferences),
        appConfigProvider.overrideWithValue(config),
        supabaseClientProvider.overrideWithValue(client),
        pushServiceProvider.overrideWithValue(push),
        authServiceProvider.overrideWithValue(SupabaseAuthService(client, googleServerClientId: config.googleServerClientId)),
      ],
      child: const StudentApp(),
    ),
  );
}

class _MissingConfig extends StatelessWidget {
  const _MissingConfig({required this.missing});

  final List<String> missing;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'This build has no configuration. Missing: ${missing.join(', ')}.\n\n'
              'Run with --dart-define-from-file=config/dev.json (see config/dev.example.json).',
            ),
          ),
        ),
      ),
    );
  }
}
