import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Trips left running (owner, 2026-11-17): the server reminds whoever runs a trip that looks forgotten, and the
/// reminder carries an End trip button. Android shows a button only on a notification the app draws itself, so the
/// server sends these as data messages and this file draws them: in the background (the app closed) with the words
/// the server sent, and in the foreground with the app's own.
const tripReminderKind = 'trip_still_running';
const endTripActionId = 'end_trip';

/// What the person chose on a reminder: the trip, and whether they pressed End trip (or only opened it).
typedef ReminderChoice = ({String tripId, bool end});

/// Reads a tap on a reminder. Null when it is not one of ours.
ReminderChoice? reminderChoice(NotificationResponse response) {
  final tripId = response.payload;
  if (tripId == null || tripId.isEmpty) return null;
  return (tripId: tripId, end: response.actionId == endTripActionId);
}

/// Shows reminders and reports what the person chose. Behind an interface so tests use a fake.
abstract interface class TripReminderNotifications {
  /// Starts listening; [onChoice] gets each tap while the app runs.
  Future<void> init(void Function(ReminderChoice choice) onChoice);

  /// The tap that opened the app, if a reminder did (the app was closed).
  Future<ReminderChoice?> launchChoice();

  Future<void> show({required String tripId, required String title, required String body, required String action});
}

class LocalTripReminderNotifications implements TripReminderNotifications {
  LocalTripReminderNotifications([FlutterLocalNotificationsPlugin? plugin]) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  @override
  Future<void> init(void Function(ReminderChoice choice) onChoice) async {
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('@drawable/ic_stat_busin')),
      onDidReceiveNotificationResponse: (response) {
        final choice = reminderChoice(response);
        if (choice != null) onChoice(choice);
      },
    );
    _ready = true;
  }

  @override
  Future<ReminderChoice?> launchChoice() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    final response = details?.notificationResponse;
    if (details?.didNotificationLaunchApp != true || response == null) return null;
    return reminderChoice(response);
  }

  @override
  Future<void> show({required String tripId, required String title, required String body, required String action}) async {
    if (!_ready) await init((_) {});
    await _plugin.show(
      // One per trip: a second reminder replaces the first.
      id: tripId.hashCode & 0x7fffffff,
      title: title,
      body: body,
      payload: tripId,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'busin_trips',
          'Trips',
          channelDescription: 'Reminders about trips you run',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
          // Opens the app, which ends the trip signed in as the person, and says how it went.
          actions: [AndroidNotificationAction(endTripActionId, action, showsUserInterface: true, cancelNotification: true)],
        ),
      ),
    );
  }
}

/// Firebase calls this, in a background isolate, for a data message while the app is not in front. It draws a trip
/// reminder with the words the server sent; anything else is left alone.
@pragma('vm:entry-point')
Future<void> opsBackgroundMessage(RemoteMessage message) async {
  final data = message.data;
  final tripId = data['ref_id'];
  if (data['kind'] != tripReminderKind || tripId is! String || tripId.isEmpty) return;
  await LocalTripReminderNotifications().show(
    tripId: tripId,
    title: (data['title'] as String?) ?? 'BusIn Ops',
    body: (data['body'] as String?) ?? '',
    action: (data['action'] as String?) ?? 'End trip',
  );
}
