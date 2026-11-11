/// App plumbing shared by the BusIn Flutter apps: config from `--dart-define-from-file`, Google sign-in with the
/// session kept in secure storage, the theme and language choices, and the offline helpers.
library;

export 'src/auth/auth_service.dart';
export 'src/auth/secure_session_storage.dart';
export 'src/auth/supabase_auth_service.dart';
export 'src/config/app_config.dart';
export 'src/offline/offline_providers.dart';
export 'src/settings/appearance.dart';
export 'src/time/school_clock.dart';
