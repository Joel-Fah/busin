import 'dart:async';

import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:busin_ops/src/app.dart';
import 'package:busin_ops/src/providers.dart';
import 'package:busin_ops/src/push/push_binder.dart';
import 'package:busin_ops/src/push/trip_reminders.dart';
import 'package:busin_ops/src/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support.dart';

class FakePush implements PushService {
  PushPermission current = PushPermission.notAsked;
  PushPermission answer = PushPermission.granted;
  int requests = 0;
  int forgets = 0;
  PushMessage? launched;
  final tapped = StreamController<PushMessage>.broadcast();
  final arrived = StreamController<PushMessage>.broadcast();

  @override
  bool get available => true;
  @override
  Future<PushPermission> permission() async => current;
  @override
  Future<PushPermission> requestPermission() async {
    requests++;
    return current = answer;
  }

  @override
  Future<String?> token() async => current == PushPermission.granted ? 'ops-phone-token' : null;
  @override
  Stream<String> get tokenRefreshes => const Stream.empty();
  @override
  Stream<PushMessage> get taps => tapped.stream;
  @override
  Future<PushMessage?> launchedBy() async => launched;
  @override
  Stream<PushMessage> get foreground => arrived.stream;
  @override
  Future<void> forgetToken() async => forgets++;
}

class FakeTokens implements DeviceTokensRepository {
  final List<String> registered = [];
  final List<String> unregistered = [];
  @override
  Future<void> register({required String token, required String platform, required String locale}) async => registered.add('$token/$platform/$locale');
  @override
  Future<void> unregister(String token) async => unregistered.add(token);
}

/// The reminders the app draws, and the taps a test makes on them.
class FakeReminders implements TripReminderNotifications {
  void Function(ReminderChoice choice)? _onChoice;
  ReminderChoice? launched;
  final List<({String tripId, String title, String body, String action})> shown = [];

  void tap(ReminderChoice choice) => _onChoice?.call(choice);

  @override
  Future<void> init(void Function(ReminderChoice choice) onChoice) async => _onChoice = onChoice;
  @override
  Future<ReminderChoice?> launchChoice() async => launched;
  @override
  Future<void> show({required String tripId, required String title, required String body, required String action}) async =>
      shown.add((tripId: tripId, title: title, body: body, action: action));
}

