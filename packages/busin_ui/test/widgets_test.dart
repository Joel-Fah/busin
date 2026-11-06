import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

Widget app(Widget child, {ThemeData? theme, Locale locale = const Locale('en')}) => MaterialApp(
      theme: theme ?? BusinTheme.light(),
      locale: locale,
      localizationsDelegates: businLocalizationsDelegates,
      supportedLocales: businSupportedLocales,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('BusinButton', () {
    testWidgets('labels are bold in both themes, in every variant', (tester) async {
      for (final theme in [BusinTheme.light(), BusinTheme.dark()]) {
        for (final variant in BusinButtonVariant.values) {
          await tester.pumpWidget(app(BusinButton(label: 'Save', variant: variant, onPressed: () {}), theme: theme));
          expect(tester.widget<Text>(find.text('Save')).style?.fontWeight, FontWeight.w700, reason: '$variant');
        }
      }
    });

    testWidgets('calls back when pressed', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(app(BusinButton(label: 'Save', onPressed: () => pressed++)));
      await tester.tap(find.text('Save'));
      expect(pressed, 1);
    });

    testWidgets('does nothing while loading, and shows progress', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(app(BusinButton(label: 'Save', loading: true, onPressed: () => pressed++)));
      await tester.tap(find.text('Save'), warnIfMissed: false);
      expect(pressed, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('is disabled without a callback', (tester) async {
      await tester.pumpWidget(app(const BusinButton(label: 'Save', onPressed: null)));
      expect(tester.widget<InkWell>(find.descendant(of: find.byType(BusinButton), matching: find.byType(InkWell))).onTap, isNull);
    });

    testWidgets('every variant draws in light and dark', (tester) async {
      for (final theme in [BusinTheme.light(), BusinTheme.dark()]) {
        for (final variant in BusinButtonVariant.values) {
          await tester.pumpWidget(app(
            BusinButton(label: variant.name, variant: variant, icon: HugeIcons.strokeRoundedTick02, onPressed: () {}),
            theme: theme,
          ));
          expect(find.text(variant.name), findsOneWidget);
        }
      }
    });

    testWidgets('can fill the width', (tester) async {
      await tester.pumpWidget(app(SizedBox(width: 300, child: BusinButton(label: 'Wide', expand: true, onPressed: () {}))));
      expect(tester.getSize(find.byType(BusinButton)).width, 300);
    });
  });

  group('BusinTextField', () {
    testWidgets('has its label above, a placeholder, a leading icon and reports typing', (tester) async {
      String? typed;
      await tester.pumpWidget(app(BusinTextField(
        label: 'Search',
        hint: 'Search by name',
        icon: HugeIcons.strokeRoundedSearch01,
        onChanged: (v) => typed = v,
      )));
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Search by name'), findsOneWidget);
      expect(find.byType(HugeIcon), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'ada');
      expect(typed, 'ada');
    });

    testWidgets('shows an error message', (tester) async {
      await tester.pumpWidget(app(const BusinTextField(
        label: 'Name',
        hint: 'Your name',
        icon: HugeIcons.strokeRoundedUser,
        errorText: 'This field is required.',
      )));
      expect(find.text('This field is required.'), findsOneWidget);
    });
  });

  group('StatusChip and avatar', () {
    testWidgets('a chip always carries its label', (tester) async {
      for (final tone in StatusTone.values) {
        await tester.pumpWidget(app(StatusChip(label: 'Approved', tone: tone)));
        expect(find.text('Approved'), findsOneWidget);
      }
    });

    testWidgets('an avatar without a picture shows initials', (tester) async {
      await tester.pumpWidget(app(const UserAvatar(name: 'Ada Lovelace')));
      expect(find.text('AL'), findsOneWidget);
    });

    testWidgets('with a picture address the initials wait underneath, and stay if the picture cannot load', (tester) async {
      // The network is not available in tests, so the picture fails: the initials must still be there.
      await tester.pumpWidget(app(const UserAvatar(name: 'Ada Lovelace', imageUrl: 'https://example.invalid/ada.jpg')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('AL'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an avatar is hidden from screen readers unless given a label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app(const UserAvatar(name: 'Ada Lovelace')));
      expect(find.bySemanticsLabel('Picture of Ada Lovelace'), findsNothing);
      await tester.pumpWidget(app(const UserAvatar(name: 'Ada Lovelace', semanticLabel: 'Picture of Ada Lovelace')));
      expect(find.bySemanticsLabel('Picture of Ada Lovelace'), findsOneWidget);
      handle.dispose();
    });
  });

  group('StatCard and EmptyState', () {
    testWidgets('a stat card reads its value before its label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app(const StatCard(label: 'Trips today', value: '12')));
      expect(find.bySemanticsLabel('12 Trips today'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('an empty state shows its title, text and action', (tester) async {
      var retried = false;
      await tester.pumpWidget(app(EmptyState(
        title: 'Nothing here yet',
        body: 'Add the first one.',
        icon: HugeIcons.strokeRoundedBus01,
        action: BusinButton(label: 'Try again', variant: BusinButtonVariant.secondary, onPressed: () => retried = true),
      )));
      expect(find.text('Nothing here yet'), findsOneWidget);
      expect(find.text('Add the first one.'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retried, isTrue);
    });
  });

  group('words and tones', () {
    testWidgets('names things the same way in English and French', (tester) async {
      late BusinL10n en;
      late BusinL10n fr;
      await tester.pumpWidget(app(Builder(builder: (c) {
        en = BusinL10n.of(c);
        return const SizedBox();
      })));
      await tester.pumpWidget(app(
        Builder(builder: (c) {
          fr = BusinL10n.of(c);
          return const SizedBox();
        }),
        locale: const Locale('fr'),
      ));

      expect(en.direction(TripDirection.inbound), 'Going to school');
      expect(en.direction(TripDirection.outbound), 'Going home');
      expect(fr.direction(TripDirection.inbound), "Vers l'école");
      expect(en.role(UserRole.admin), 'Administrator');
      expect(fr.role(UserRole.admin), 'Administrateur');
      expect(en.semester(SemesterName.fall, 2026), 'Fall 2026');
      expect(fr.semester(SemesterName.summer, 2026), 'Été 2026');
      expect(en.subscriptionStatus(SubscriptionStatus.approved), 'Approved');
      expect(fr.tripStatus(TripStatus.active), 'En cours');
      expect(en.accountStatus(AccountStatus.verified), 'Active');
    });

    testWidgets('a failure becomes a message in the person\'s language', (tester) async {
      late BusinL10n en;
      await tester.pumpWidget(app(Builder(builder: (c) {
        en = BusinL10n.of(c);
        return const SizedBox();
      })));
      expect(en.failure(const Offline('x')), en.errorOffline);
      expect(en.failure(const NotAllowed('x')), en.errorNotAllowed);
      expect(en.failure(const NotFound('x')), en.errorNotFound);
      expect(en.failure(const Unexpected('x')), en.errorGeneric);
      expect(en.failure(const Conflict('x')), en.errorGeneric);
    });

    test('statuses take the tones the portal gives them', () {
      expect(subscriptionTone(SubscriptionStatus.pending), StatusTone.warn);
      expect(subscriptionTone(SubscriptionStatus.approved), StatusTone.ok);
      expect(subscriptionTone(SubscriptionStatus.rejected), StatusTone.bad);
      expect(tripTone(TripStatus.active), StatusTone.ok);
      expect(tripTone(TripStatus.scheduled), StatusTone.info);
      expect(accountTone(AccountStatus.suspended), StatusTone.bad);
    });
  });
}
