import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../history/history_providers.dart';
import '../history/history_stats.dart';
import '../qr/qr_providers.dart';
import '../router.dart';
import '../subscription/subscription_providers.dart';

/// The student's own boardings, newest first, grouped by the day at the school: two numbers on top, then a card per day.
/// On a wide screen the days are on the left and the chosen day's summary is on the right. Pages load as the list is
/// scrolled near its end. Opened from the profile.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final history = ref.watch(scanHistoryProvider);
    final wide = BusinLayout.of(context).isExpanded;

    return ContentColumn(
      maxWidth: wide ? 1180 : BusinLayout.maxColumn,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(scanHistoryProvider);
          try {
            await ref.read(scanHistoryProvider.future);
          } catch (_) {
            // The error state on screen says what happened.
          }
        },
        child: history.when(
          loading: () => const _HistorySkeleton(),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 80),
              EmptyState(
                icon: HugeIcons.strokeRoundedWifiDisconnected01,
                title: error is RepositoryException ? l10n.failure(error) : l10n.errorGeneric,
                action: BusinButton(label: l10n.actionRetry, onPressed: () => ref.invalidate(scanHistoryProvider)),
              ),
            ],
          ),
          data: (state) {
            if (state.entries.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 40),
                  EmptyState(illustration: BusinIllustration.seat, title: l10n.historyEmptyTitle, body: l10n.historyEmptyBody),
                ],
              );
            }
            return _HistoryList(state: state);
          },
        ),
      ),
    );
  }
}

/// Today at the school (no time of day), for "this week".
DateTime _schoolToday(WidgetRef ref) {
  final now = ref.watch(nowProvider)();
  final school = ref.watch(schoolProvider).value;
  final wall = school == null ? now.toLocal() : ref.watch(schoolClockProvider).wallClock(school.timezone, now);
  return DateTime(wall.year, wall.month, wall.day);
}

class _HistoryList extends ConsumerStatefulWidget {
  const _HistoryList({required this.state});

  final HistoryState state;

  @override
  ConsumerState<_HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends ConsumerState<_HistoryList> {
  final _controller = ScrollController();

  /// The day the right-hand summary shows on a wide screen; the newest day until one is tapped.
  DateTime? _selected;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// If what is loaded does not fill the screen there is nothing to scroll, so nothing would ask for more.
  void _fillScreen() {
    final state = widget.state;
    if (!mounted || !_controller.hasClients || !state.hasMore || state.loadingMore || state.loadMoreFailed) return;
    if (_controller.position.maxScrollExtent <= 0) ref.read(scanHistoryProvider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    WidgetsBinding.instance.addPostFrameCallback((_) => _fillScreen());

    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final material = MaterialLocalizations.of(context);
    final use24 = MediaQuery.alwaysUse24HourFormatOf(context);
    final wide = BusinLayout.of(context).isExpanded;
    final days = groupByDay(state.entries);
    final stats = statsFor(state.entries, _schoolToday(ref));
    final selected = days.firstWhere((d) => d.day == _selected, orElse: () => days.first);

    String time(DateTime when) => material.formatTimeOfDay(TimeOfDay.fromDateTime(when), alwaysUse24HourFormat: use24);

    // Equal height cards in a list (which has no height of its own to stretch to).
    Widget statCards() => IntrinsicHeight(
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: StaggeredIn(child: StatCard(label: l10n.historyStatWeek, value: '${stats.thisWeek}', icon: HugeIcons.strokeRoundedCalendar03))),
            const SizedBox(width: BusinSpace.x3),
            Expanded(child: StaggeredIn(index: 1, child: StatCard(label: l10n.historyStatStop, value: stats.topStop ?? l10n.historyStatStopNone, icon: HugeIcons.strokeRoundedFlag02))),
          ],
        ),
        );

