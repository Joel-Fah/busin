import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../providers.dart';
import '../router.dart';
import '../trips/my_trips_providers.dart';

/// My past trips, newest first, grouped by week: which bus, when, my part, whether it left on time, how many boarded and
/// how long it ran. More load as the list reaches its end.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final history = ref.watch(tripHistoryProvider);
    final zone = ref.watch(schoolProvider).value?.timezone ?? 'UTC';
    final thisMonday = ref.watch(thisMondayProvider);
    final bottom = BusinScope.of(context).bottomInset;

    Future<void> refresh() async {
      ref.invalidate(tripHistoryProvider);
      await ref.read(tripHistoryProvider.future).catchError((Object _) => const TripHistory());
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.opsHistoryTitle)),
      body: SafeArea(
        bottom: false,
        child: ContentColumn(
          child: RefreshIndicator(
            onRefresh: refresh,
            child: history.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => ListView(
                children: [
                  EmptyState(illustration: BusinIllustration.waiting, title: l10n.errorGeneric, action: BusinButton(label: l10n.actionRetry, onPressed: refresh)),
                ],
              ),
              data: (state) {
                if (state.items.isEmpty) {
                  return ListView(children: [EmptyState(illustration: BusinIllustration.busStop, title: l10n.opsHistoryEmpty)]);
                }
                final weeks = groupByWeek(state.items, (TripHistoryEntry e) => e.scheduledStart, zone: zone);
                return NotificationListener<ScrollNotification>(
                  // Near the end: the next page.
                  onNotification: (n) {
                    if (n.metrics.extentAfter < 400) ref.read(tripHistoryProvider.notifier).loadMore();
                    return false;
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(BusinSpace.x5, BusinSpace.x2, BusinSpace.x5, BusinSpace.x6 + bottom),
                    children: [
                      for (final week in weeks) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: BusinSpace.x5, bottom: BusinSpace.x2),
                          child: Text(weekLabel(context, week.monday, thisMonday: thisMonday), style: text.titleSmall?.copyWith(color: p.muted)),
                        ),
                        for (final entry in week.items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: BusinSpace.x3),
                            child: HistoryCard(entry: entry, zone: zone, onTap: () => context.push(Routes.trip(entry.id))),
                          ),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: BusinSpace.x4),
                        child: Center(
                          child: state.loadingMore
                              ? const CircularProgressIndicator()
                              : state.moreFailed
                                  ? TextButton(onPressed: () => ref.read(tripHistoryProvider.notifier).loadMore(), child: Text(l10n.actionRetry))
                                  : state.done
                                      ? Text(l10n.opsHistoryEnd, style: text.bodySmall?.copyWith(color: p.muted))
                                      : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// One past trip.
class HistoryCard extends StatelessWidget {
  const HistoryCard({super.key, required this.entry, required this.zone, required this.onTap});

  final TripHistoryEntry entry;
  final String zone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final material = MaterialLocalizations.of(context);
    final wall = const SchoolClock().wallClock(zone, entry.scheduledStart);
    final when = '${material.formatMediumDate(wall)}, ${material.formatTimeOfDay(TimeOfDay.fromDateTime(wall))}';

    // How it went: cancelled, never run, started in the field, on time, or late by so much.
    final (String timing, StatusTone tone) = switch (entry) {
      TripHistoryEntry(status: TripStatus.cancelled) => (l10n.tripStatus(TripStatus.cancelled), StatusTone.neutral),
      TripHistoryEntry(startedAt: null) => (l10n.opsNotRun, StatusTone.bad),
      TripHistoryEntry(startedInField: true) => (l10n.opsFieldBadge, StatusTone.info),
      _ when entry.onTime == true => (l10n.opsOnTime, StatusTone.ok),
      _ => (l10n.opsLateBy(entry.delay!.inMinutes), StatusTone.warn),
    };
    final part = switch (entry.part) {
      CrewPart.driver => l10n.opsRoleDriver,
      CrewPart.assistant => l10n.opsRoleAssistant,
      CrewPart.starter => l10n.opsRoleStarter,
    };
    final duration = entry.duration;

    return BusinCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(entry.busLabel, style: text.titleMedium)),
              StatusChip(label: timing, tone: tone),
            ],
          ),
          const SizedBox(height: BusinSpace.x1),
          Text('${l10n.direction(entry.direction)} · $when', style: text.bodySmall?.copyWith(color: p.muted)),
          const SizedBox(height: BusinSpace.x3),
          Wrap(
            spacing: BusinSpace.x2,
            runSpacing: BusinSpace.x2,
            children: [
              StatusChip(label: part, icon: entry.part == CrewPart.driver ? HugeIcons.strokeRoundedSteering : HugeIcons.strokeRoundedUserMultiple),
              if (entry.startedAt != null) StatusChip(label: l10n.opsBoardedCount(entry.boarded), icon: HugeIcons.strokeRoundedUserCheck01),
              if (duration != null) StatusChip(label: l10n.opsDuration(durationLabel(l10n, duration.inMinutes)), icon: HugeIcons.strokeRoundedClock01),
            ],
          ),
        ],
      ),
    );
  }
}
