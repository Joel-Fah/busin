import 'package:busin_core/busin_core.dart';

import 'billing_choices.dart';

/// Where a student stands for the semester that matters now.
class SubscriptionOverview {
  const SubscriptionOverview({this.semester, this.upcoming = false, this.subscription, this.stop, this.savedAt, this.live = const []});

  /// No semester is open or coming.
  const SubscriptionOverview.none() : this();

  /// Reads what [toJson] wrote (the phone's saved copy, used when the server cannot be reached). [savedAt] says when it was saved.
  factory SubscriptionOverview.fromJson(Map<String, dynamic> json, {required DateTime savedAt}) {
    final semester = json['semester'];
    final subscription = json['subscription'];
    final stop = json['stop'];
    final live = json['live'];
    return SubscriptionOverview(
      semester: semester is Map<String, dynamic> ? Semester.fromJson(semester) : null,
      upcoming: json['upcoming'] == true,
      subscription: subscription is Map<String, dynamic> ? Subscription.fromJson(subscription) : null,
      stop: stop is Map<String, dynamic> ? Stop.fromJson(stop) : null,
      savedAt: savedAt,
      live: live is List ? [for (final s in live.whereType<Map<String, dynamic>>()) Subscription.fromJson(s)] : const [],
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

  /// Every pending or approved request of the semester that has not ended, [subscription] among them. With monthly
  /// billing it can hold this month and the next (ADR 0022).
  final List<Subscription> live;

  /// A live request for a later month than [subscription], if any.
  Subscription? get next {
    final shown = subscription;
    for (final s in live) {
      if (s.id != shown?.id && s.periodStart != null && (shown?.periodStart == null || s.periodStart!.isAfter(shown!.periodStart!))) return s;
    }
    return null;
  }

  /// Set when this is the copy saved on the phone because the server could not be reached; null when it was just read.
  final DateTime? savedAt;

  bool get fromSavedCopy => savedAt != null;

  /// Whether the pass may be shown as a working pass. A fresh answer from the server is taken as it is. A saved copy is
  /// trusted only while its semester is running at the school (school-local [today]): after it ends, or before it has begun,
  /// the app must reconnect and ask again.
  bool passUsable(DateTime today) {
    if (subscription?.status != SubscriptionStatus.approved) return false;
    // A monthly subscription stops at the end of its month, saved copy or not.
    final end = subscription!.periodEnd;
    if (end != null && calendarDay(today).isAfter(end)) return false;
    if (!fromSavedCopy) return true;
    final semester = this.semester;
    return semester != null && semester.includes(today);
  }

  Map<String, dynamic> toJson() => {
        'semester': semester?.toJson(),
        'upcoming': upcoming,
        'subscription': subscription?.toJson(),
        'stop': stop?.toJson(),
        'live': [for (final s in live) s.toJson()],
      };
}
