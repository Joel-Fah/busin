import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_plan.dart';

/// The words of one reminder, already in the student's language.
typedef ReminderText = ({String title, String body});

/// Places reminders on the phone. Replacing is all-or-nothing: the previous plan is cancelled first.
abstract interface class ReminderScheduler {
  Future<void> replace(List<PlannedReminder> plan, {required String timeZone, required ReminderText Function(ReminderKind kind) text});

  /// Asks the phone to allow notifications (Android 13 and later), and says whether they are allowed.
  Future<bool> requestPermission();

  /// Shows one notification now, so the student sees what a kind they just turned on looks like. Local only.
  Future<void> showSample(ReminderText text);
}

/// The id of the sample notification: outside the range the plan uses, and each sample replaces the last.
const sampleNotificationId = 9000;

/// Does nothing: for tests, and for platforms without local notifications.
class NoReminderScheduler implements ReminderScheduler {
  const NoReminderScheduler();

  @override
  Future<void> replace(List<PlannedReminder> plan, {required String timeZone, required ReminderText Function(ReminderKind kind) text}) async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> showSample(ReminderText text) async {}
}

/// Local notifications on the phone. They work offline and nothing about them is sent to the server.
class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler([FlutterLocalNotificationsPlugin? plugin]) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static const _channel = AndroidNotificationDetails(
    'busin_reminders',
    'Reminders',
    channelDescription: 'Morning and evening reminders you set in BusIn',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  Future<void> _init() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    await _plugin.initialize(settings: const InitializationSettings(android: AndroidInitializationSettings('@drawable/ic_stat_busin')));
    _ready = true;
  }

  @override
  Future<void> replace(List<PlannedReminder> plan, {required String timeZone, required ReminderText Function(ReminderKind kind) text}) async {
    await _init();
    await _plugin.cancelAllPendingNotifications();
    tz.Location location;
    try {
      location = tz.getLocation(timeZone);
    } catch (_) {
      location = tz.UTC;
    }
    for (final reminder in plan) {
      final words = text(reminder.kind);
      final at = reminder.at;
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: words.title,
        body: words.body,
        scheduledDate: tz.TZDateTime(location, at.year, at.month, at.day, at.hour, at.minute),
        notificationDetails: const NotificationDetails(android: _channel),
        // Inexact: no special alarm permission is needed, and a minute or two either way is fine for a reminder.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<bool> requestPermission() async {
    await _init();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> showSample(ReminderText text) async {
    await _init();
    await _plugin.show(id: sampleNotificationId, title: text.title, body: text.body, notificationDetails: const NotificationDetails(android: _channel));
  }
}
