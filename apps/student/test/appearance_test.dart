import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/providers.dart';
import 'package:busin_student/src/settings/appearance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support.dart';

Future<SharedPreferences> prefs([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

Future<void> openProfile(WidgetTester tester, SharedPreferences store, {Locale systemLocale = const Locale('en'), Brightness system = Brightness.light}) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.localesTestValue = [systemLocale];
  tester.platformDispatcher.platformBrightnessTestValue = system;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        ...overridesFor(FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()})),
        appPreferencesProvider.overrideWithValue(store),
      ],
      child: const StudentApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(systemLocale.languageCode == 'fr' || store.getString('locale') == 'fr' ? 'Profil' : 'Profile'));
  await tester.pumpAndSettle();
}

Brightness shown(WidgetTester tester) => Theme.of(tester.element(find.byType(Scaffold).first)).brightness;

void main() {
  testWidgets('by default it follows the phone: theme and language', (tester) async {
    await openProfile(tester, await prefs(), system: Brightness.dark);
    expect(shown(tester), Brightness.dark);
    expect(find.text('Appearance'), findsOneWidget);
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.system);
  });

  testWidgets('choosing Light or Dark applies at once and is remembered', (tester) async {
    final store = await prefs();
    await openProfile(tester, store, system: Brightness.light);
    expect(shown(tester), Brightness.light);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(shown(tester), Brightness.dark);
    expect(store.getString('theme_mode'), 'dark');

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(shown(tester), Brightness.light);
    expect(store.getString('theme_mode'), 'light');

    await tester.tap(find.text('System').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(store.containsKey('theme_mode'), isFalse, reason: 'following the phone is stored as nothing');
  });

  testWidgets('choosing a language changes the words at once and is remembered', (tester) async {
    final store = await prefs();
    await openProfile(tester, store);
    expect(find.text('Appearance'), findsOneWidget);

    await tester.tap(find.text('Français'));
    await tester.pumpAndSettle();
    expect(find.text('Apparence'), findsOneWidget);
    expect(find.text('Appearance'), findsNothing);
    expect(store.getString('locale'), 'fr');

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);
    expect(store.getString('locale'), 'en');

    await tester.tap(find.text('System').last);
    await tester.pumpAndSettle();
    expect(store.containsKey('locale'), isFalse);
  });

  testWidgets('what was chosen last time is there from the first frame, whatever the phone says', (tester) async {
    await openProfile(tester, await prefs({'theme_mode': 'dark', 'locale': 'fr'}), system: Brightness.light);
    expect(shown(tester), Brightness.dark);
    expect(find.text('Apparence'), findsOneWidget);
  });

  testWidgets('a language the app does not speak is ignored', (tester) async {
    final container = ProviderContainer(overrides: [appPreferencesProvider.overrideWithValue(await prefs({'locale': 'de'}))]);
    addTearDown(container.dispose);
    expect(container.read(localeProvider), isNull);
  });

  test('notifications come in the language chosen on the profile, else the phone\'s', () async {
    final container = ProviderContainer(overrides: [appPreferencesProvider.overrideWithValue(await prefs())]);
    addTearDown(container.dispose);
    final phone = container.read(languageCodeProvider)();
    container.read(localeProvider.notifier).choose(const Locale('fr'));
    expect(container.read(languageCodeProvider)(), 'fr');
    container.read(localeProvider.notifier).choose(null);
    expect(container.read(languageCodeProvider)(), phone);
  });

  testWidgets('the profile with the new card fits a small phone at large text in French', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openProfile(tester, await prefs({'locale': 'fr'}));
    await tester.scrollUntilVisible(find.text('Apparence'), 200, scrollable: find.byType(Scrollable).first);
    expect(tester.takeException(), isNull);
  });
}
