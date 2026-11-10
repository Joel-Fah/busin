import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import 'streak_providers.dart';

/// The streak on the pass screen: a small chip that opens the calendar. Shows nothing for a student who keeps no streak.
class StreakChip extends ConsumerWidget {
  const StreakChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider).value;
    if (streak == null) return const SizedBox.shrink();
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final on = streak.current > 0;
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: on ? p.accent.withValues(alpha: 0.16) : p.surface2,
        borderRadius: BorderRadius.circular(BusinRadius.xs),
        child: InkWell(
          borderRadius: BorderRadius.circular(BusinRadius.xs),
          onTap: () {
            BusinHaptics.light();
            showBusinSheet<void>(context, isScrollControlled: true, builder: (_) => const StreakSheet());
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x3, vertical: BusinSpace.x2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedFire, size: 18, color: on ? p.accent : p.muted),
                const SizedBox(width: BusinSpace.x2),
                Text(l10n.streakDays(streak.current), style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: BusinSpace.x1),
                HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 16, color: p.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _StreakView { calendar, board }

/// The streak in full: the current and best runs, the rides this semester, then either a calendar of every day since
/// opting in or the school's leaderboard.
class StreakSheet extends ConsumerStatefulWidget {
  const StreakSheet({super.key});

  @override
  ConsumerState<StreakSheet> createState() => _StreakSheetState();
}

class _StreakSheetState extends ConsumerState<StreakSheet> {
  var _view = _StreakView.calendar;

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final text = Theme.of(context).textTheme;
    final streak = ref.watch(streakProvider).value;
    return Padding(
      padding: EdgeInsets.all(BusinSheetFrame.contentInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.streakSheetTitle, style: text.titleLarge),
            const SizedBox(height: BusinSpace.x3),
            if (streak != null)
              Wrap(
                spacing: BusinSpace.x2,
                runSpacing: BusinSpace.x2,
                children: [
                  StatusChip(
                    label: l10n.streakDays(streak.current),
                    tone: streak.current > 0 ? StatusTone.ok : StatusTone.neutral,
                    icon: HugeIcons.strokeRoundedFire,
                  ),
                  StatusChip(label: l10n.streakBest(streak.best), icon: HugeIcons.strokeRoundedStar),
                  StatusChip(label: l10n.streakRides(streak.rides), icon: HugeIcons.strokeRoundedBus01),
                ],
              ),
            const SizedBox(height: BusinSpace.x4),
            BusinSegmented<_StreakView>(
              groupLabel: l10n.streakViewLabel,
              selected: _view,
              onChanged: (view) => setState(() => _view = view),
              segments: [
                BusinSegment(value: _StreakView.calendar, label: l10n.streakTabCalendar, icon: HugeIcons.strokeRoundedCalendar03),
                BusinSegment(value: _StreakView.board, label: l10n.streakTabBoard, icon: HugeIcons.strokeRoundedAward01),
              ],
            ),
            const SizedBox(height: BusinSpace.x4),
            // The board is only fetched once its tab is opened.
            if (_view == _StreakView.calendar) const _CalendarView() else const Leaderboard(),
          ],
        ),
      ),
    );
  }
}

class _CalendarView extends ConsumerWidget {
  const _CalendarView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    return ref.watch(rideDaysProvider).when(
          data: (list) => StreakCalendar(days: list),
          loading: () => const _Loading(),
          error: (_, _) => Text(l10n.errorGeneric, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: p.muted)),
        );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(BusinSpace.x6),
        child: Center(child: CircularProgressIndicator()),
      );
}

/// The school's board: rank, avatar, first name and initial, and the current streak. The student's own row is
/// highlighted, and shown below a gap when it falls outside the top of the board.
class Leaderboard extends ConsumerWidget {
  const Leaderboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    return ref.watch(leaderboardProvider).when(
          loading: () => const _Loading(),
          error: (_, _) => Text(l10n.errorGeneric, style: text.bodyMedium?.copyWith(color: p.muted)),
          data: (rows) {
            if (rows.isEmpty) return Text(l10n.leaderboardEmpty, style: text.bodyMedium?.copyWith(color: p.muted));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.leaderboardNote, style: text.bodySmall?.copyWith(color: p.muted)),
                const SizedBox(height: BusinSpace.x3),
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0 && rows[i].rank > rows[i - 1].rank + 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: BusinSpace.x1),
                      child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedMoreHorizontal, size: 18, color: p.muted)),
                    )
                  else if (i > 0)
                    const SizedBox(height: BusinSpace.x2),
                  _BoardRow(entry: rows[i]),
                ],
              ],
            );
          },
        );
  }
}

