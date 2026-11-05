import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';
import 'src/auth/secure_session_storage.dart';
import 'src/auth/supabase_auth_service.dart';
import 'src/config/app_config.dart';
import 'src/providers.dart';

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
  );
  final client = Supabase.instance.client;

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        supabaseClientProvider.overrideWithValue(client),
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
