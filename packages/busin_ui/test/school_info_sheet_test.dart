import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const school = School(
  id: 's1',
  name: 'ICT University',
  shortName: 'ICTU',
  timezone: 'Africa/Douala',
  isActive: true,
  about: 'A university in Yaounde.',
  address: 'Messassi',
  city: 'Yaounde',
  country: 'Cameroon',
  contactEmail: 'info@ictu.example',
  phone: '+237677123456',
  phoneSecondary: '+237699000111',
  website: 'https://ictu.example',
);

Widget host({required List<Uri> opened, bool opens = true, School of = school, Locale locale = const Locale('en')}) => MaterialApp(
      theme: BusinTheme.light(),
      locale: locale,
      localizationsDelegates: businLocalizationsDelegates,
      supportedLocales: businSupportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: SchoolBadge(
              school: of,
              supabaseUrl: 'http://localhost',
              onTap: () => showSchoolInfoSheet(context, school: of, supabaseUrl: 'http://localhost', open: (uri) async {
                opened.add(uri);
                return opens;
              }),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('tapping the school opens what the admin wrote, and email, phones and website open their apps', (tester) async {
    final opened = <Uri>[];
    await tester.pumpWidget(host(opened: opened));
    await tester.tap(find.text('ICT University'));
    await tester.pumpAndSettle();

    expect(find.text('A university in Yaounde.'), findsOneWidget);
    expect(find.text('Messassi, Yaounde, Cameroon'), findsOneWidget);
    expect(find.text('ictu.example'), findsOneWidget);

    await tester.tap(find.text('info@ictu.example'));
    await tester.tap(find.text(PhoneNumbers.display('+237677123456')));
    await tester.tap(find.text(PhoneNumbers.display('+237699000111')));
    await tester.tap(find.text('ictu.example'));
    await tester.pump();
    expect(opened.map((u) => u.toString()), ['mailto:info@ictu.example', 'tel:+237677123456', 'tel:+237699000111', 'https://ictu.example']);
  });

  testWidgets('the country follows the app language, and a link nothing can open says so', (tester) async {
    final opened = <Uri>[];
    await tester.pumpWidget(host(opened: opened, opens: false, locale: const Locale('fr')));
    await tester.tap(find.text('ICT University'));
    await tester.pumpAndSettle();
    expect(find.text('Messassi, Yaounde, Cameroun'), findsOneWidget);
    await tester.tap(find.text('info@ictu.example'));
    await tester.pump();
    expect(find.text('Aucune application de ce téléphone ne peut ouvrir ceci.'), findsOneWidget);
    BusinToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('a school without details says so', (tester) async {
    await tester.pumpWidget(host(opened: [], of: const School(id: 's2', name: 'New School', timezone: 'UTC', isActive: true)));
    await tester.tap(find.text('New School'));
    await tester.pumpAndSettle();
    expect(find.text('The school has not added its details yet.'), findsOneWidget);
  });
}
