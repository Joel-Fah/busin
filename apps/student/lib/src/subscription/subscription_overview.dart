import 'package:busin_core/busin_core.dart';

/// Where a student stands for the semester that matters now.
class SubscriptionOverview {
  const SubscriptionOverview({this.semester, this.upcoming = false, this.subscription, this.stop, this.savedAt});

  /// No semester is open or coming.
  const SubscriptionOverview.none() : this();

  /// Reads what [toJson] wrote (the phone's saved copy, used when the server cannot be reached). [savedAt] says when it was saved.
  factory SubscriptionOverview.fromJson(Map<String, dynamic> json, {required DateTime savedAt}) {
    final semester = json['semester'];
    final subscription = json['subscription'];
    final stop = json['stop'];
    return SubscriptionOverview(
      semester: semester is Map<String, dynamic> ? Semester.fromJson(semester) : null,
      upcoming: json['upcoming'] == true,
      subscription: subscription is Map<String, dynamic> ? Subscription.fromJson(subscription) : null,
      stop: stop is Map<String, dynamic> ? Stop.fromJson(stop) : null,
      savedAt: savedAt,
    );
  }

  /// The current semester, or the next one when none is running.
  final Semester? semester;

  /// True when [semester] has not started yet.
  final bool upcoming;

  /// The student's pending or approved request, or else the latest one that ended in rejection or expiry.
  final Subscription? subscription;

  /// The stop of [subscription].
  final Stop? stop;

  /// Set when this is the copy saved on the phone because the server could not be reached; null when it was just read.
  final DateTime? savedAt;

  bool get fromSavedCopy => savedAt != null;

  /// Whether the pass may be shown as a working pass. A fresh answer from the server is taken as it is. A saved copy is
  /// trusted only while its semester is running at the school (school-local [today]): after it ends, or before it has begun,
  /// the app must reconnect and ask again.
  bool passUsable(DateTime today) {
    if (subscription?.status != SubscriptionStatus.approved) return false;
    if (!fromSavedCopy) return true;
    final semester = this.semester;
    return semester != null && semester.includes(today);
  }

  Map<String, dynamic> toJson() => {
        'semester': semester?.toJson(),
        'upcoming': upcoming,
        'subscription': subscription?.toJson(),
        'stop': stop?.toJson(),
      };
}
