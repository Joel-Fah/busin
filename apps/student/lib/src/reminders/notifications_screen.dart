import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../boarding/boarding_card.dart';
import '../router.dart';
import 'notification_providers.dart';
import 'reminder_scheduler.dart';

/// Which days the student rides and what BusIn reminds them of. Every change is saved at once; reminders are then
/// placed on the phone again. Notices from the school cannot be turned off, and the page says so.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const busNearChoices = [3, 5, 10, 15];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final prefs = ref.watch(notificationPreferencesProvider);
    // Keep the phone's reminders in step while this page is open (it plans again after each change).
    ref.watch(reminderSyncProvider);

    Future<void> save(NotificationPreferences next) async {
      try {
        await ref.read(notificationPreferencesProvider.notifier).save(next);
      } catch (_) {
        if (context.mounted) BusinToast.show(context, l10n.errorGeneric, tone: ToastTone.error);
      }
    }

    // Turning a kind on asks for the permission, then shows one example right away so the student sees what will come.
    Future<void> turnOn(NotificationPreferences next, ReminderText sample) async {
      await save(next);
      final scheduler = ref.read(reminderSchedulerProvider);
      final allowed = await scheduler.requestPermission();
      if (!context.mounted) return;
      if (!allowed) {
        BusinToast.show(context, l10n.notificationsPermission, tone: ToastTone.info);
        return;
      }
      await scheduler.showSample(sample);
      if (context.mounted) BusinToast.show(context, l10n.notificationsSampleSent, tone: ToastTone.info);
    }

    Future<TimeOfDayValue?> pickTime(TimeOfDayValue current) async {
      final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: current.hour, minute: current.minute));
      return picked == null ? null : TimeOfDayValue(picked.hour, picked.minute);
    }

    String timeLabel(TimeOfDayValue time) => MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: time.hour, minute: time.minute));

    Widget toggle({
      required String title,
      required String hint,
      required bool value,
      required ValueChanged<bool>? onChanged,
      Widget? below,
      List<List<dynamic>>? icon,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: BusinSpace.x2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.titleMedium),
                      Text(hint, style: text.bodySmall?.copyWith(color: p.muted)),
                    ],
                  ),
                ),
                if (icon != null) HugeIcon(icon: icon, size: 20, color: p.muted) else Switch.adaptive(value: value, onChanged: onChanged),
              ],
            ),
            if (below != null) ...[const SizedBox(height: BusinSpace.x2), below],
          ],
        ),
      );
    }

    Widget body(NotificationPreferences current) {
      final locale = Localizations.localeOf(context).toLanguageTag();
      // Monday first, as the database stores it.
      final weekdays = [for (var day = 1; day <= 7; day++) (day, DateFormat.E(locale).format(DateTime(2024, 1, day)))];
      return ListView(
        padding: const EdgeInsets.all(BusinSpace.x5),
        children: [
          Text(l10n.notificationsHint, style: text.bodyMedium?.copyWith(color: p.muted)),
          const SizedBox(height: BusinSpace.x4),
          BusinCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.notificationsDays, style: text.titleMedium),
                Text(l10n.notificationsDaysHint, style: text.bodySmall?.copyWith(color: p.muted)),
                const SizedBox(height: BusinSpace.x3),
                Wrap(
                  spacing: BusinSpace.x2,
                  runSpacing: BusinSpace.x2,
                  children: [
                    for (final (day, label) in weekdays)
                      FilterChip(
                        label: Text(label),
                        selected: current.ridingDays.contains(day),
                        onSelected: (on) => save(current.copyWith(ridingDays: on ? {...current.ridingDays, day} : ({...current.ridingDays}..remove(day)))),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: BusinSpace.x4),
          BusinCard(
            child: Column(
              children: [
                toggle(
                  title: l10n.notificationsMorning,
                  hint: l10n.notificationsMorningHint,
                  value: current.morningOn,
                  onChanged: (on) => on
                      ? turnOn(current.copyWith(morningOn: true), (title: l10n.reminderMorningTitle, body: l10n.reminderMorningBody))
                      : save(current.copyWith(morningOn: false)),
                  below: current.morningOn
                      ? TextButton.icon(
                          icon: HugeIcon(icon: HugeIcons.strokeRoundedClock01, size: 18, color: p.fg),
                          label: Text(l10n.notificationsAt(timeLabel(current.morningTime))),
                          onPressed: () async {
                            final time = await pickTime(current.morningTime);
                            if (time != null) await save(current.copyWith(morningTime: time));
                          },
                        )
                      : null,
                ),
                const Divider(),
                toggle(
                  title: l10n.notificationsEvening,
                  hint: l10n.notificationsEveningHint,
                  value: current.eveningOn,
                  onChanged: (on) => on
                      ? turnOn(current.copyWith(eveningOn: true), (title: l10n.reminderEveningTitle, body: l10n.reminderEveningBody))
                      : save(current.copyWith(eveningOn: false)),
                  below: current.eveningOn
                      ? TextButton.icon(
                          icon: HugeIcon(icon: HugeIcons.strokeRoundedClock01, size: 18, color: p.fg),
                          label: Text(l10n.notificationsAt(timeLabel(current.eveningTime))),
                          onPressed: () async {
                            final time = await pickTime(current.eveningTime);
                            if (time != null) await save(current.copyWith(eveningTime: time));
                          },
                        )
                      : null,
                ),
                const Divider(),
                toggle(
                  title: l10n.notificationsBusNear,
                  hint: l10n.notificationsBusNearHint,
                  value: current.busNearOn,
                  onChanged: (on) => on
                      ? turnOn(current.copyWith(busNearOn: true), (title: l10n.sampleBusNearTitle, body: l10n.sampleBusNearBody))
                      : save(current.copyWith(busNearOn: false)),
                  below: current.busNearOn
                      ? Wrap(
                          spacing: BusinSpace.x2,
                          children: [
                            for (final minutes in busNearChoices)
                              ChoiceChip(
                                label: Text(l10n.notificationsBusNearMinutes(minutes)),
                                selected: current.busNearMinutes == minutes,
                                onSelected: (_) => save(current.copyWith(busNearMinutes: minutes)),
                              ),
                          ],
                        )
                      : null,
                ),
                const Divider(),
                toggle(
                  title: l10n.notificationsBoarding,
                  hint: l10n.notificationsBoardingHint,
                  value: current.boardingMessagesOn,
                  onChanged: (on) async {
                    await save(current.copyWith(boardingMessagesOn: on));
                    // The card itself is the example: it shows in the app, over this page.
                    if (on && context.mounted) {
                      final code = Localizations.localeOf(context).languageCode;
                      await showBoardingCard(context, title: l10n.boardedTitle, line: boardingLine(BoardingMoment(at: DateTime.now()), seed: 'sample', languageCode: code));
                    }
                  },
                ),
                const Divider(),
                toggle(
                  title: l10n.notificationsSchool,
                  hint: l10n.notificationsSchoolHint,
                  value: true,
                  onChanged: null,
                  icon: HugeIcons.strokeRoundedLockPassword,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go(Routes.profile)),
      ),
      body: SafeArea(
        child: ContentColumn(
          child: prefs.when(
            data: body,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => EmptyState(
              illustration: BusinIllustration.blocked,
              title: l10n.errorGeneric,
              action: BusinButton(label: l10n.actionRetry, variant: BusinButtonVariant.secondary, onPressed: () => ref.invalidate(notificationPreferencesProvider)),
            ),
          ),
        ),
      ),
    );
  }
}
