import 'package:busin_app/busin_app.dart';
import 'dart:async';

import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers.dart';
import '../subscription/live_changes.dart';
import '../subscription/installments_section.dart';
import '../subscription/request_history.dart';
import '../subscription/subscription_providers.dart';
import 'push_routes.dart';

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
    // A part of a subscription paid in installments: said as it comes, and the parts are read again.
    final part = switch (message.kind) {
      'installment_paid' => l10n.pushForegroundInstallmentPaid,
      'installment_rejected' => l10n.pushForegroundInstallmentRejected,
      'installment_due' => l10n.pushForegroundInstallmentDue,
      _ => null,
    };
    if (part != null) {
      final id = message.refId;
      if (id != null) ref.invalidate(installmentsProvider(id));
      ref.invalidate(requestHistoryProvider);
      _show(part, message);
      return;
    }
    final text = switch (message.kind) {
      'subscription_approved' => l10n.pushForegroundApproved,
      'subscription_rejected' => l10n.pushForegroundRejected,
      'subscription_revoked' => l10n.liveRevoked,
      'subscription_restored' => l10n.liveReinstated,
      _ => null,
    };
    if (text == null) return;
    // The live feed may have said it already (both arrive together while the app is open).
    // A restored subscription is what the live feed calls a reinstatement: the same key, so it is said once.
    final status = message.kind == 'subscription_restored' ? 'reinstated' : message.kind.substring('subscription_'.length);
    final id = message.refId;
    final announced = ref.read(announcedChangesProvider.notifier);
    // An older server sends a reinstatement as an approval: the live feed may have claimed it under its own name.
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
