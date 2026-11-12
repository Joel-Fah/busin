import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/subscription/proof_picker.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

Future<void> open(
  WidgetTester tester,
  FakeBackend backend, {
  FakeProofPicker? picker,
  Locale locale = const Locale('en'),
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: overridesFor(FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()}), backend: backend, picker: picker),
      child: const StudentApp(),
    ),
  );
  await tester.pumpAndSettle();
  // A student with an approved subscription opens on the boarding code; these tests look at the subscription tab.
  if (find.text('Boarding code').evaluate().isNotEmpty) {
    await tester.tap(find.text('Subscription').first);
    await tester.pumpAndSettle();
  }
}

bool sendEnabled(WidgetTester tester) => tester.widget<BusinButton>(find.widgetWithText(BusinButton, 'Send request')).onPressed != null;

Future<void> chooseStop(WidgetTester tester, String name) async {
  await tester.tap(find.text('Your stop'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

Future<void> choosePhoto(WidgetTester tester) async {
  await tester.tap(find.text('Payment proof'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Choose from gallery'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('with no semester there is nothing to subscribe to, and it says so', (tester) async {
    await open(tester, FakeBackend());
    expect(find.text('No semester open yet'), findsOneWidget);
    expect(find.text('Send request'), findsNothing);
  });

  testWidgets('the semester is chosen by the school day, not the phone', (tester) async {
    final backend = FakeBackend(current: semester());
    await open(tester, backend);
    // The fake clock reads the real now; what matters is that the repository got a plain date.
    final asked = backend.askedToday!;
    expect((asked.hour, asked.minute, asked.second), (0, 0, 0));
  });

  testWidgets('an upcoming semester can already be subscribed to, and says when it starts', (tester) async {
    await open(tester, FakeBackend(next: semester(start: '2030-09-01', end: '2031-01-31')));
    expect(find.textContaining('Subscribe for Fall 2026'), findsOneWidget);
    expect(find.textContaining('Starts'), findsOneWidget);
  });

  testWidgets('Send stays off until a stop and a photo are chosen, then sends both and shows the pending request', (tester) async {
    final backend = FakeBackend(current: semester());
    final picker = FakeProofPicker(samplePhoto());
    await open(tester, backend, picker: picker);

    expect(find.text('Subscribe for Fall 2026'), findsOneWidget);
    expect(sendEnabled(tester), isFalse);

    await chooseStop(tester, 'Carrefour Vogt');
    expect(find.text('Carrefour Vogt'), findsOneWidget);
    expect(sendEnabled(tester), isFalse, reason: 'a stop alone is not enough');

    await choosePhoto(tester);
    expect(picker.asked, [ProofSource.gallery]);
    expect(find.text('Photo added'), findsOneWidget);
    expect(sendEnabled(tester), isTrue);

    await tester.tap(find.text('Send request'));
    await tester.pumpAndSettle();

    expect(backend.uploads, hasLength(1));
    final sent = backend.requests.single;
    expect(sent.studentId, 'u1');
    expect(sent.schoolId, 's1');
    expect(sent.semesterId, 'sem1');
    expect(sent.stopId, 'stop2');
    expect(sent.proofPath, 's1/u1/file1.jpg', reason: 'the request carries the path the upload returned');

    expect(find.text('Request sent'), findsOneWidget);
    expect(find.text('Pending'), findsWidgets);
    expect(find.text('Carrefour Vogt'), findsOneWidget);
    expect(find.text('Send request'), findsNothing);
  });

  testWidgets('a form left open after the semester ended sends nothing and says so', (tester) async {
    // The fake clock reads the real now; this semester ended long ago.
    final backend = FakeBackend(current: semester(start: '2020-09-01', end: '2021-01-31'));
    final picker = FakeProofPicker(samplePhoto());
    await open(tester, backend, picker: picker);
    await chooseStop(tester, 'Carrefour Vogt');
    await choosePhoto(tester);
    await tester.tap(find.text('Send request'));
    await tester.pumpAndSettle();

    expect(backend.requests, isEmpty, reason: 'nothing is sent for a semester that is over');
    expect(backend.uploads, isEmpty, reason: 'and no photo is uploaded for it');
    expect(find.text('This semester has ended. Pull down to refresh and see what is open now.'), findsOneWidget);
  });

  testWidgets('the stop sheet can be searched', (tester) async {
    await open(tester, FakeBackend(current: semester()));
    await tester.tap(find.text('Your stop'));
    await tester.pumpAndSettle();
    expect(find.text('Olezoa'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'nsim');
    await tester.pumpAndSettle();
    expect(find.text('Shell Nsimeyong'), findsOneWidget);
    expect(find.text('Olezoa'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No stop matches.'), findsOneWidget);
  });

  testWidgets('backing out of the camera or gallery changes nothing', (tester) async {
    await open(tester, FakeBackend(current: semester()), picker: FakeProofPicker(null));
    await choosePhoto(tester);
    expect(find.text('Photo added'), findsNothing);
    expect(find.text('Add a clear photo of your receipt'), findsOneWidget);
  });

  testWidgets('a file that is not a usable photo is explained and not kept', (tester) async {
    final picker = FakeProofPicker()..error = const ProofException(ProofProblem.type);
    await open(tester, FakeBackend(current: semester()), picker: picker);
    await choosePhoto(tester);
    expect(find.text('Use a JPEG, PNG or WebP photo.'), findsOneWidget);

    picker.error = const ProofException(ProofProblem.tooLarge);
    await choosePhoto(tester);
    expect(find.text('That photo is too large. Pick one under 5 MB.'), findsOneWidget);
    expect(sendEnabled(tester), isFalse);
  });

  testWidgets('each way sending can fail is explained, and the form is kept to try again', (tester) async {
    final cases = <(Object, String)>[
      (const Conflict('x'), 'You already have a request for this semester. Pull down to refresh.'),
      (const Offline('x'), 'No connection. Check your network and try again.'),
      (const Unexpected('x'), 'Something went wrong. Try again.'),
    ];
    for (final (error, message) in cases) {
      final backend = FakeBackend(current: semester())..requestError = error;
      await open(tester, backend, picker: FakeProofPicker(samplePhoto()));
      await chooseStop(tester, 'Carrefour Vogt');
      await choosePhoto(tester);
      await tester.tap(find.text('Send request'));
      await tester.pumpAndSettle();

      expect(find.text(message), findsOneWidget, reason: '$error');
      expect(sendEnabled(tester), isTrue, reason: 'the choices are kept so one tap retries');
      expect(find.text('Request sent'), findsNothing);
    }
  });

  testWidgets('a failed upload sends no request', (tester) async {
    final backend = FakeBackend(current: semester())..uploadError = const Offline('x');
    await open(tester, backend, picker: FakeProofPicker(samplePhoto()));
    await chooseStop(tester, 'Carrefour Vogt');
    await choosePhoto(tester);
    await tester.tap(find.text('Send request'));
    await tester.pumpAndSettle();

    expect(backend.requests, isEmpty);
    expect(find.text('No connection. Check your network and try again.'), findsOneWidget);
  });

  testWidgets('a pending request shows where it stands, with its stop and no form', (tester) async {
    await open(tester, FakeBackend(current: semester(), mine: [subscription(stopId: 'stop3', proofPath: 's1/u1/a.jpg')]));
    expect(find.text('Request sent'), findsOneWidget);
    expect(find.text('Olezoa'), findsOneWidget);
    expect(find.textContaining('checking your payment proof'), findsOneWidget);
    expect(find.text('Send request'), findsNothing);
  });

  testWidgets('an approved subscription says where to board and leads to the boarding code', (tester) async {
    await open(tester, FakeBackend(current: semester(), mine: [subscription(status: SubscriptionStatus.approved)]));
    expect(find.text('You are subscribed'), findsOneWidget);
    expect(find.text('You can board at Shell Nsimeyong.'), findsOneWidget);

    await tester.tap(find.text('Show boarding code'));
    await tester.pumpAndSettle();
    expect(find.text('Your boarding code. It changes every 30 seconds.').evaluate(), isEmpty, reason: 'the image label is a semantics label, not text');
    expect(find.text('Boarding code'), findsOneWidget, reason: 'the screen title; the tab says Code');
  });

  testWidgets('a rejected request shows the school\'s reason and lets the student ask again', (tester) async {
    await open(
      tester,
      FakeBackend(current: semester(), mine: [subscription(status: SubscriptionStatus.rejected, note: 'The receipt is unreadable.')]),
    );
    expect(find.text('Request not approved'), findsOneWidget);
    expect(find.text('The receipt is unreadable.'), findsOneWidget);

    await tester.tap(find.text('Request again'));
    await tester.pumpAndSettle();
    expect(find.text('Subscribe for Fall 2026'), findsOneWidget);
    expect(find.text('Send request'), findsOneWidget);
  });

  testWidgets('a rejection without a note says so, and an expired one offers a new request', (tester) async {
    await open(tester, FakeBackend(current: semester(), mine: [subscription(status: SubscriptionStatus.rejected)]));
    expect(find.text('Your school did not give a reason.'), findsOneWidget);

    await open(tester, FakeBackend(current: semester(), mine: [subscription(status: SubscriptionStatus.expired)]));
    expect(find.text('Subscription ended'), findsOneWidget);
    expect(find.text('Request again'), findsOneWidget);
  });

  testWidgets('a revoked subscription says so with the school\'s reason and lets the student ask again', (tester) async {
    await open(tester, FakeBackend(current: semester(), mine: [subscription(status: SubscriptionStatus.revoked, note: 'Payment was reversed.')]));
    expect(find.text('Subscription ended by your school'), findsOneWidget);
    expect(find.text('Revoked'), findsWidgets);
    expect(find.text('Payment was reversed.'), findsOneWidget);
    expect(find.text('Show boarding code'), findsNothing);

    await tester.tap(find.text('Request again'));
    await tester.pumpAndSettle();
    expect(find.text('Send request'), findsOneWidget);
  });

  testWidgets('requests for another semester do not count', (tester) async {
    await open(tester, FakeBackend(current: semester(), mine: [subscription(semesterId: 'old', status: SubscriptionStatus.approved)]));
    expect(find.text('Subscribe for Fall 2026'), findsOneWidget);
  });

  testWidgets('pulling down refreshes the status', (tester) async {
    final backend = FakeBackend(current: semester(), mine: [subscription()]);
    await open(tester, backend);
    expect(find.text('Request sent'), findsOneWidget);

    backend.mine[0] = subscription(status: SubscriptionStatus.approved);
    await tester.drag(find.byType(ListView).first, const Offset(0, 1500));
    await tester.pumpAndSettle();
    expect(find.text('You are subscribed'), findsOneWidget);
  });

  testWidgets('the form speaks French', (tester) async {
    await open(tester, FakeBackend(current: semester()), locale: const Locale('fr'));
    expect(find.text('Envoyer la demande'), findsOneWidget);
    expect(find.text('Votre arrêt'), findsOneWidget);
    expect(find.text('Preuve de paiement'), findsOneWidget);
  });
}
