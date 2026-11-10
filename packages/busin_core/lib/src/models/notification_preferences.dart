import '../json.dart';
import '../value_object.dart';

/// A time of day, without a date or a zone (a reminder's time at the school).
class TimeOfDayValue extends ValueObject {
  const TimeOfDayValue(this.hour, this.minute);

  /// Reads "06:30" or "06:30:00".
  factory TimeOfDayValue.parse(String value) {
    final parts = value.split(':');
    if (parts.length < 2) throw FormatException('Not a time: $value');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) throw FormatException('Not a time: $value');
    return TimeOfDayValue(hour, minute);
  }

  final int hour;
  final int minute;

  /// "06:30", as the database takes it.
  String get text => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  List<Object?> get props => [hour, minute];
}

/// What a student wants to be reminded of, and when. Riding days are what the reminders (and later the streaks) count.
class NotificationPreferences extends ValueObject {
  const NotificationPreferences({
    this.ridingDays = const {DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday},
    this.morningOn = true,
    this.morningTime = const TimeOfDayValue(6, 30),
    this.eveningOn = false,
    this.eveningTime = const TimeOfDayValue(16, 30),
    this.busNearOn = true,
    this.busNearMinutes = 5,
    this.boardingMessagesOn = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) => NotificationPreferences(
        ridingDays: daysFromMask(reqInt(json, 'riding_days')),
        morningOn: reqBool(json, 'morning_on'),
        morningTime: TimeOfDayValue.parse(reqString(json, 'morning_time')),
        eveningOn: reqBool(json, 'evening_on'),
        eveningTime: TimeOfDayValue.parse(reqString(json, 'evening_time')),
        busNearOn: reqBool(json, 'bus_near_on'),
        busNearMinutes: reqInt(json, 'bus_near_minutes'),
        boardingMessagesOn: reqBool(json, 'boarding_messages_on'),
      );

  /// Weekdays as DateTime.monday (1) ... DateTime.sunday (7).
  final Set<int> ridingDays;
  final bool morningOn;
  final TimeOfDayValue morningTime;
  final bool eveningOn;
  final TimeOfDayValue eveningTime;
  final bool busNearOn;

  /// How long before the bus reaches the stop the student is told, 1 to 30.
  final int busNearMinutes;
  final bool boardingMessagesOn;

  /// Monday is bit 0, Sunday bit 6, as stored.
  static int maskOf(Set<int> days) => days.fold(0, (mask, day) => mask | (1 << (day - 1)));

  static Set<int> daysFromMask(int mask) => {for (var day = 1; day <= 7; day++) if (mask & (1 << (day - 1)) != 0) day};

  NotificationPreferences copyWith({
    Set<int>? ridingDays,
    bool? morningOn,
    TimeOfDayValue? morningTime,
    bool? eveningOn,
    TimeOfDayValue? eveningTime,
    bool? busNearOn,
    int? busNearMinutes,
    bool? boardingMessagesOn,
  }) =>
      NotificationPreferences(
        ridingDays: ridingDays ?? this.ridingDays,
        morningOn: morningOn ?? this.morningOn,
        morningTime: morningTime ?? this.morningTime,
        eveningOn: eveningOn ?? this.eveningOn,
        eveningTime: eveningTime ?? this.eveningTime,
        busNearOn: busNearOn ?? this.busNearOn,
        busNearMinutes: busNearMinutes ?? this.busNearMinutes,
        boardingMessagesOn: boardingMessagesOn ?? this.boardingMessagesOn,
      );

  @override
  List<Object?> get props => [ridingDays.toList()..sort(), morningOn, morningTime, eveningOn, eveningTime, busNearOn, busNearMinutes, boardingMessagesOn];
}