Future<void> settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  test('a crew notification opens its trip; an unknown kind opens nothing', () {
    expect(opsRouteForPush(const PushMessage(kind: 'crew_assigned', refId: 't9')), Routes.trip('t9'));
    expect(opsRouteForPush(const PushMessage(kind: 'crew_assigned')), Routes.today);
    expect(opsRouteForPush(const PushMessage(kind: 'subscription_approved')), isNull);
  });

  Future<(FakePush, FakeTokens, FakeAuth)> open(WidgetTester tester, {Map<String, Object> prefs = const {}, FakeTrips? trips, FakeReminders? reminders}) async {
    SharedPreferences.setMockInitialValues(prefs);
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final push = FakePush();
    final tokens = FakeTokens();
    final auth = FakeAuth(signedInAs: 'u1');
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...overridesFor(auth: auth, profiles: {'u1': staff()}, trips: trips ?? FakeTrips([trip('t1', driver: 'u1')])),
        pushServiceProvider.overrideWithValue(push),
        deviceTokensRepositoryProvider.overrideWithValue(tokens),
        tripReminderNotificationsProvider.overrideWithValue(reminders ?? FakeReminders()),
      ],
      child: const OpsApp(),
    ));
    await settle(tester);
    return (push, tokens, auth);
  }

  testWidgets('after sign-in the phone is asked once, then registered for notifications', (tester) async {
    final (push, tokens, _) = await open(tester);
    expect(push.requests, 1, reason: 'asked on the first sign-in');
    expect(tokens.registered, ['ops-phone-token/android/en']);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(pushAskedKey), isTrue, reason: 'and remembered, so it is not asked again');
  });

  testWidgets('a phone already asked is not asked again', (tester) async {
    final (push, tokens, _) = await open(tester, prefs: {pushAskedKey: true});
    expect(push.requests, 0);
    expect(tokens.registered, isEmpty, reason: 'the person did not allow it');
  });

  testWidgets('tapping a crew notification opens that trip', (tester) async {
    final (push, _, _) = await open(tester, trips: FakeTrips([trip('t1', driver: 'u1'), trip('t2', bus: 'b2', assistant: 'u1')]));
    push.tapped.add(const PushMessage(kind: 'crew_assigned', refId: 't2'));
    await settle(tester);
    expect(find.text('Bus B2'), findsWidgets, reason: 'the trip screen of t2');
    expect(find.text('Start trip'), findsOneWidget);
  });

  testWidgets('a crew notification while the app is open says so', (tester) async {
    final (push, _, _) = await open(tester);
    push.arrived.add(const PushMessage(kind: 'crew_assigned', refId: 't1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('You were added to a trip. It is in your trips.'), findsOneWidget);
    await settle(tester, 40);
  });

  testWidgets('signing out removes this phone from the notifications', (tester) async {
    final (push, tokens, auth) = await open(tester);
    await ProviderScope.containerOf(tester.element(find.byType(OpsApp))).read(signOutProvider)();
    await settle(tester);
    expect(tokens.unregistered, ['ops-phone-token']);
    expect(push.forgets, 1);
    expect(auth.signOuts, 1);
  });

  group('trips left running', () {
    test('a reminder opens its trip; End trip is told apart from opening it', () {
      expect(opsRouteForPush(const PushMessage(kind: tripReminderKind, refId: 't1')), Routes.trip('t1'));
      expect(opsRouteForPush(const PushMessage(kind: tripAtCampusKind, refId: 't1')), Routes.trip('t1'));
      expect(reminderChoice(const NotificationResponse(notificationResponseType: NotificationResponseType.selectedNotificationAction, actionId: endTripActionId, payload: 't1')),
          (tripId: 't1', end: true));
      expect(reminderChoice(const NotificationResponse(notificationResponseType: NotificationResponseType.selectedNotification, payload: 't1')), (tripId: 't1', end: false));
      expect(reminderChoice(const NotificationResponse(notificationResponseType: NotificationResponseType.selectedNotification)), isNull);
    });

    testWidgets('a reminder while the app is open is drawn with its End trip button, in the app language', (tester) async {
      final reminders = FakeReminders();
      final (push, _, _) = await open(tester, prefs: {pushAskedKey: true}, reminders: reminders);
      push.arrived.add(const PushMessage(kind: tripReminderKind, refId: 't1'));
      await settle(tester, 4);
      expect(reminders.shown.single.tripId, 't1');
      expect(reminders.shown.single.title, 'Is your trip over?');
      expect(reminders.shown.single.action, 'End trip');
    });

    testWidgets('End trip on a reminder ends the trip and says so', (tester) async {
      final reminders = FakeReminders();
      final trips = FakeTrips([trip('t1', driver: 'u1', status: TripStatus.active)]);
      await open(tester, prefs: {pushAskedKey: true}, trips: trips, reminders: reminders);
      reminders.tap((tripId: 't1', end: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(trips.ended, ['t1']);
      expect(find.text('Trip ended.'), findsOneWidget);
      await settle(tester, 40);
    });

    testWidgets('tapping the reminder itself opens the trip', (tester) async {
      final reminders = FakeReminders();
      await open(tester, prefs: {pushAskedKey: true}, trips: FakeTrips([trip('t1', driver: 'u1'), trip('t2', bus: 'b2', driver: 'u1')]), reminders: reminders);
      reminders.tap((tripId: 't2', end: false));
      await settle(tester);
      expect(find.text('Bus B2'), findsWidgets);
    });

    testWidgets('End trip pressed while the app was closed ends it once the app opens', (tester) async {
      final reminders = FakeReminders()..launched = (tripId: 't1', end: true);
      final trips = FakeTrips([trip('t1', driver: 'u1', status: TripStatus.active)]);
      await open(tester, prefs: {pushAskedKey: true}, trips: trips, reminders: reminders);
      expect(trips.ended, ['t1']);
      await settle(tester, 40);
    });
  
    testWidgets('reaching the campus is drawn the same way, with its own words and the End trip button', (tester) async {
      final reminders = FakeReminders();
      final (push, _, _) = await open(tester, prefs: {pushAskedKey: true}, reminders: reminders);
      push.arrived.add(const PushMessage(kind: tripAtCampusKind, refId: 't1'));
      await settle(tester, 4);
      expect(reminders.shown.single.title, 'You are at the campus');
      expect(reminders.shown.single.action, 'End trip');
    });
  });
}
