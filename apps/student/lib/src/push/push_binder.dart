import 'dart:async';

import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers.dart';
import '../subscription/live_changes.dart';
import '../subscription/subscription_providers.dart';
import 'push_registrar.dart';
import 'push_service.dart';

/// Wraps the signed-in app and keeps notifications connected to it: registers the token if the person already allowed
/// them, follows a replaced token, opens the right tab when a notification is tapped (also when it launched the app),
/// and, when one arrives while the app is open, refreshes the subscription and says so in a small banner.
/// It exists only for an allowed student, because the signed-in frame is the only place it is built.
class PushBinder extends ConsumerStatefulWidget {
  const PushBinder({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushBinder> createState() => _PushBinderState();
}

class _PushBinderState extends ConsumerState<PushBinder> {
  final _subscriptions = <StreamSubscription<Object?>>[];

  @override
  void initState() {
    super.initState();
    final push = ref.read(pushServiceProvider);
    final registrar = ref.read(pushRegistrarProvider);

    registrar.syncIfAllowed();
    _subscriptions
      ..add(push.tokenRefreshes.listen(registrar.tokenChanged))
      ..add(push.taps.listen(_open))
      ..add(push.foreground.listen(_arrived));
    push.launchedBy().then((message) {
      if (message != null && mounted) _open(message);
    });
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
    ref.invalidate(subscriptionOverviewProvider);
    final route = routeForPush(message);
    if (route != null) context.go(route);
  }

  void _arrived(PushMessage message) {
    if (!mounted) return;
    final l10n = BusinL10n.of(context);
    if (message.kind == 'bus_near_stop') {
      _show(l10n.pushForegroundBusNear, message);
      return;
    }
    ref.invalidate(subscriptionOverviewProvider);
    final text = switch (message.kind) {
      'subscription_approved' => l10n.pushForegroundApproved,
      'subscription_rejected' => l10n.pushForegroundRejected,
      _ => null,
    };
    if (text == null) return;
    // The live feed may have said it already (both arrive together while the app is open).
    final status = message.kind == 'subscription_approved' ? 'approved' : 'rejected';
    final id = message.refId;
    // A reinstatement arrives as an approval: the live feed may have claimed it under its own name.
    final announced = ref.read(announcedChangesProvider.notifier);
    if (id != null && status == 'approved' && ref.read(announcedChangesProvider).contains(changeKey(id, 'reinstated'))) return;
    if (id != null && !announced.claim(changeKey(id, status))) return;
    _show(text, message);
  }

  void _show(String text, PushMessage message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), action: SnackBarAction(label: BusinL10n.of(context).pushForegroundView, onPressed: () => _open(message))),
      );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
