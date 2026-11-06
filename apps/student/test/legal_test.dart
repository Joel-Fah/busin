import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/legal/legal_documents.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

final _emoji = RegExp(r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}]', unicode: true);

Future<void> openProfile(WidgetTester tester, {Locale locale = const Locale('en'), Size size = const Size(800, 1800)}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: overridesFor(FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()}), backend: FakeBackend(current: semester())),
      child: const StudentApp(),
    ),
  );
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  BusinToast.dismiss();
  await tester.tap(find.text(locale.languageCode == 'fr' ? 'Profil' : 'Profile'));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  group('the documents', () {
    for (final doc in LegalDoc.values) {
      test('${doc.name}: both languages have the same shape, real text and no emoji', () {
        final en = legalDocument(doc, 'en');
        final fr = legalDocument(doc, 'fr');
        expect(fr.sections.length, en.sections.length, reason: 'the French text covers the same parts');
        expect(fr.highlights.length, en.highlights.length);
        for (final document in [en, fr]) {
          expect(document.highlights, isNotEmpty);
          expect(document.minutes, inInclusiveRange(1, 10));
          for (final section in document.sections) {
            expect(section.title.trim(), isNotEmpty);
            expect(section.paragraphs.isNotEmpty || section.bullets.isNotEmpty, isTrue, reason: section.title);
            expect(_emoji.hasMatch([section.title, ...section.paragraphs, ...section.bullets].join(' ')), isFalse);
          }
        }
      });
    }

    test('no document names a school: the page says which school it applies to', () {
      for (final doc in LegalDoc.values) {
        for (final lang in ['en', 'fr']) {
          final d = legalDocument(doc, lang);
          final all = [...d.highlights, for (final s in d.sections) ...[s.title, ...s.paragraphs, ...s.bullets]].join(' ');
          expect(all.contains('ICT'), isFalse, reason: '$doc $lang');
        }
      }
    });
  });

  group('in the app', () {
    testWidgets('the profile lists the three documents and one opens as a page with the first part open', (tester) async {
      await openProfile(tester);
      await tester.scrollUntilVisible(find.text('Privacy policy'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Terms of use'), findsOneWidget);
      expect(find.text('Acceptable use'), findsOneWidget);

      await tester.tap(find.text('Privacy policy'));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('In short'), findsOneWidget);
      expect(find.textContaining('Updated'), findsOneWidget);
      expect(find.text('What we keep'), findsOneWidget);
      // The first part is open, the second is closed.
      expect(find.textContaining('Your name, school email'), findsOneWidget);
      expect(find.textContaining('To let your school review'), findsNothing);

      await tester.tap(find.text('Why we keep it'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.textContaining('To let your school review'), findsOneWidget);
    });

    testWidgets('from a document the other two are one tap away, and back returns to the profile', (tester) async {
      await openProfile(tester);
      await tester.scrollUntilVisible(find.text('Terms of use'), 300, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Terms of use'));
      await tester.pump(const Duration(milliseconds: 800));

      await tester.scrollUntilVisible(find.text('Also read'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Privacy policy'), findsOneWidget);
      expect(find.text('Terms of use'), findsWidgets);
      await tester.tap(find.text('Privacy policy'));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('What we keep'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('Edit details'), findsOneWidget, reason: 'back goes to the profile, not to the document it replaced');
    });

    testWidgets('in French the profile and the page speak French', (tester) async {
      await openProfile(tester, locale: const Locale('fr'));
      await tester.scrollUntilVisible(find.text('Politique de confidentialité'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Conditions d’utilisation'), findsOneWidget);
      await tester.tap(find.text('Politique de confidentialité'));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('En bref'), findsOneWidget);
      expect(find.text('Ce que nous gardons'), findsOneWidget);
    });

    testWidgets('on a phone with large text the page does not overflow', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openProfile(tester, size: const Size(360, 740));
      await tester.scrollUntilVisible(find.text('Acceptable use'), 300, scrollable: find.byType(Scrollable).first);
      // The last row can sit under the floating bar; the first one is clear of it.
      await tester.ensureVisible(find.text('Terms of use'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Terms of use'));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('In short'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
