import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../trips/my_trips_providers.dart';

/// My own numbers over the last 12 weeks: how many trips, how punctual (and whether that is getting better), how many
/// students boarded, time on the road, and my part on the crew. Every chart also has its numbers in text.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final stats = ref.watch(myStatsProvider);
    final bottom = BusinScope.of(context).bottomInset;

    Future<void> refresh() async {
      ref.invalidate(myStatsProvider);
      await ref.read(myStatsProvider.future).catchError((Object _) => const <WeekStats>[]);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.opsStatsTitle)),
      body: SafeArea(
        bottom: false,
        child: ContentColumn(
          child: RefreshIndicator(
            onRefresh: refresh,
            child: stats.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => ListView(
                children: [
                  EmptyState(illustration: BusinIllustration.waiting, title: l10n.errorGeneric, action: BusinButton(label: l10n.actionRetry, onPressed: refresh)),
                ],
              ),
              data: (weeks) {
                final summary = StatsSummary(weeks);
                if (summary.trips == 0) {
                  return ListView(children: [EmptyState(illustration: BusinIllustration.busStop, title: l10n.opsStatsEmpty)]);
                }
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(BusinSpace.x5, BusinSpace.x2, BusinSpace.x5, BusinSpace.x6 + bottom),
                  children: [_StatsBody(weeks: weeks, summary: summary)],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.weeks, required this.summary});

  final List<WeekStats> weeks;
  final StatsSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final material = MaterialLocalizations.of(context);
    String percent(double v) => '${(v * 100).round()}%';
    // Week labels on the axis: each Monday's day, with the month on the first week and when it changes ("24 Aug", "31",
    // "7 Sep", "14").
    final labels = [
      for (var i = 0; i < weeks.length; i++)
        i == 0 || weeks[i].weekStart.month != weeks[i - 1].weekStart.month ? material.formatShortMonthDay(weeks[i].weekStart) : '${weeks[i].weekStart.day}',
    ];

    final punctuality = summary.punctuality;
    final delay = summary.avgDelayMinutes;
    final perTrip = summary.boardedPerTrip;
    final trend = punctualityTrend(weeks);
    final timed = [for (final w in weeks) if (w.punctuality != null) w];
    final best = timed.isEmpty ? null : timed.reduce((a, b) => b.punctuality! > a.punctuality! ? b : a);
    final worst = timed.isEmpty ? null : timed.reduce((a, b) => b.punctuality! < a.punctuality! ? b : a);
    final notRun = summary.cancelled + summary.missed;

    Widget heading(String title) => Padding(
          padding: const EdgeInsets.only(top: BusinSpace.x6, bottom: BusinSpace.x3),
          child: Text(title, style: text.titleMedium),
        );

    Widget tiles(List<Widget> children) => LayoutBuilder(
          builder: (context, box) {
            final columns = box.maxWidth >= 640 ? 4 : 2;
            final width = (box.maxWidth - BusinSpace.x3 * (columns - 1)) / columns;
            return Wrap(
              spacing: BusinSpace.x3,
              runSpacing: BusinSpace.x3,
              children: [for (final c in children) SizedBox(width: width, child: c)],
            );
          },
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: BusinSpace.x3, bottom: BusinSpace.x4),
          child: Text(l10n.opsStatsPeriod, style: text.bodyMedium?.copyWith(color: p.muted)),
        ),
        tiles([
          StatCard(label: l10n.opsStatsTrips, value: '${summary.trips}', icon: HugeIcons.strokeRoundedBus01),
          StatCard(label: l10n.opsStatsOnTime, value: punctuality == null ? l10n.opsStatsNoData : percent(punctuality), icon: HugeIcons.strokeRoundedClock01),
          StatCard(label: l10n.opsStatsAvgDelay, value: delay == null ? l10n.opsStatsNoData : durationLabel(l10n, delay.round()), icon: HugeIcons.strokeRoundedTimer02),
          StatCard(label: l10n.opsStatsOnRoad, value: durationLabel(l10n, summary.minutesOnRoad), icon: HugeIcons.strokeRoundedRoute01),
        ]),
        if (trend != null)
          Padding(
            padding: const EdgeInsets.only(top: BusinSpace.x4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: StatusChip(
                label: switch (trend) {
                  Trend.up => l10n.opsStatsTrendUp,
                  Trend.down => l10n.opsStatsTrendDown,
                  Trend.steady => l10n.opsStatsTrendSame,
                },
                tone: switch (trend) {
                  Trend.up => StatusTone.ok,
                  Trend.down => StatusTone.warn,
                  Trend.steady => StatusTone.neutral,
                },
                icon: switch (trend) {
                  Trend.up => HugeIcons.strokeRoundedArrowUpRight01,
                  Trend.down => HugeIcons.strokeRoundedArrowDownRight01,
                  Trend.steady => HugeIcons.strokeRoundedArrowRight01,
                },
              ),
            ),
          ),

        heading(l10n.opsStatsTripsChart),
        BusinBarChart(
          bars: [
            for (var i = 0; i < weeks.length; i++)
              ChartBar(label: labels[i], segments: [
                weeks[i].onTime.toDouble(),
                weeks[i].late.toDouble(),
                weeks[i].fieldTrips.toDouble(),
                (weeks[i].cancelled + weeks[i].missed).toDouble(),
              ]),
          ],
          colors: [p.ok, p.warn, p.info, p.muted],
          semanticLabel: l10n.opsStatsTripsSummary(summary.trips, summary.onTime, summary.late, summary.fieldTrips, notRun),
        ),
        const SizedBox(height: BusinSpace.x3),
        ChartLegend(items: [
          (color: p.ok, label: l10n.opsStatsLegendOnTime),
          (color: p.warn, label: l10n.opsStatsLegendLate),
          (color: p.info, label: l10n.opsStatsLegendField),
          (color: p.muted, label: l10n.opsStatsLegendNotRun),
        ]),
        const SizedBox(height: BusinSpace.x3),
        Text(l10n.opsStatsBreakdown(summary.completed, summary.cancelled, summary.missed), style: text.bodySmall?.copyWith(color: p.muted)),

        if (punctuality != null) ...[
          heading(l10n.opsStatsPunctualityChart),
          BusinLineChart(
            points: [for (final w in weeks) w.punctuality],
            labels: labels,
            color: p.accent,
            format: percent,
            target: 0.9,
            semanticLabel: l10n.opsStatsPunctualitySummary(
              percent(punctuality),
              best == null ? '' : '${material.formatShortMonthDay(best.weekStart)} ${percent(best.punctuality!)}',
              worst == null ? '' : '${material.formatShortMonthDay(worst.weekStart)} ${percent(worst.punctuality!)}',
            ),
          ),
          const SizedBox(height: BusinSpace.x3),
          Text(l10n.opsStatsPunctualityHint, style: text.bodySmall?.copyWith(color: p.muted)),
        ],

        heading(l10n.opsStatsBoardedChart),
        tiles([StatCard(label: l10n.opsStatsBoarded, value: '${summary.boarded}', icon: HugeIcons.strokeRoundedUserCheck01)]),
        if (perTrip != null)
          Padding(
            padding: const EdgeInsets.only(top: BusinSpace.x2),
            child: Text(l10n.opsStatsPerTrip(perTrip.toStringAsFixed(1)), style: text.bodySmall?.copyWith(color: p.muted)),
          ),
        const SizedBox(height: BusinSpace.x4),
        BusinBarChart(
          bars: [for (var i = 0; i < weeks.length; i++) ChartBar(label: labels[i], segments: [weeks[i].boarded.toDouble()])],
          colors: [p.brand],
          semanticLabel: l10n.opsStatsBoardedSummary(summary.boarded),
        ),
        const SizedBox(height: BusinSpace.x5),
        Text(l10n.opsStatsRoles(summary.asDriver, summary.asAssistant), style: text.bodyMedium),
      ],
    );
  }
}
