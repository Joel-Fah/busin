/// App plumbing shared by the BusIn Flutter apps: config from `--dart-define-from-file`, Google sign-in with the
/// session kept in secure storage, the theme and language choices, the offline helpers, and the legal texts.
library;

export 'src/account/account_watcher.dart';
export 'src/async/held.dart';
export 'src/auth/auth_service.dart';
export 'src/auth/secure_session_storage.dart';
export 'src/auth/supabase_auth_service.dart';
export 'src/config/app_config.dart';
export 'src/legal/legal_documents.dart';
export 'src/offline/offline_providers.dart';
export 'src/push/push_registrar.dart';
export 'src/push/push_service.dart';
export 'src/settings/appearance.dart';
export 'src/time/school_clock.dart';
