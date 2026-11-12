import '../enums.dart';
import '../json.dart';
import '../value_object.dart';

/// What a staff member was on a trip.
enum CrewPart {
  driver,
  assistant,

  /// Started it without being on the crew (an administrator on a trip nobody was assigned to).
  starter;

  static CrewPart parse(Object? raw) => values.firstWhere((v) => v.name == raw, orElse: () => starter);
}

/// How late a scheduled trip may start and still count as on time (owner decision). The server uses the same rule.
const onTimeSlack = Duration(minutes: 10);

/// One past trip of the signed-in staff member (`my_trip_history`): the trip, the bus's name, their part and how many
/// students boarded.
class TripHistoryEntry extends ValueObject {
  const TripHistoryEntry({
    required this.id,
    required this.busId,
    required this.busLabel,
    required this.direction,
    required this.status,
    required this.scheduledStart,
    required this.part,
    required this.boarded,
    this.origin = 'scheduled',
    this.startedAt,
    this.endedAt,
  });

  factory TripHistoryEntry.fromJson(Map<String, dynamic> json) => TripHistoryEntry(
        id: reqString(json, 'id'),
        busId: reqString(json, 'bus_id'),
        busLabel: reqString(json, 'bus_label'),
        direction: TripDirection.parse(json['direction']),
        status: TripStatus.parse(json['status']),
        origin: optString(json, 'origin') ?? 'scheduled',
        scheduledStart: reqTimestamp(json, 'scheduled_start'),
        startedAt: optTimestamp(json, 'started_at'),
        endedAt: optTimestamp(json, 'ended_at'),
        part: CrewPart.parse(json['my_role']),
        boarded: reqInt(json, 'boarded'),
      );

  final String id;
  final String busId;
  final String busLabel;
  final TripDirection direction;
  final TripStatus status;
  final String origin;
  final DateTime scheduledStart;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final CrewPart part;
  final int boarded;

  bool get startedInField => origin == 'field';

  /// How late it started, for a scheduled trip that started (an early start is no delay); null otherwise.
  Duration? get delay {
    final started = startedAt;
    if (started == null || startedInField) return null;
    final late = started.difference(scheduledStart);
    return late.isNegative ? Duration.zero : late;
  }

  /// Started within [onTimeSlack] of its schedule; null when punctuality does not apply.
  bool? get onTime {
    final d = delay;
    return d == null ? null : d <= onTimeSlack;
  }

  /// Time on the road, once it ended.
  Duration? get duration {
    final started = startedAt;
    final ended = endedAt;
    return started == null || ended == null ? null : ended.difference(started);
  }

  @override
  List<Object?> get props => [id, busId, busLabel, direction, status, origin, scheduledStart, startedAt, endedAt, part, boarded];
}

/// One week of the signed-in staff member's trips (`my_trip_stats`), Monday to Sunday at the school.
class WeekStats extends ValueObject {
  const WeekStats({
    required this.weekStart,
    this.trips = 0,
    this.completed = 0,
    this.cancelled = 0,
    this.missed = 0,
    this.onTime = 0,
    this.late = 0,
    this.avgDelayMinutes,
    this.boarded = 0,
    this.minutesOnRoad = 0,
    this.asDriver = 0,
    this.asAssistant = 0,
    this.fieldTrips = 0,
  });

  factory WeekStats.fromJson(Map<String, dynamic> json) => WeekStats(
        weekStart: reqDate(json, 'week_start'),
        trips: reqInt(json, 'trips'),
        completed: reqInt(json, 'completed'),
        cancelled: reqInt(json, 'cancelled'),
        missed: reqInt(json, 'missed'),
        onTime: reqInt(json, 'on_time'),
        late: reqInt(json, 'late'),
        avgDelayMinutes: optDouble(json, 'avg_delay_minutes'),
        boarded: reqInt(json, 'boarded'),
        minutesOnRoad: reqInt(json, 'minutes_on_road'),
        asDriver: reqInt(json, 'as_driver'),
        asAssistant: reqInt(json, 'as_assistant'),
        fieldTrips: reqInt(json, 'field_trips'),
      );

  /// The Monday the week starts on (a calendar day, UTC midnight).
  final DateTime weekStart;
  final int trips;
  final int completed;
  final int cancelled;
  final int missed;
  final int onTime;
  final int late;

  /// Average lateness of the scheduled trips that started; null for a week without any.
  final double? avgDelayMinutes;
  final int boarded;
  final int minutesOnRoad;
  final int asDriver;
  final int asAssistant;
  final int fieldTrips;

  /// Share of the scheduled trips that started on time, 0 to 1; null for a week without any.
  double? get punctuality => onTime + late == 0 ? null : onTime / (onTime + late);

  @override
  List<Object?> get props => [weekStart, trips, completed, cancelled, missed, onTime, late, avgDelayMinutes, boarded, minutesOnRoad, asDriver, asAssistant, fieldTrips];
}

/// Several weeks added up, for the totals at the top of the stats.
class StatsSummary {
  const StatsSummary(this.weeks);

  final List<WeekStats> weeks;

  int _sum(int Function(WeekStats w) f) => weeks.fold(0, (total, w) => total + f(w));

  int get trips => _sum((w) => w.trips);
  int get completed => _sum((w) => w.completed);
  int get cancelled => _sum((w) => w.cancelled);
  int get missed => _sum((w) => w.missed);
  int get onTime => _sum((w) => w.onTime);
  int get late => _sum((w) => w.late);
  int get boarded => _sum((w) => w.boarded);
  int get minutesOnRoad => _sum((w) => w.minutesOnRoad);
  int get asDriver => _sum((w) => w.asDriver);
  int get asAssistant => _sum((w) => w.asAssistant);
  int get fieldTrips => _sum((w) => w.fieldTrips);

  /// Share on time over the whole period, 0 to 1; null without any scheduled trip that started.
  double? get punctuality => onTime + late == 0 ? null : onTime / (onTime + late);

  /// Average lateness over the period, weighted by each week's count of started scheduled trips.
  double? get avgDelayMinutes {
    var minutes = 0.0;
    var count = 0;
    for (final w in weeks) {
      final avg = w.avgDelayMinutes;
      final n = w.onTime + w.late;
      if (avg == null || n == 0) continue;
      minutes += avg * n;
      count += n;
    }
    return count == 0 ? null : minutes / count;
  }

  /// Students boarded per completed trip; null without any.
  double? get boardedPerTrip => completed == 0 ? null : boarded / completed;
}