    Widget entryRow(HistoryEntry entry, {required bool last}) => Column(
          key: ValueKey(entry.scan.id),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: BusinSpace.x3),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(BusinRadius.xs)),
                    child: Padding(padding: const EdgeInsets.all(BusinSpace.x2), child: HugeIcon(icon: HugeIcons.strokeRoundedBus01, color: p.fg, size: 22)),
                  ),
                  const SizedBox(width: BusinSpace.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.stopName ?? l10n.historyStopUnknown, style: text.titleSmall),
                        if (entry.direction != null) Text(l10n.direction(entry.direction!), style: text.bodySmall?.copyWith(color: p.muted)),
                      ],
                    ),
                  ),
                  Text(time(entry.when), style: text.titleSmall),
                ],
              ),
            ),
            if (!last) Divider(height: 1, color: p.line),
          ],
        );

    Widget dayCard(HistoryDay day, int index) {
      final isSelected = wide && day.day == selected.day;
      return Padding(
        padding: const EdgeInsets.only(bottom: BusinSpace.x4),
        child: StaggeredIn(
          // Only the first few arrive one after another; later pages just appear.
          index: index < 5 ? index : 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: wide ? () => setState(() => _selected = day.day) : null,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(BusinSpace.x2, 0, BusinSpace.x2, BusinSpace.x2),
                  child: Row(
                    children: [
                      Expanded(child: Text(material.formatFullDate(day.day), style: text.labelLarge?.copyWith(color: p.muted))),
                      Text(l10n.historyDayCount(day.entries.length), style: text.labelMedium?.copyWith(color: p.muted)),
                    ],
                  ),
                ),
              ),
              BusinCard(
                padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x5, vertical: BusinSpace.x2),
                color: isSelected ? p.surface2 : null,
                onTap: wide ? () => setState(() => _selected = day.day) : null,
                semanticLabel: wide ? '${material.formatFullDate(day.day)}. ${l10n.historyDayCount(day.entries.length)}' : null,
                child: Column(children: [for (var i = 0; i < day.entries.length; i++) entryRow(day.entries[i], last: i == day.entries.length - 1)]),
              ),
            ],
          ),
        ),
      );
    }

    Widget footer() {
      if (state.loadingMore) {
        return const Padding(padding: EdgeInsets.all(BusinSpace.x5), child: Center(child: CircularProgressIndicator()));
      }
      if (state.loadMoreFailed) {
        return ListTile(
          leading: HugeIcon(icon: HugeIcons.strokeRoundedRefresh, color: p.bad),
          title: Text(l10n.historyLoadMoreFailed, style: TextStyle(color: p.bad)),
          onTap: () => ref.read(scanHistoryProvider.notifier).loadMore(retry: true),
        );
      }
      return const SizedBox.shrink();
    }

    Widget summary() {
      final s = summarizeDay(selected);
      Widget line(List<List<dynamic>> icon, String label, String value) => Padding(
            padding: const EdgeInsets.symmetric(vertical: BusinSpace.x2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HugeIcon(icon: icon, size: 20, color: p.muted),
                const SizedBox(width: BusinSpace.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: text.labelMedium?.copyWith(color: p.muted)),
                      Text(value, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          );
      return StaggeredIn(
        index: 2,
        child: BusinCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.historySelectedDay, style: text.labelLarge?.copyWith(color: p.muted)),
              const SizedBox(height: BusinSpace.x1),
              Text(material.formatFullDate(selected.day), style: text.titleLarge),
              const SizedBox(height: BusinSpace.x1),
              Text(l10n.historyDayCount(s.count), style: text.bodyMedium?.copyWith(color: p.muted)),
              const SizedBox(height: BusinSpace.x3),
              line(HugeIcons.strokeRoundedSunrise, l10n.historyDayFirst, time(s.first)),
              line(HugeIcons.strokeRoundedSunset, l10n.historyDayLast, time(s.last)),
              if (s.stops.isNotEmpty) line(HugeIcons.strokeRoundedFlag02, l10n.historyDayStops, s.stops.join(', ')),
            ],
          ),
        ),
      );
    }

    final scroller = NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Ask for the next page a little before the end, so it is usually there by the time you reach it.
        if (state.hasMore && !state.loadingMore && !state.loadMoreFailed && notification.metrics.extentAfter < 400) {
          ref.read(scanHistoryProvider.notifier).loadMore();
        }
        return false;
      },
      child: ListView(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(BusinSpace.x5, BusinSpace.x4, BusinSpace.x5, BusinSpace.x6 + BusinScope.of(context).bottomInset),
        children: [
          if (!wide) ...[
            Text(l10n.historyTitle, style: text.headlineMedium),
            const SizedBox(height: BusinSpace.x4),
            statCards(),
            const SizedBox(height: BusinSpace.x6),
          ],
          for (var i = 0; i < days.length; i++) dayCard(days[i], i),
          footer(),
        ],
      ),
    );

    if (!wide) return scroller;
    // A wide screen: the days on the left, the numbers and the chosen day on the right.
    return Padding(
      padding: const EdgeInsets.only(top: BusinSpace.x2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: scroller),
          Expanded(
            flex: 5,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, BusinSpace.x4, BusinSpace.x5, BusinSpace.x6),
              children: [
                Text(l10n.historyTitle, style: text.headlineMedium),
                const SizedBox(height: BusinSpace.x4),
                statCards(),
                const SizedBox(height: BusinSpace.x4),
                summary(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// While the first page loads: the two numbers and a couple of day cards, as grey shapes of the real thing.
class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final wide = BusinLayout.of(context).isExpanded;

    Widget stats() => const Row(
          children: [
            Expanded(child: Skeleton(height: 112, radius: BusinRadius.lg)),
            SizedBox(width: BusinSpace.x3),
            Expanded(child: Skeleton(height: 112, radius: BusinRadius.lg)),
          ],
        );

    Widget day(int rows) => Padding(
          padding: const EdgeInsets.only(bottom: BusinSpace.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.fromLTRB(BusinSpace.x2, 0, 0, BusinSpace.x2), child: Skeleton(width: 150, height: 14)),
              BusinCard(
                padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x5, vertical: BusinSpace.x2),
                child: Column(
                  children: [
                    for (var i = 0; i < rows; i++)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: BusinSpace.x3),
                        child: Row(
                          children: [
                            Skeleton(width: 38, height: 38, radius: BusinRadius.xs),
                            SizedBox(width: BusinSpace.x3),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Skeleton(width: 140, height: 14), SizedBox(height: BusinSpace.x2), Skeleton(width: 90, height: 12)])),
                            Skeleton(width: 44, height: 14),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );

    final days = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [day(3), day(2)]);

    return Semantics(
      liveRegion: true,
      label: l10n.historyTitle,
      child: ExcludeSemantics(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(BusinSpace.x5, BusinSpace.x4, BusinSpace.x5, BusinSpace.x6),
          children: [
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: days),
                  const SizedBox(width: BusinSpace.x5),
                  Expanded(
                    flex: 5,
                    child: Column(children: [stats(), const SizedBox(height: BusinSpace.x4), const Skeleton(height: 220, radius: BusinRadius.lg)]),
                  ),
                ],
              )
            else ...[
              const Skeleton(width: 180, height: 28, radius: BusinRadius.xs),
              const SizedBox(height: BusinSpace.x4),
              stats(),
              const SizedBox(height: BusinSpace.x6),
              days,
            ],
          ],
        ),
      ),
    );
  }
}

/// The history as a page of its own, above the tabs, with a way back to the profile.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navHistory), leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go(Routes.profile))),
      body: const SafeArea(child: HistoryScreen()),
    );
  }
}
