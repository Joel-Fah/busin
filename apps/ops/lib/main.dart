import 'package:busin_app/busin_app.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';
import 'src/providers.dart';
import 'src/push/trip_reminders.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  if (!config.isComplete) {
    // A build without its configuration is a developer mistake, not something staff should ever see.
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
    // No silent retries: with no connection the answer must come at once, so the app can work from what it kept.
    postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
  );
  final client = Supabase.instance.client;
  // Without Firebase configured this is a stand-in that does nothing, and the app works the same otherwise.
  final push = await FirebasePushService.tryCreate();
  // Trip reminders arrive as data messages and are drawn by the app, also when it is closed (their End trip button).
  if (push.available) FirebaseMessaging.onBackgroundMessage(opsBackgroundMessage);
  // Crash reports (ADR 0025): release builds only, no personal data. Nothing without Firebase or in a debug build.
  final crashes = await startCrashReports(app: 'ops');
  // Read before the first frame, so the chosen theme and language are there from the start.
  final preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      retry: noAutomaticRetry,
      overrides: [
        appPreferencesProvider.overrideWithValue(preferences),
        appConfigProvider.overrideWithValue(config),
        supabaseClientProvider.overrideWithValue(client),
        pushServiceProvider.overrideWithValue(push),
        crashReporterProvider.overrideWithValue(crashes),
        authServiceProvider.overrideWithValue(SupabaseAuthService(client, googleServerClientId: config.googleServerClientId)),
      ],
      child: const OpsApp(),
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
              'Run with --dart-define-from-file=../../config/dev.json (see config/dev.example.json).',
            ),
          ),
        ),
      ),
    );
  }
}
