import 'package:busin_core/busin_core.dart';
import 'package:test/test.dart';

void main() {
  final row = {
    'riding_days': 31,
    'morning_on': true,
    'morning_time': '06:30:00',
    'evening_on': false,
    'evening_time': '16:30:00',
    'bus_near_on': true,
    'bus_near_minutes': 5,
    'boarding_messages_on': true,
  };

  test('the trip and stop alert settings are read', () {
    final p = NotificationPreferences.fromJson({...row, 'trip_started_on': false, 'stop_alerts_on': true});
    expect(p.tripStartedOn, isFalse);
    expect(p.stopAlertsOn, isTrue);
    expect(p.copyWith(stopAlertsOn: false).stopAlertsOn, isFalse);
    expect(p.copyWith(stopAlertsOn: false), isNot(p));
  });

  test('a server that does not send them yet leaves them on, as the database defaults them', () {
    final p = NotificationPreferences.fromJson(row);
    expect(p.tripStartedOn, isTrue);
    expect(p.stopAlertsOn, isTrue);
  });
}