class _BoardRow extends StatelessWidget {
  const _BoardRow({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final name = entry.isMe ? '${entry.displayName} (${l10n.leaderboardYou})' : entry.displayName;
    final podium = entry.rank <= 3 && entry.currentStreak > 0;
    return Semantics(
      container: true,
      label: '${l10n.leaderboardRank(entry.rank)}, $name, ${l10n.streakDays(entry.currentStreak)}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x3, vertical: BusinSpace.x2),
          decoration: BoxDecoration(
            color: entry.isMe ? p.accent.withValues(alpha: 0.14) : p.surface2,
            borderRadius: BorderRadius.circular(BusinRadius.sm),
            border: entry.isMe ? Border.all(color: p.accent.withValues(alpha: 0.6)) : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '${entry.rank}',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: podium ? p.accent : p.muted),
                ),
              ),
              UserAvatar(name: entry.displayName, imageUrl: entry.avatarUrl, size: 32),
              const SizedBox(width: BusinSpace.x3),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyLarge?.copyWith(fontWeight: entry.isMe ? FontWeight.w700 : null),
                ),
              ),
              const SizedBox(width: BusinSpace.x2),
              HugeIcon(icon: HugeIcons.strokeRoundedFire, size: 16, color: entry.currentStreak > 0 ? p.accent : p.muted),
              const SizedBox(width: BusinSpace.x1),
              Text('${entry.currentStreak}', style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A month grid per month of the semester, Monday first, each day coloured by what it was.
class StreakCalendar extends StatelessWidget {
  const StreakCalendar({super.key, required this.days});

  final List<RideDay> days;

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (days.isEmpty) return const SizedBox.shrink();
    final byDay = {for (final d in days) d.day: d.state};
    final months = <DateTime>{for (final d in days) DateTime(d.day.year, d.day.month)}.toList()..sort();
    final weekdayNames = [for (var day = 1; day <= 7; day++) DateFormat.E(locale).format(DateTime(2024, 1, day)).characters.first];

    (Color, Color) look(RideDayState? state) => switch (state) {
      RideDayState.rode => (p.ok, Colors.white),
      RideDayState.missed => (p.badBg, p.bad),
      RideDayState.rest || RideDayState.noService => (p.surface2, p.muted),
      RideDayState.today => (p.surface, p.fg),
      RideDayState.future => (Colors.transparent, p.muted.withValues(alpha: 0.6)),
      null => (Colors.transparent, p.muted.withValues(alpha: 0.35)),
    };

    Widget legend(Color fill, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: p.line),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: text.bodySmall),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: BusinSpace.x3,
          runSpacing: BusinSpace.x2,
          children: [
            legend(p.ok, l10n.streakRode),
            legend(p.badBg, l10n.streakMissed),
            legend(p.surface2, l10n.streakRest),
            legend(p.surface, l10n.streakToday),
          ],
        ),
        for (final month in months) ...[
          const SizedBox(height: BusinSpace.x4),
          Text(DateFormat.yMMMM(locale).format(month), style: text.titleSmall),
          const SizedBox(height: BusinSpace.x2),
          GridView.count(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final name in weekdayNames)
                Center(
                  child: Text(name, style: text.labelSmall?.copyWith(color: p.muted)),
                ),
              for (var blank = 1; blank < month.weekday; blank++) const SizedBox.shrink(),
              for (var day = 1; day <= DateUtils.getDaysInMonth(month.year, month.month); day++)
                Builder(
                  builder: (context) {
                    final date = DateTime(month.year, month.month, day);
                    final state = byDay[date];
                    final (fill, ink) = look(state);
                    return Semantics(
                      label: '${DateFormat.MMMMd(locale).format(date)}${state == null ? '' : ', ${_stateLabel(l10n, state)}'}',
                      child: Container(
                        decoration: BoxDecoration(
                          color: fill,
                          borderRadius: BorderRadius.circular(BusinRadius.xs),
                          border: state == RideDayState.today ? Border.all(color: p.accent, width: 2) : null,
                        ),
                        alignment: Alignment.center,
                        child: ExcludeSemantics(
                          child: Text(
                            '$day',
                            style: text.labelMedium?.copyWith(color: ink, fontWeight: state == RideDayState.rode ? FontWeight.w800 : null),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }

  static String _stateLabel(BusinL10n l10n, RideDayState state) => switch (state) {
    RideDayState.rode => l10n.streakRode,
    RideDayState.missed => l10n.streakMissed,
    RideDayState.rest || RideDayState.noService => l10n.streakRest,
    RideDayState.today => l10n.streakToday,
    RideDayState.future => '',
  };
}
