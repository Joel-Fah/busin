import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../history/history_providers.dart';

/// The third tab: the student's own boardings, newest first, grouped by the day at the school.
/// Pages load as the list is scrolled near its end.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final history = ref.watch(scanHistoryProvider);

    return ContentColumn(
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
        loading: () => ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [SizedBox(height: 240), Center(child: CircularProgressIndicator())]),
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
                const SizedBox(height: 80),
                EmptyState(icon: HugeIcons.strokeRoundedReceiptText, title: l10n.historyEmptyTitle, body: l10n.historyEmptyBody),
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

class _HistoryList extends ConsumerStatefulWidget {
  const _HistoryList({required this.state});

  final HistoryState state;

  @override
  ConsumerState<_HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends ConsumerState<_HistoryList> {
  final _controller = ScrollController();

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
    final palette = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final material = MaterialLocalizations.of(context);
    final use24 = MediaQuery.alwaysUse24HourFormatOf(context);

    // One flat list: a header for each day, then its rows, then an end marker.
    final rows = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(BusinSpace.x5, BusinSpace.x5, BusinSpace.x5, BusinSpace.x2),
        child: Text(l10n.historyTitle, style: text.headlineSmall),
      ),
    ];
    for (final day in groupByDay(state.entries)) {
      rows.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(BusinSpace.x5, BusinSpace.x4, BusinSpace.x5, BusinSpace.x1),
          child: Text(material.formatFullDate(day.day), style: text.labelLarge?.copyWith(color: palette.muted)),
        ),
      );
      for (final entry in day.entries) {
        rows.add(
          ListTile(
            key: ValueKey(entry.scan.id),
            leading: DecoratedBox(
              decoration: BoxDecoration(color: palette.surface2, borderRadius: BorderRadius.circular(BusinRadius.xs)),
              child: Padding(padding: const EdgeInsets.all(BusinSpace.x2), child: HugeIcon(icon: HugeIcons.strokeRoundedBus01, color: palette.fg, size: 22)),
            ),
            title: Text(entry.stopName ?? l10n.historyStopUnknown),
            subtitle: entry.direction == null ? null : Text(l10n.direction(entry.direction!)),
            trailing: Text(
              material.formatTimeOfDay(TimeOfDay.fromDateTime(entry.when), alwaysUse24HourFormat: use24),
              style: text.titleSmall,
            ),
          ),
        );
      }
    }
    if (state.loadingMore) {
      rows.add(const Padding(padding: EdgeInsets.all(BusinSpace.x5), child: Center(child: CircularProgressIndicator())));
    } else if (state.loadMoreFailed) {
      rows.add(
        ListTile(
          leading: HugeIcon(icon: HugeIcons.strokeRoundedRefresh, color: palette.bad),
          title: Text(l10n.historyLoadMoreFailed, style: TextStyle(color: palette.bad)),
          onTap: () => ref.read(scanHistoryProvider.notifier).loadMore(retry: true),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Ask for the next page a little before the end, so it is usually there by the time you reach it.
        if (state.hasMore && !state.loadingMore && !state.loadMoreFailed && notification.metrics.extentAfter < 400) {
          ref.read(scanHistoryProvider.notifier).loadMore();
        }
        return false;
      },
      child: ListView(controller: _controller, physics: const AlwaysScrollableScrollPhysics(), padding: EdgeInsets.only(bottom: BusinSpace.x6 + BusinScope.of(context).bottomInset), children: rows),
    );
  }
}
