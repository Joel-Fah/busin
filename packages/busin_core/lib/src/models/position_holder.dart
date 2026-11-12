import '../json.dart';
import '../value_object.dart';

/// Whose phone leads the position of a running trip right now (ADR 0019). When a driver and an assistant both share,
/// the server keeps the fixes of one phone and sets the other's aside, until the leader has been quiet for 30 seconds.
class PositionHolder extends ValueObject {
  const PositionHolder({required this.holderId, required this.name, required this.isMe, required this.secondsAgo});

  /// One row of `trip_position_holder`.
  factory PositionHolder.fromJson(Map<String, dynamic> json) => PositionHolder(
        holderId: reqString(json, 'holder_id'),
        name: optString(json, 'holder_name') ?? '',
        isMe: json['is_me'] == true,
        secondsAgo: (json['seconds_ago'] as num?)?.toInt() ?? 0,
      );

  final String holderId;
  final String name;

  /// This phone's owner is the one leading.
  final bool isMe;

  /// Seconds since the leader's last kept fix.
  final int secondsAgo;

  @override
  List<Object?> get props => [holderId, name, isMe, secondsAgo];
}
