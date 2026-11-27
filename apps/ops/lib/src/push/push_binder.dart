import 'dart:async';

import 'package:busin_app/busin_app.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../nav/tab_badges.dart';
import '../providers.dart';
import '../router.dart';
import '../trips/trip_providers.dart';
import 'trip_reminders.dart';

/// Where a tapped notification takes a staff member: a trip they were put on opens that trip. Null for a kind this
/// version does not know.
String? opsRouteForPush(PushMessage message) => switch (message.kind) {
      'crew_assigned' || tripReminderKind || tripAtCampusKind => message.refId == null ? Routes.today : Routes.trip(message.refId!),
      _ => null,
    };

/// Remembered once asked, so the system question comes up a single time on this phone.
const pushAskedKey = 'ops.push.asked';

/// Keeps notifications connected while a staff member is signed in: asks once whether this phone may show them (the
/// app is a work tool, and being put on a trip is worth knowing), registers the token, follows a replaced token, opens
/// the trip from a tapped notification (also when it launched the app), and while the app is open says so in a toast
/// and refreshes the trips. Built only inside the signed-in tabs.
class OpsPushBinder extends ConsumerStatefulWidget {
  const OpsPushBinder({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OpsPushBinder> createState() => _OpsPushBinderState();
}

class _OpsPushBinderState extends ConsumerState<OpsPushBinder> {
  final _subscriptions = <StreamSubscription<Object?>>[];

  @override
  void initState() {
    super.initState();
    final push = ref.read(pushServiceProvider);
    if (!push.available) return;
    // Trip reminders and their End trip button (also when a reminder opened the app).
    final reminders = ref.read(tripReminderNotificationsProvider);
    unawaited(() async {
      try {
        await reminders.init(_chose);
        final launch = await reminders.launchChoice();
        if (launch != null) _chose(launch);
      } catch (_) {
        // A notification is a convenience: nothing here may get in the way of the app.
      }
    }());
    final registrar = ref.read(pushRegistrarProvider);
    unawaited(_connect(push, registrar));
    _subscriptions
      ..add(push.tokenRefreshes.listen(registrar.tokenChanged))
      ..add(push.taps.listen(_open))
      ..add(push.foreground.listen(_arrived));
    push.launchedBy().then((message) {
      if (message != null && mounted) _open(message);
    });
  }

  Future<void> _connect(PushService push, PushRegistrar registrar) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final asked = prefs.getBool(pushAskedKey) ?? false;
      if (!asked && await push.permission() == PushPermission.notAsked) {
        await prefs.setBool(pushAskedKey, true);
        await registrar.enable();
        return;
      }
      await registrar.syncIfAllowed();
    } catch (_) {
      // A notification is a convenience: nothing here may get in the way of the app.
    }
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }

  void _open(PushMessage message) {
    if (!mounted) return;
    ref.invalidate(todayTripsProvider);
    final route = opsRouteForPush(message);
    if (route != null) ref.read(routerProvider).push(route);
  }

  /// A reminder tapped: End trip ends it, signed in as the person, and says how it went; the notification itself opens
  /// the trip.
  Future<void> _chose(ReminderChoice choice) async {
    if (!mounted) return;
    if (!choice.end) {
      ref.read(routerProvider).push(Routes.trip(choice.tripId));
      return;
    }
    final l10n = BusinL10n.of(context);
    try {
      await ref.read(tripsRepositoryProvider).end(choice.tripId);
      ref.invalidate(todayTripsProvider);
      if (mounted) BusinToast.show(context, l10n.opsTripEndedFromReminder, tone: ToastTone.success);
    } catch (_) {
      if (!mounted) return;
      BusinToast.show(context, l10n.opsTripEndFromReminderFailed, tone: ToastTone.error);
      ref.read(routerProvider).push(Routes.trip(choice.tripId));
    }
  }

  void _arrived(PushMessage message) {
    if (!mounted) return;
    // A reminder while the app is open: drawn here, in the app's language, with its button.
    if (tripEndingKinds.contains(message.kind) && message.refId != null) {
      final l10n = BusinL10n.of(context);
      final campus = message.kind == tripAtCampusKind;
      unawaited(ref
          .read(tripReminderNotificationsProvider)
          .show(
            tripId: message.refId!,
            title: campus ? l10n.opsTripAtCampusTitle : l10n.opsTripReminderTitle,
            body: campus ? l10n.opsTripAtCampusBody : l10n.opsTripReminderBody,
            action: l10n.opsTripReminderAction,
          )
          .catchError((Object _) {}));
      return;
    }
    if (message.kind != 'crew_assigned') return;
    ref.invalidate(todayTripsProvider);
    ref.read(tabBadgesProvider.notifier).mark(const [OpsTabs.trips]);
    BusinToast.show(context, BusinL10n.of(context).opsPushCrewAssigned, tone: ToastTone.info);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
