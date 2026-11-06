import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// The calendar day it is at the school, which is what a semester's dates mean. The phone's own zone
/// is not used: a student travelling or a wrong device zone must not change which semester is open.
class SchoolClock {
  const SchoolClock();

  static bool _loaded = false;

  /// Today at [zone] (an IANA name such as `Africa/Douala`) as a plain date, midnight, no zone.
  /// An unknown zone falls back to UTC rather than failing the screen.
  DateTime today(String zone, {DateTime? now}) {
    if (!_loaded) {
      tz_data.initializeTimeZones();
      _loaded = true;
    }
    tz.Location location;
    try {
      location = tz.getLocation(zone);
    } catch (_) {
      location = tz.UTC;
    }
    final local = tz.TZDateTime.from(now ?? DateTime.now(), location);
    return DateTime(local.year, local.month, local.day);
  }
}
