import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import 'bus_updates.dart';

/// The words for an update. [busLabel] and [direction] name the bus; [now] counts the minutes of "not moving" and
/// "no news".
String busUpdateText(BusinL10n l10n, BusUpdate update, {required String busLabel, required String direction, required DateTime now}) {
  String minutesSince(DateTime? since) => '${since == null ? 0 : now.difference(since).inMinutes.clamp(0, 999)}';
  return switch (update.kind) {
    BusUpdateKind.following => l10n.busUpdateFollowing(busLabel, direction),
    BusUpdateKind.atStop => l10n.busUpdateAtStop(update.stopName ?? ''),
    BusUpdateKind.leftStop => l10n.busUpdateLeftStop(update.stopName ?? ''),
    BusUpdateKind.stopped => l10n.busUpdateStopped(minutesSince(update.since)),
    BusUpdateKind.moving => l10n.busUpdateMoving,
    BusUpdateKind.nearMyStop => l10n.busUpdateNearMyStop('${update.minutes ?? 1}'),
    BusUpdateKind.passedMyStop => l10n.busUpdatePassedMyStop,
    BusUpdateKind.signalLost => l10n.busUpdateSignalLost(minutesSince(update.since)),
    BusUpdateKind.signalBack => l10n.busUpdateSignalBack,
    BusUpdateKind.tripEnded => l10n.busUpdateEnded(busLabel),
  };
}

/// The tone and icon of each kind: what needs the student's attention is warm, the rest is calm. Never colour alone.
(StatusTone, List<List<dynamic>>) busUpdateLook(BusUpdateKind kind) => switch (kind) {
      BusUpdateKind.following => (StatusTone.info, HugeIcons.strokeRoundedBus01),
      BusUpdateKind.atStop => (StatusTone.info, HugeIcons.strokeRoundedFlag02),
      BusUpdateKind.leftStop => (StatusTone.info, HugeIcons.strokeRoundedArrowRight02),
      BusUpdateKind.stopped => (StatusTone.warn, HugeIcons.strokeRoundedPauseCircle),
      BusUpdateKind.moving => (StatusTone.ok, HugeIcons.strokeRoundedPlayCircle),
      BusUpdateKind.nearMyStop => (StatusTone.ok, HugeIcons.strokeRoundedLocation01),
      BusUpdateKind.passedMyStop => (StatusTone.warn, HugeIcons.strokeRoundedAlert02),
      BusUpdateKind.signalLost => (StatusTone.warn, HugeIcons.strokeRoundedWifiDisconnected01),
      BusUpdateKind.signalBack => (StatusTone.ok, HugeIcons.strokeRoundedWifi01),
      BusUpdateKind.tripEnded => (StatusTone.neutral, HugeIcons.strokeRoundedCheckmarkCircle02),
    };

/// One short update over the map. A newer update slides in over the old one; the student can hide it until the next.
/// Announced to screen readers; a light tap of the phone when the bus is near or past the student's stop.
class BusUpdateStrip extends StatefulWidget {
  const BusUpdateStrip({super.key, required this.update, required this.busLabel, required this.direction, required this.now});

  final BusUpdate? update;
  final String busLabel;
  final String direction;
  final DateTime now;

  @override
  State<BusUpdateStrip> createState() => _BusUpdateStripState();
}

class _BusUpdateStripState extends State<BusUpdateStrip> {
  Object? _hidden;

  Object? _keyOf(BusUpdate? u) => u == null ? null : (u.kind, u.seq, u.at);

  @override
  void didUpdateWidget(BusUpdateStrip old) {
    super.didUpdateWidget(old);
    final u = widget.update;
    if (u != null && _keyOf(u) != _keyOf(old.update) && (u.kind == BusUpdateKind.nearMyStop || u.kind == BusUpdateKind.passedMyStop)) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final u = widget.update;
    final key = _keyOf(u);
    final show = u != null && key != _hidden;
    return AnimatedSwitcher(
      duration: BusinMotion.of(context, BusinMotion.fast),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(position: Tween(begin: const Offset(0, -0.25), end: Offset.zero).animate(animation), child: child),
      ),
      child: !show
          ? const SizedBox.shrink(key: ValueKey('none'))
          : Semantics(
              key: ValueKey(key),
              liveRegion: true,
              child: Notice(
                tone: busUpdateLook(u.kind).$1,
                icon: busUpdateLook(u.kind).$2,
                child: Row(
                  children: [
                    Expanded(child: Text(busUpdateText(l10n, u, busLabel: widget.busLabel, direction: widget.direction, now: widget.now))),
                    IconButton(
                      tooltip: l10n.busUpdateDismiss,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _hidden = key),
                      icon: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 18, color: DefaultTextStyle.of(context).style.color),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// On a wide screen, beside the map: the newest update stands out and the few before it follow, each with its time.
/// Only what happened while the tab was open; nothing is stored.
class BusUpdateFeed extends StatelessWidget {
  const BusUpdateFeed({super.key, required this.updates, required this.busLabel, required this.direction, required this.now});

  /// Newest first.
  final List<BusUpdate> updates;
  final String busLabel;
  final String direction;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final shown = updates.take(5).toList();
    String words(BusUpdate u) => busUpdateText(
          l10n,
          u,
          busLabel: u.kind == BusUpdateKind.tripEnded ? (u.stopName ?? '') : busLabel,
          direction: direction,
          now: now,
        );
    String time(BusUpdate u) => MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(u.at.toLocal()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.busUpdatesTitle, style: text.titleMedium),
        const SizedBox(height: BusinSpace.x2),
        if (shown.isEmpty)
          Text(l10n.busUpdatesEmpty, style: text.bodySmall?.copyWith(color: p.muted))
        else ...[
          AnimatedSwitcher(
            duration: BusinMotion.of(context, BusinMotion.fast),
            child: Semantics(
              key: ValueKey((shown.first.kind, shown.first.seq, shown.first.at)),
              liveRegion: true,
              child: Notice(
                tone: busUpdateLook(shown.first.kind).$1,
                icon: busUpdateLook(shown.first.kind).$2,
                child: Row(
                  children: [
                    Expanded(child: Text(words(shown.first))),
                    const SizedBox(width: BusinSpace.x2),
                    Text(time(shown.first), style: text.bodySmall),
                  ],
                ),
              ),
            ),
          ),
          for (final u in shown.skip(1))
            Padding(
              padding: const EdgeInsets.fromLTRB(BusinSpace.x4, BusinSpace.x3, BusinSpace.x4, 0),
              child: Row(
                children: [
                  HugeIcon(icon: busUpdateLook(u.kind).$2, size: 18, color: p.muted),
                  const SizedBox(width: BusinSpace.x3),
                  Expanded(child: Text(words(u), style: text.bodySmall?.copyWith(color: p.muted))),
                  Text(time(u), style: text.bodySmall?.copyWith(color: p.muted)),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
