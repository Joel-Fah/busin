import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/providers.dart';
import 'package:busin_student/src/push/push_registrar.dart';
import 'package:busin_student/src/push/push_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support.dart';

PushRegistrar registrar(FakePushService push, FakeDeviceTokens tokens, {String language = 'en', TargetPlatform platform = TargetPlatform.android}) =>
    PushRegistrar(push: push, tokens: tokens, languageCode: () => language, platform: platform);

Future<void> openApp(
  WidgetTester tester, {
  FakePushService? push,
  FakeDeviceTokens? tokens,
  FakeBackend? backend,
  Locale locale = const Locale('en'),
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: overridesFor(
        FakeAuthService(signedInAs: 'u1'),
        FakeProfileRepository({'u1': profile()}),
        push: push,
        deviceTokens: tokens,
        backend: backend ?? FakeBackend(current: semester(), mine: [subscription()]),
        languageCode: locale.languageCode,
      ),
      child: const StudentApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('routeForPush', () {
    test('subscription decisions open the subscription tab', () {
      expect(routeForPush(const PushMessage(kind: 'subscription_approved')), '/subscription');
      expect(routeForPush(const PushMessage(kind: 'subscription_rejected', refId: 'x')), '/subscription');
    });
    test('a kind this version does not know goes nowhere', () => expect(routeForPush(const PushMessage(kind: 'something_new')), isNull));
  });

  group('PushRegistrar', () {
    test('registers the token with the platform and the phone\'s language when notifications are already allowed', () async {
      final push = FakePushService(current: PushPermission.granted);
      final tokens = FakeDeviceTokens();
      await registrar(push, tokens, language: 'fr').syncIfAllowed();
      expect(tokens.registered.single.token, 'fcm-token-of-this-phone-0001');
      expect(tokens.registered.single.platform, 'android');
      expect(tokens.registered.single.locale, 'fr');
      expect(push.requests, 0, reason: 'syncing never asks');
    });

    test('an iPhone says ios, and any language but French is English', () async {
      final push = FakePushService(current: PushPermission.granted);
      final tokens = FakeDeviceTokens();
      await registrar(push, tokens, language: 'de', platform: TargetPlatform.iOS).syncIfAllowed();
      expect(tokens.registered.single.platform, 'ios');
      expect(tokens.registered.single.locale, 'en');
    });

    test('does nothing when not allowed, not asked, or Firebase is not set up', () async {
      for (final push in [FakePushService(current: PushPermission.notAsked), FakePushService(current: PushPermission.denied), FakePushService(available: false, current: PushPermission.granted)]) {
        final tokens = FakeDeviceTokens();
        await registrar(push, tokens).syncIfAllowed();
        expect(tokens.registered, isEmpty);
        expect(push.requests, 0);
      }
    });

    test('a failing server never breaks the app', () async {
      final tokens = FakeDeviceTokens()..error = const Offline('down');
      await registrar(FakePushService(current: PushPermission.granted), tokens).syncIfAllowed();
      expect(await registrar(FakePushService(), tokens).enable(), PushPermission.granted);
    });

    test('enable asks, and registers only if the answer is yes', () async {
      final yes = FakePushService();
      final yesTokens = FakeDeviceTokens();
      expect(await registrar(yes, yesTokens).enable(), PushPermission.granted);
      expect(yes.requests, 1);
      expect(yesTokens.registered, hasLength(1));

      final no = FakePushService(onRequest: PushPermission.denied);
      final noTokens = FakeDeviceTokens();
      expect(await registrar(no, noTokens).enable(), PushPermission.denied);
      expect(noTokens.registered, isEmpty);

      expect(await registrar(FakePushService(available: false), FakeDeviceTokens()).enable(), PushPermission.denied);
    });

    test('a replaced token is registered', () async {
      final tokens = FakeDeviceTokens();
      await registrar(FakePushService(), tokens).tokenChanged('a-brand-new-fcm-token-0002');
      expect(tokens.registered.single.token, 'a-brand-new-fcm-token-0002');
    });

    test('forgetting removes the registered token from the server and throws the phone\'s token away', () async {
      final push = FakePushService();
      final tokens = FakeDeviceTokens();
      final r = registrar(push, tokens);
      await r.enable();
      await r.forget();
      expect(tokens.unregistered, ['fcm-token-of-this-phone-0001']);
      expect(push.forgets, 1);
    });

    test('forgetting still throws the token away when the server cannot be reached', () async {
      final push = FakePushService(current: PushPermission.granted);
      final tokens = FakeDeviceTokens()..error = const Offline('down');
      await registrar(push, tokens).forget();
      expect(push.forgets, 1);
    });

    test('forgetting does nothing without Firebase', () async {
      final push = FakePushService(available: false);
      final tokens = FakeDeviceTokens();
      await registrar(push, tokens).forget();
      expect(push.forgets, 0);
      expect(tokens.unregistered, isEmpty);
    });
  });

  testWidgets('a student who already allowed notifications is registered on entering the app, without being asked', (tester) async {
    final push = FakePushService(current: PushPermission.granted);
    final tokens = FakeDeviceTokens();
    await openApp(tester, push: push, tokens: tokens);
    expect(tokens.registered, hasLength(1));
    expect(push.requests, 0);
  });

  testWidgets('nothing is asked at launch: a student who has not decided is left alone until they have a request to wait for', (tester) async {
    final push = FakePushService();
    final tokens = FakeDeviceTokens();
    await openApp(tester, push: push, tokens: tokens, backend: FakeBackend(current: semester()));
    expect(push.requests, 0);
    expect(tokens.registered, isEmpty);
    expect(find.text('Get notified'), findsNothing, reason: 'no request yet, so nothing to wait for');
  });

  testWidgets('with a pending request the student is offered notifications, and turning them on asks and registers', (tester) async {
    final push = FakePushService();
    final tokens = FakeDeviceTokens();
    await openApp(tester, push: push, tokens: tokens);

    expect(find.text('Get notified'), findsOneWidget);
    expect(push.requests, 0, reason: 'offering is not asking');
    await tester.tap(find.text('Turn on notifications'));
    await tester.pumpAndSettle();

    expect(push.requests, 1);
    expect(tokens.registered, hasLength(1));
    expect(find.text('Get notified'), findsNothing);
  });

  testWidgets('if the system says no the card says how to change that, and nothing is registered', (tester) async {
    final push = FakePushService(onRequest: PushPermission.denied);
    final tokens = FakeDeviceTokens();
    await openApp(tester, push: push, tokens: tokens);
    await tester.tap(find.text('Turn on notifications'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Notifications are off'), findsOneWidget);
    expect(find.text('Turn on notifications'), findsNothing);
    expect(tokens.registered, isEmpty);
  });

  testWidgets('"Not now" hides the offer for good', (tester) async {
    final push = FakePushService();
    await openApp(tester, push: push);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('Get notified'), findsNothing);
    expect(push.requests, 0);

    // Reopened with the same stored choice (the preferences are kept across the two runs).
    tester.view.physicalSize = const Size(800, 1800);
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: overridesFor(FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()}), push: push, backend: FakeBackend(current: semester(), mine: [subscription()])),
        child: const StudentApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Request sent'), findsOneWidget);
    expect(find.text('Get notified'), findsNothing);
  });

  testWidgets('the offer is not shown without Firebase, once allowed, or once the request is decided', (tester) async {
    await openApp(tester, push: FakePushService(available: false));
    expect(find.text('Get notified'), findsNothing);

    await openApp(tester, push: FakePushService(current: PushPermission.granted));
    expect(find.text('Get notified'), findsNothing);

    await openApp(tester, push: FakePushService(), backend: FakeBackend(current: semester(), mine: [subscription(status: SubscriptionStatus.approved)]));
    expect(find.text('Get notified'), findsNothing);
  });

  testWidgets('tapping a notification opens the subscription tab with the new status', (tester) async {
    final push = FakePushService();
    final backend = FakeBackend(current: semester(), mine: [subscription()]);
    await openApp(tester, push: push, backend: backend);
    expect(find.text('Request sent'), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    backend.mine[0] = subscription(status: SubscriptionStatus.approved);
    push.tapped.add(const PushMessage(kind: 'subscription_approved', refId: 'sub1'));
    await tester.pumpAndSettle();

    expect(find.text('You are subscribed'), findsOneWidget, reason: 'it went to the subscription tab and reloaded');
  });

  testWidgets('a notification that arrives while the app is open refreshes the status and says so', (tester) async {
    final push = FakePushService();
    final backend = FakeBackend(current: semester(), mine: [subscription()]);
    await openApp(tester, push: push, backend: backend);

    backend.mine[0] = subscription(status: SubscriptionStatus.approved);
    push.arrived.add(const PushMessage(kind: 'subscription_approved'));
    await tester.pumpAndSettle();

    expect(find.text('Your subscription was approved.'), findsOneWidget);
    expect(find.text('You are subscribed'), findsOneWidget);
  });

  testWidgets('a kind this version does not know changes nothing and shows nothing', (tester) async {
    final push = FakePushService();
    await openApp(tester, push: push);
    push.arrived.add(const PushMessage(kind: 'something_new'));
    push.tapped.add(const PushMessage(kind: 'something_new'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Request sent'), findsOneWidget);
  });

  testWidgets('a replaced token is passed on to the server while the app is open', (tester) async {
    final push = FakePushService(current: PushPermission.granted);
    final tokens = FakeDeviceTokens();
    await openApp(tester, push: push, tokens: tokens);
    push.refreshes.add('a-brand-new-fcm-token-0002');
    await tester.pumpAndSettle();
    expect(tokens.registered.map((t) => t.token), ['fcm-token-of-this-phone-0001', 'a-brand-new-fcm-token-0002']);
  });

  testWidgets('the offer speaks French, and the token is registered with French wording', (tester) async {
    final push = FakePushService(current: PushPermission.granted);
    final tokens = FakeDeviceTokens();
    await openApp(tester, push: push, tokens: tokens, locale: const Locale('fr'));
    expect(tokens.registered.single.locale, 'fr');

    await openApp(tester, push: FakePushService(), locale: const Locale('fr'));
    expect(find.text('Soyez prévenu'), findsOneWidget);
  });

  test('signing out removes this phone from the server before the session ends', () async {
    final auth = FakeAuthService(signedInAs: 'u1');
    final push = FakePushService();
    final tokens = FakeDeviceTokens();
    final container = ProviderContainer(overrides: overridesFor(auth, FakeProfileRepository({'u1': profile()}), push: push, deviceTokens: tokens));
    addTearDown(container.dispose);

    await container.read(pushRegistrarProvider).enable();
    await container.read(signOutProvider)();

    expect(tokens.unregistered, ['fcm-token-of-this-phone-0001']);
    expect(push.forgets, 1);
    expect(auth.signOuts, 1);
  });
}
