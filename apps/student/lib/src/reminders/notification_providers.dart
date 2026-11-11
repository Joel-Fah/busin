import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/access.dart';
import '../providers.dart';
import '../subscription/subscription_providers.dart';
import 'reminder_plan.dart';
import 'reminder_scheduler.dart';

final notificationPreferencesRepositoryProvider =
    Provider<NotificationPreferencesRepository>((ref) => ref.watch(repositoriesProvider).notificationPreferences);

/// Where reminders are placed. Local notifications in the app; tests use [NoReminderScheduler].
final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) => LocalReminderScheduler());

/// The student's preferences: loaded from the server once signed in, saved there on every change.
class NotificationPreferencesNotifier extends AsyncNotifier<NotificationPreferences> {
  @override
  Future<NotificationPreferences> build() async {
    if (ref.watch(accessProvider) is! Allowed) return const NotificationPreferences();
    return ref.watch(notificationPreferencesRepositoryProvider).load();
  }

  /// Saves at once and shows the change; if the server refuses, the previous preferences come back and the error is rethrown.
  Future<void> save(NotificationPreferences next) async {
    final previous = state.value;
    state = AsyncData(next);
    try {
      await ref.read(notificationPreferencesRepositoryProvider).save(next);
    } catch (_) {
      if (previous != null) state = AsyncData(previous);
      rethrow;
    }
  }
}

final notificationPreferencesProvider =
    AsyncNotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(NotificationPreferencesNotifier.new);

/// Keeps the phone's reminders in step with the preferences, the semester and the language. Watched while the student
/// is in the app; it plans again whenever one of those changes. Without an approved subscription for a running
/// semester there is nothing to remind, so the plan is empty.
final reminderSyncProvider = FutureProvider.autoDispose<int>((ref) async {
  final scheduler = ref.watch(reminderSchedulerProvider);
  final code = ref.watch(languageCodeProvider)();
  final words = lookupBusinL10n(Locale(code == 'fr' ? 'fr' : 'en'));
  ReminderText text(ReminderKind kind) => kind == ReminderKind.morning
      ? (title: words.reminderMorningTitle, body: words.reminderMorningBody)
      : (title: words.reminderEveningTitle, body: words.reminderEveningBody);

  if (ref.watch(accessProvider) is! Allowed) {
    await scheduler.replace(const [], timeZone: 'UTC', text: text);
    return 0;
  }
  final preferences = await ref.watch(notificationPreferencesProvider.future);
  final school = await ref.watch(schoolProvider.future);
  final overview = await ref.watch(subscriptionOverviewProvider.future);
  final semester = overview.semester;
  final approved = overview.subscription?.status == SubscriptionStatus.approved && !overview.upcoming;
  final now = ref.watch(schoolClockProvider).wallClock(school.timezone, ref.read(nowProvider)());
  final plan = semester == null || !approved
      ? const <PlannedReminder>[]
      : planReminders(preferences: preferences, semesterStart: semester.startDate, semesterEnd: semester.endDate, now: now);
  await scheduler.replace(plan, timeZone: school.timezone, text: text);
  return plan.length;
}, retry: noAutomaticRetry);
