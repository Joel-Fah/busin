// The full data set: since timezone 0.11 the smaller ones leave out link names such as Africa/Douala (an alias of
// Africa/Lagos), which is every school's default zone. It costs about 375 KB more than latest_10y.
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// The calendar day it is at the school, which is what a semester's dates mean. The phone's own zone
/// is not used: a student travelling or a wrong device zone must not change which semester is open.
class SchoolClock {
  const SchoolClock();

  static bool _loaded = false;

  /// Today at [zone] (an IANA name such as `Africa/Douala`) as a plain date, midnight, no zone.
  /// An unknown zone falls back to UTC rather than failing the screen.
  DateTime today(String zone, {DateTime? now}) {
    final local = _toZone(zone, now ?? DateTime.now());
    return DateTime(local.year, local.month, local.day);
  }

  tz.TZDateTime _toZone(String zone, DateTime instant) {
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
    return tz.TZDateTime.from(instant, location);
  }

  /// The instant the school's day [date] begins (midnight in [zone]), in UTC. Used to ask for one school day of trips.
  DateTime dayStart(String zone, DateTime date) {
    _toZone(zone, DateTime.now());
    tz.Location location;
    try {
      location = tz.getLocation(zone);
    } catch (_) {
      location = tz.UTC;
    }
    return tz.TZDateTime(location, date.year, date.month, date.day).toUtc();
  }

  /// The wall-clock time an instant was at the school, as a plain date and time with no zone. Used to
  /// show when a boarding happened and to group boardings by the day it was at the school.
  DateTime wallClock(String zone, DateTime instant) {
    final local = _toZone(zone, instant);
    return DateTime(local.year, local.month, local.day, local.hour, local.minute, local.second);
  }
}
