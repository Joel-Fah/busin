import '../json.dart';
import '../value_object.dart';

/// A scheduled deletion of the person's own account (ADR 0028): when it happens, and whether BusIn scheduled it for
/// them (someone who lost access asked from the public page). The person can cancel until [dueAt].
class ScheduledDeletion extends ValueObject {
  const ScheduledDeletion({required this.dueAt, required this.byPlatform});

  factory ScheduledDeletion.fromJson(Map<String, dynamic> json) => ScheduledDeletion(
        dueAt: reqTimestamp(json, 'due_at'),
        byPlatform: optString(json, 'requested_by') == 'platform',
      );

  final DateTime dueAt;
  final bool byPlatform;

  @override
  List<Object?> get props => [dueAt, byPlatform];
}
