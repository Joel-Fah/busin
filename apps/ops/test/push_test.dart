import 'dart:async';

import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:busin_ops/src/app.dart';
import 'package:busin_ops/src/providers.dart';
import 'package:busin_ops/src/push/push_binder.dart';
import 'package:busin_ops/src/router.dart';
import 'package:flutter/material.dart';
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

  Future<(FakePush, FakeTokens, FakeAuth)> open(WidgetTester tester, {Map<String, Object> prefs = const {}, FakeTrips? trips}) async {
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
}
