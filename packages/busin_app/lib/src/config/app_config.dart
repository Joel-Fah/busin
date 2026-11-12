/// Public values the app is built with, passed as
/// `--dart-define-from-file=config/<env>.json`. Nothing secret belongs here: the publishable key is
/// meant for clients, and what a user may do is decided by Row Level Security on the server.
class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.publishableKey,
    required this.googleServerClientId,
    required this.environment,
    this.mapStyleUrl = defaultMapStyleUrl,
    this.darkMapStyleUrl = defaultDarkMapStyleUrl,
  });

  /// Reads the values the app was compiled with.
  factory AppConfig.fromEnvironment() => const AppConfig(
        supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
        publishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
        googleServerClientId: String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
        environment: String.fromEnvironment('APP_ENV', defaultValue: 'dev'),
        mapStyleUrl: String.fromEnvironment('MAP_STYLE_URL', defaultValue: defaultMapStyleUrl),
        darkMapStyleUrl: String.fromEnvironment('MAP_DARK_STYLE_URL', defaultValue: defaultDarkMapStyleUrl),
      );

  final String supabaseUrl;
  final String publishableKey;

  /// The Web application OAuth client id from Google Cloud. Supabase checks the Google ID token against it.
  final String googleServerClientId;
  final String environment;

  /// The base map. OpenFreeMap needs no key and no account (ADR 0008); point this at another style to change provider.
  final String mapStyleUrl;

  /// The base map used when the phone is in dark mode.
  final String darkMapStyleUrl;

  static const defaultMapStyleUrl = 'https://tiles.openfreemap.org/styles/liberty';
  static const defaultDarkMapStyleUrl = 'https://tiles.openfreemap.org/styles/dark';

  /// Names of the values that are missing, so a developer sees exactly what to add.
  List<String> get missing => [
        if (supabaseUrl.isEmpty) 'SUPABASE_URL',
        if (publishableKey.isEmpty) 'SUPABASE_PUBLISHABLE_KEY',
        if (googleServerClientId.isEmpty) 'GOOGLE_SERVER_CLIENT_ID',
      ];

  bool get isComplete => missing.isEmpty;
}
