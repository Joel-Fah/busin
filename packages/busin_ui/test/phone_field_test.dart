import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The country and phone field (ADR 0024): one row, a searchable country list, the number written the country's way,
// and a pasted full number picks its country.
void main() {
  Widget host(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
        theme: BusinTheme.light(),
        locale: locale,
        localizationsDelegates: BusinL10n.localizationsDelegates,
        supportedLocales: BusinL10n.supportedLocales,
        home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
      );

  Widget field(TextEditingController controller, ValueNotifier<String> country) => ValueListenableBuilder<String>(
        valueListenable: country,
        builder: (context, code, _) => BusinPhoneField(
          label: 'Phone',
          hint: 'Type your number',
          controller: controller,
          country: code,
          onCountryChanged: (c) => country.value = c,
        ),
      );

  testWidgets('the number is written the country way as it is typed', (tester) async {
    final controller = TextEditingController();
    final country = ValueNotifier('CM');
    await tester.pumpWidget(host(field(controller, country)));
    expect(find.text('+237'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '677123456');
    expect(controller.text, '6 77 12 34 56');
    expect(PhoneNumbers.parse(controller.text, country.value).e164, '+237677123456');
  });

  testWidgets('a country is found by search, in the app language, and the digits follow it', (tester) async {
    final controller = TextEditingController(text: '612345678');
    final country = ValueNotifier('CM');
    await tester.pumpWidget(host(field(controller, country), locale: const Locale('fr')));
    await tester.tap(find.text('+237'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'allem');
    await tester.pumpAndSettle();
    expect(find.text('Allemagne'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'fran');
    await tester.pumpAndSettle();
    await tester.tap(find.text('France'));
    await tester.pumpAndSettle();
    expect(country.value, 'FR');
    expect(find.text('+33'), findsOneWidget);
    expect(controller.text, '6 12 34 56 78');
  });

  testWidgets('a number pasted with its code picks its country', (tester) async {
    final controller = TextEditingController();
    final country = ValueNotifier('CM');
    await tester.pumpWidget(host(field(controller, country)));
    await tester.enterText(find.byType(TextField), '+44 7400 123456');
    await tester.pump();
    expect(country.value, 'GB');
    expect(controller.text, '7400 123456');
    expect(find.text('+44'), findsOneWidget);
  });

  testWidgets('country and number stay on one row on a small phone with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(1.6)),
      child: host(field(TextEditingController(), ValueNotifier('CM'))),
    ));
    expect(tester.takeException(), isNull);
    final button = tester.getRect(find.text('+237'));
    final input = tester.getRect(find.byType(TextField));
    expect(button.right, lessThan(input.left), reason: 'side by side');
    expect((button.center.dy - input.center.dy).abs(), lessThan(24));
  });
}
