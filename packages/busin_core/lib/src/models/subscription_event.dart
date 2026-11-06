import '../enums.dart';
import '../json.dart';
import '../value_object.dart';

/// One thing that happened to a subscription: it was requested, approved, declined, ended or given back. The database
/// writes these itself; a student reads their own.
class SubscriptionEvent extends ValueObject {
  const SubscriptionEvent({required this.id, required this.subscriptionId, required this.action, required this.createdAt, this.note});

  factory SubscriptionEvent.fromJson(Map<String, dynamic> json) => SubscriptionEvent(
        id: reqInt(json, 'id'),
        subscriptionId: reqString(json, 'subscription_id'),
        action: SubscriptionEventAction.parse(json['action']),
        note: optString(json, 'note'),
        createdAt: reqTimestamp(json, 'created_at'),
      );

  final int id;
  final String subscriptionId;
  final SubscriptionEventAction action;

  /// The school's reason, where there is one (a decline, an ending, a reinstatement note).
  final String? note;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, subscriptionId, action, note, createdAt];
}
