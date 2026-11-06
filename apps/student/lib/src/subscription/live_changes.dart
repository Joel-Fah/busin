import 'dart:async';

import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bus/bus_providers.dart';
import '../providers.dart';
import '../qr/qr_providers.dart';
import 'subscription_providers.dart';

/// A subscription whose status is not what it was.
class StatusChange {
  const StatusChange({required this.id, required this.status, this.from});

  final String id;
  final SubscriptionStatus status;

  /// What it was before, if it was known (an approval after an ending is a reinstatement).
  final SubscriptionStatus? from;

  bool get isReinstatement => from == SubscriptionStatus.revoked && status == SubscriptionStatus.approved;
}

/// What changed between what was known and what has just arrived: a subscription with a different status, or one that
/// was not there before. [known] is updated to the new state. The first arrival (nothing known yet) only fills [known].
List<StatusChange> changesSince(Map<String, SubscriptionStatus> known, List<Subscription> now, {required bool first}) {
  final changes = <StatusChange>[];
  for (final s in now) {
    if (!first && known[s.id] != s.status) changes.add(StatusChange(id: s.id, status: s.status, from: known[s.id]));
    known[s.id] = s.status;
  }
  return changes;
}

/// Which changes the person has already been told about, so a push and the live feed arriving together say it once.
class AnnouncedChanges extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  /// True the first time [key] is claimed.
  bool claim(String key) {
    if (state.contains(key)) return false;
    state = {...state, key};
    return true;
  }
}

final announcedChangesProvider = NotifierProvider<AnnouncedChanges, Set<String>>(AnnouncedChanges.new);

/// The key the live feed and a push share for "this subscription became this".
String changeKey(String id, String status) => '$id:$status';

/// Follows the student's own subscription while the app is open. When a status changes (the school approved, rejected
/// or ended it) everything that depends on it is read again, and a short toast says so. Push covers the app being closed;
/// this is the cheap, immediate path while it is open (one row filter, nothing when nobody is signed in).
class SubscriptionLiveBinder extends ConsumerStatefulWidget {
  const SubscriptionLiveBinder({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SubscriptionLiveBinder> createState() => _SubscriptionLiveBinderState();
}

class _SubscriptionLiveBinderState extends ConsumerState<SubscriptionLiveBinder> {
  StreamSubscription<List<Subscription>>? _feed;
  final _known = <String, SubscriptionStatus>{};
  bool _first = true;

  @override
  void initState() {
    super.initState();
    final userId = ref.read(authUserIdProvider).value;
    if (userId == null) return;
    _feed = ref.read(subscriptionsRepositoryProvider).watchForStudent(userId).listen(_arrived, onError: (Object _) {
      // The feed is a convenience: if it drops, the screens still refresh when they are opened.
    });
  }

  @override
  void dispose() {
    _feed?.cancel();
    super.dispose();
  }

  void _arrived(List<Subscription> rows) {
    final changes = changesSince(_known, rows, first: _first);
    _first = false;
    if (changes.isEmpty || !mounted) return;

    // Everything that depends on the subscription reads it again.
    ref.invalidate(subscriptionOverviewProvider);
    ref.invalidate(qrSecretProvider);
    ref.invalidate(canFollowBusesProvider);

    final l10n = BusinL10n.of(context);
    for (final change in changes) {
      final (String? text, ToastTone tone) = switch (change.status) {
        SubscriptionStatus.approved => (change.isReinstatement ? l10n.liveReinstated : l10n.pushForegroundApproved, ToastTone.success),
        SubscriptionStatus.rejected => (l10n.pushForegroundRejected, ToastTone.warning),
        SubscriptionStatus.revoked => (l10n.liveRevoked, ToastTone.warning),
        _ => (null, ToastTone.info),
      };
      if (text == null) continue;
      if (!ref.read(announcedChangesProvider.notifier).claim(changeKey(change.id, change.isReinstatement ? 'reinstated' : change.status.name))) continue;
      BusinToast.show(context, text, tone: tone);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
