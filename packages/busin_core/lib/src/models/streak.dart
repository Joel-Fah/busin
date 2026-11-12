import '../json.dart';
import '../value_object.dart';

/// What a day of the semester was for a student who keeps a streak (see the streaks migration).
enum RideDayState {
  rode,
  rest,
  noService,
  missed,
  today,
  future;

  static RideDayState parse(Object? value) => switch (value) {
        'rode' => rode,
        'rest' => rest,
        'no_service' => noService,
        'missed' => missed,
        'today' => today,
        'future' => future,
        _ => throw FormatException('Unknown ride day state: $value'),
      };
}

class RideDay extends ValueObject {
  const RideDay(this.day, this.state);

  factory RideDay.fromJson(Map<String, dynamic> json) => RideDay(reqDate(json, 'day'), RideDayState.parse(json['state']));

  /// A calendar day at the school (midnight, no zone).
  final DateTime day;
  final RideDayState state;

  @override
  List<Object?> get props => [day, state];
}

/// The current and best runs of riding days, and the rides this semester.
class Streak extends ValueObject {
  const Streak({required this.current, required this.best, required this.rides});

  factory Streak.fromJson(Map<String, dynamic> json) =>
      Streak(current: reqInt(json, 'current_streak'), best: reqInt(json, 'best_streak'), rides: reqInt(json, 'rides'));

  final int current;
  final int best;
  final int rides;

  Map<String, dynamic> toJson() => {'current_streak': current, 'best_streak': best, 'rides': rides};

  @override
  List<Object?> get props => [current, best, rides];
}

/// One row of a school's leaderboard: students who keep a streak, shown as first name and initial.
class LeaderboardEntry extends ValueObject {
  const LeaderboardEntry({
    required this.rank,
    required this.displayName,
    required this.currentStreak,
    required this.rides,
    required this.isMe,
    this.avatarUrl,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        rank: reqInt(json, 'rank'),
        displayName: reqString(json, 'display_name'),
        avatarUrl: optString(json, 'avatar_url'),
        currentStreak: reqInt(json, 'current_streak'),
        rides: reqInt(json, 'rides'),
        isMe: reqBool(json, 'is_me'),
      );

  final int rank;
  final String displayName;
  final String? avatarUrl;
  final int currentStreak;
  final int rides;

  /// The signed-in student's own row (always included, even below the limit).
  final bool isMe;

  @override
  List<Object?> get props => [rank, displayName, avatarUrl, currentStreak, rides, isMe];
}
