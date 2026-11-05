/// Public values the app is built with, passed as
/// `--dart-define-from-file=config/<env>.json`. Nothing secret belongs here: the publishable key is
/// meant for clients, and what a user may do is decided by Row Level Security on the server.
class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.publishableKey,
    required this.googleServerClientId,
    required this.environment,
  });

  /// Reads the values the app was compiled with.
  factory AppConfig.fromEnvironment() => const AppConfig(
        supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
        publishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
        googleServerClientId: String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
        environment: String.fromEnvironment('APP_ENV', defaultValue: 'dev'),
      );

  final String supabaseUrl;
  final String publishableKey;

  /// The Web application OAuth client id from Google Cloud. Supabase checks the Google ID token against it.
  final String googleServerClientId;
  final String environment;

  /// Names of the values that are missing, so a developer sees exactly what to add.
  List<String> get missing => [
        if (supabaseUrl.isEmpty) 'SUPABASE_URL',
        if (publishableKey.isEmpty) 'SUPABASE_PUBLISHABLE_KEY',
        if (googleServerClientId.isEmpty) 'GOOGLE_SERVER_CLIENT_ID',
      ];

  bool get isComplete => missing.isEmpty;
}
