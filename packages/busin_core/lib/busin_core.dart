/// BusIn domain layer: enums, models, value objects and the rotating QR code
/// generator shared by the student and ops apps.
///
/// The repository interfaces apps program against are here too.
///
/// Pure Dart. Must not import Flutter or any backend SDK; backend access
/// lives in `busin_data`.
library;

export 'src/enums.dart';
export 'src/geo_point.dart';
export 'src/models/academic.dart';
export 'src/models/bus.dart';
export 'src/models/joining.dart';
export 'src/models/live_position.dart';
export 'src/models/notification_preferences.dart';
export 'src/models/profile.dart';
export 'src/models/scan.dart';
export 'src/models/scan_outcome.dart';
export 'src/models/school.dart';
export 'src/models/semester.dart';
export 'src/models/stop.dart';
export 'src/models/subscription.dart';
export 'src/models/subscription_event.dart';
export 'src/models/trip.dart';
export 'src/profile_validation.dart';
export 'src/qr_code.dart';
export 'src/repositories/page.dart';
export 'src/repositories/repositories.dart';
export 'src/repositories/repository_exception.dart';
export 'src/value_object.dart';
