import 'package:busin_core/busin_core.dart';
import 'package:test/test.dart';

void main() {
  final at = DateTime.utc(2026, 11, 10, 6, 30);

  TripHistoryEntry entry({DateTime? started, DateTime? ended, String origin = 'scheduled'}) => TripHistoryEntry(
        id: 't1',
        busId: 'b1',
        busLabel: 'Blue',
        direction: TripDirection.inbound,
        status: TripStatus.completed,
        scheduledStart: at,
        part: CrewPart.driver,
        boarded: 3,
        origin: origin,
        startedAt: started,
        endedAt: ended,
      );

  test('a history entry reads what the server sends', () {
    final e = TripHistoryEntry.fromJson({
      'id': 't1',
      'bus_id': 'b1',
      'bus_label': 'Blue',
      'direction': 'outbound',
      'status': 'completed',
      'origin': 'field',
      'scheduled_start': '2026-11-10T06:30:00Z',
      'started_at': '2026-11-10T06:31:00Z',
      'ended_at': '2026-11-10T07:31:00Z',
      'my_role': 'assistant',
      'boarded': 12,
    });
    expect(e.part, CrewPart.assistant);
    expect(e.boarded, 12);
    expect(e.startedInField, isTrue);
    expect(e.duration, const Duration(hours: 1));
    expect(CrewPart.parse('something new'), CrewPart.starter);
  });

  test('on time means started no more than 10 minutes late; an early start is no delay', () {
    expect(entry(started: at.add(const Duration(minutes: 10))).onTime, isTrue);
    expect(entry(started: at.add(const Duration(minutes: 11))).onTime, isFalse);
    expect(entry(started: at.subtract(const Duration(minutes: 3))).delay, Duration.zero);
    expect(entry().onTime, isNull, reason: 'never started');
    expect(entry(started: at.add(const Duration(hours: 1)), origin: 'field').onTime, isNull, reason: 'a field trip has no schedule');
  });

  test('a week reads the stats row and gives its punctuality', () {
    final w = WeekStats.fromJson({
      'week_start': '2026-11-09',
      'trips': 5,
      'completed': 3,
      'cancelled': 1,
      'missed': 1,
      'on_time': 3,
      'late': 1,
      'avg_delay_minutes': 6.5,
      'boarded': 40,
      'minutes_on_road': 135,
      'as_driver': 4,
      'as_assistant': 1,
      'field_trips': 1,
    });
    expect(w.weekStart, DateTime.utc(2026, 11, 9));
    expect(w.punctuality, 0.75);
    expect(WeekStats(weekStart: DateTime.utc(2026, 11, 2)).punctuality, isNull, reason: 'an empty week has none');
  });

  test('a summary adds the weeks and weighs the average delay by trips', () {
    final s = StatsSummary([
      WeekStats(weekStart: DateTime.utc(2026, 11, 2), onTime: 1, late: 1, avgDelayMinutes: 10, completed: 2, boarded: 30),
      WeekStats(weekStart: DateTime.utc(2026, 11, 9), onTime: 2, avgDelayMinutes: 1, completed: 2, boarded: 10),
      WeekStats(weekStart: DateTime.utc(2026, 11, 16)),
    ]);
    expect(s.onTime, 3);
    expect(s.punctuality, 0.75);
    expect(s.avgDelayMinutes, closeTo((10 * 2 + 1 * 2) / 4, 1e-9));
    expect(s.boardedPerTrip, 10);
    expect(const StatsSummary([]).punctuality, isNull);
  });
}
