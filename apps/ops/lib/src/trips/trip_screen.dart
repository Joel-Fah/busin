import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../providers.dart';
import '../router.dart';
import '../drive/driver_mode.dart';
import '../drive/position_publisher.dart';
import '../queue/scan_queue.dart';
import '../scan/scan_providers.dart';
import 'trip_providers.dart';

/// One trip: where it stands, how full the bus is, and Start or End for whoever may run it.
class TripScreen extends ConsumerStatefulWidget {
  const TripScreen({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends ConsumerState<TripScreen> {
  bool _busy = false;

  void _reload() {
    ref.invalidate(tripProvider(widget.tripId));
    ref.invalidate(manifestProvider(widget.tripId));
    ref.invalidate(todayTripsProvider);
  }

  Future<void> _start(Trip trip) async {
    final l10n = BusinL10n.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(tripsRepositoryProvider).start(trip.id);
      if (!mounted) return;
      BusinHaptics.medium();
      BusinToast.show(context, l10n.opsStarted, tone: ToastTone.success);
      _reload();
      // Whoever shares this trip's position is offered to start sharing right away.
      final me = staffOf(ref.read(accessProvider));
      final running = await ref.read(tripProvider(trip.id).future);
      if (mounted && me != null && running.sharesPosition(me.userId, isAdmin: false)) await _share(true);
    } on NotAllowed {
      if (mounted) BusinToast.show(context, l10n.opsAssignedElsewhere, tone: ToastTone.warning);
    } on Conflict {
      if (!mounted) return;
      final school = ref.read(schoolProvider).value;
      final clock = ref.read(schoolClockProvider);
      final zone = school?.timezone ?? 'UTC';
      final now = ref.read(nowProvider)();
      final isToday = clock.today(zone, now: trip.scheduledStart) == clock.today(zone, now: now);
      final today = ref.read(todayTripsProvider).value ?? const <Trip>[];
      final text = switch (startRefusal(trip: trip, today: today, isToday: isToday)) {
        StartRefusal.notToday => l10n.opsNotToday,
        StartRefusal.busBusy => l10n.opsBusBusy,
        StartRefusal.notScheduled => l10n.opsNotScheduled,
      };
      BusinToast.show(context, text, tone: ToastTone.warning);
      _reload();
    } catch (_) {
      if (mounted) BusinToast.show(context, l10n.errorGeneric, tone: ToastTone.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Turns sharing on (after explaining it) or off.
  Future<void> _share(bool on) async {
    final l10n = BusinL10n.of(context);
    final mode = ref.read(driverModeProvider(widget.tripId).notifier);
    if (!on) {
      mode.stop();
      return;
    }
    final go = await showBusinSheet<bool>(context, builder: (context) => const _ShareWhy());
    if (go != true || !mounted) return;
    final started = await mode.start(title: l10n.opsShareNotificationTitle, text: l10n.opsShareNotificationText);
    if (!started && mounted) BusinToast.show(context, l10n.opsShareDenied, tone: ToastTone.warning);
  }

  Future<void> _end(Trip trip) async {
    final l10n = BusinL10n.of(context);
    final sure = await showBusinSheet<bool>(context, builder: (context) => const _EndSheet());
    if (sure != true || !mounted) return;
    setState(() => _busy = true);
    ref.read(driverModeProvider(trip.id).notifier).stop();
    try {
      await ref.read(tripsRepositoryProvider).end(trip.id);
      if (!mounted) return;
      BusinToast.show(context, l10n.opsEnded, tone: ToastTone.success);
      _reload();
      context.canPop() ? context.pop() : context.go(Routes.today);
    } on NotAllowed {
      if (mounted) BusinToast.show(context, l10n.opsAssignedElsewhere, tone: ToastTone.warning);
    } catch (_) {
      if (mounted) BusinToast.show(context, l10n.errorGeneric, tone: ToastTone.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final me = staffOf(ref.watch(accessProvider));
    final trip = ref.watch(tripProvider(widget.tripId));
    final bus = ref.watch(tripBusProvider(widget.tripId)).value;
    final zone = ref.watch(schoolProvider).value?.timezone ?? 'UTC';

    return Scaffold(
      appBar: AppBar(
        title: Text(bus?.label ?? l10n.opsTripTitle),
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go(Routes.today)),
      ),
      body: SafeArea(
        child: ContentColumn(
          child: trip.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => EmptyState(
              illustration: BusinIllustration.waiting,
              title: l10n.errorGeneric,
              action: BusinButton(label: l10n.actionRetry, onPressed: _reload),
            ),
            data: (trip) {
              final canRun = me != null && trip.canRun(me.userId, isAdmin: me.isAdmin);
              final manifest = ref.watch(manifestProvider(trip.id)).value;
              final mine = ref.watch(tripScansProvider(trip.id)).value ?? const <QueuedScan>[];
              // On board: what the server has, plus what this phone let on and has not sent yet.
              final boarded = manifest == null
                  ? null
                  : {for (final m in manifest) m.studentId, for (final s in mine) if (s.state != QueuedState.refused) s.studentId}.length;
              final refusedLater = [for (final s in mine) if (s.state == QueuedState.refused) s];
              final roster = ref.watch(rosterProvider).value;
              final time = const SchoolClock().wallClock(zone, trip.scheduledStart);
              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(BusinSpace.x5),
                  children: [
                    BusinCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(l10n.direction(trip.direction), style: text.titleLarge)),
                              StatusChip(label: l10n.tripStatus(trip.status), tone: tripTone(trip.status)),
                            ],
                          ),
                          const SizedBox(height: BusinSpace.x2),
                          Text(
                            l10n.opsDeparts(MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(time))),
                            style: text.bodyMedium?.copyWith(color: p.muted),
                          ),
                          if (boarded != null && bus != null && trip.status != TripStatus.scheduled) ...[
                            const SizedBox(height: BusinSpace.x3),
                            Row(
                              children: [
                                HugeIcon(icon: HugeIcons.strokeRoundedUserGroup, size: 20, color: p.fg),
                                const SizedBox(width: BusinSpace.x2),
                                Text(l10n.opsBoarded(boarded, bus.capacity), style: text.titleMedium),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: BusinSpace.x4),
                    if (trip.status == TripStatus.scheduled) ...[
                      Text(l10n.opsScannerSoon, style: text.bodyMedium?.copyWith(color: p.muted)),
                      const SizedBox(height: BusinSpace.x4),
                      if (canRun)
                        BusinButton(
                          label: l10n.opsStart,
                          icon: HugeIcons.strokeRoundedPlayCircle,
                          expand: true,
                          loading: _busy,
                          onPressed: _busy ? null : () => _start(trip),
                        )
                      else
                        Notice(child: Text(l10n.opsAssignedElsewhere)),
                    ],
                    if (trip.status == TripStatus.active) ...[
                      BusinButton(
                        label: l10n.opsScan,
                        icon: HugeIcons.strokeRoundedQrCode,
                        expand: true,
                        onPressed: () => context.push(Routes.scan(trip.id)),
                      ),
                      const SizedBox(height: BusinSpace.x3),
                    ],
                    if (trip.status == TripStatus.active && me != null) ...[
                      _ShareCard(
                        tripId: trip.id,
                        mine: trip.sharesPosition(me.userId, isAdmin: false),
                        zone: zone,
                        onChanged: _share,
                      ),
                      const SizedBox(height: BusinSpace.x3),
                    ],
                    if (refusedLater.isNotEmpty) ...[
                      Notice(
                        tone: StatusTone.bad,
                        title: l10n.opsRefusedLaterTitle,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.opsRefusedLaterBody),
                            const SizedBox(height: BusinSpace.x2),
                            for (final s in refusedLater)
                              Text('${roster?.rider(s.studentId)?.fullName ?? s.studentId.substring(0, 8)} · ${_reasonText(l10n, s.reason)}',
                                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(height: BusinSpace.x3),
                    ],
                    if (trip.status == TripStatus.active && canRun)
                      BusinButton(
                        label: l10n.opsEnd,
                        icon: HugeIcons.strokeRoundedStopCircle,
                        variant: BusinButtonVariant.danger,
                        expand: true,
                        loading: _busy,
                        onPressed: _busy ? null : () => _end(trip),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Sharing the bus position: a switch for whoever shares this trip, a line for everyone else.
class _ShareCard extends ConsumerWidget {
  const _ShareCard({required this.tripId, required this.mine, required this.zone, required this.onChanged});

  final String tripId;
  final bool mine;
  final String zone;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final drive = ref.watch(driverModeProvider(tripId));
    final last = drive.lastSentAt;
    final status = switch (drive.status) {
      ShareStatus.stopped => l10n.opsShareOff,
      ShareStatus.waiting => l10n.opsShareWaiting,
      ShareStatus.sharing when last == null => l10n.opsShareStarting,
      ShareStatus.sharing => l10n.opsShareLast(
          MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(const SchoolClock().wallClock(zone, last!))),
        ),
    };
    return BusinCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(icon: HugeIcons.strokeRoundedGps01, size: 22, color: drive.status == ShareStatus.stopped ? p.muted : p.ok),
              const SizedBox(width: BusinSpace.x3),
              Expanded(child: Text(l10n.opsShareTitle, style: text.titleMedium)),
              if (mine) Switch.adaptive(value: drive.status != ShareStatus.stopped, onChanged: onChanged),
            ],
          ),
          const SizedBox(height: BusinSpace.x2),
          Text(mine ? status : l10n.opsShareNotYours, style: text.bodySmall?.copyWith(color: p.muted)),
          if (mine && drive.status == ShareStatus.stopped) Text(l10n.opsShareBody, style: text.bodySmall?.copyWith(color: p.muted)),
        ],
      ),
    );
  }
}

class _ShareWhy extends StatelessWidget {
  const _ShareWhy();

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.all(BusinSheetFrame.contentInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.opsShareWhyTitle, style: text.titleLarge),
          const SizedBox(height: BusinSpace.x2),
          Text(l10n.opsShareWhyBody, style: text.bodyMedium?.copyWith(color: p.muted)),
          const SizedBox(height: BusinSpace.x4),
          BusinButton(label: l10n.opsLocationContinue, expand: true, onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );
  }
}

String _reasonText(BusinL10n l10n, String? reason) => switch (reason) {
      'account_not_verified' => l10n.opsResultNotVerified,
      'no_active_subscription' => l10n.opsResultNoSubscription,
      'student_not_found' => l10n.opsResultUnknown,
      'expired_code' => l10n.opsResultExpired,
      'invalid_code' => l10n.opsResultInvalid,
      _ => l10n.errorGeneric,
    };

class _EndSheet extends StatelessWidget {
  const _EndSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.all(BusinSheetFrame.contentInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.opsEndTitle, style: text.titleLarge),
          const SizedBox(height: BusinSpace.x2),
          Text(l10n.opsEndBody, style: text.bodyMedium?.copyWith(color: p.muted)),
          const SizedBox(height: BusinSpace.x4),
          BusinButton(label: l10n.opsEnd, variant: BusinButtonVariant.danger, expand: true, onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );
  }
}
