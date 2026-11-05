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
      overrides: overridesFor(FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()}), backend: backend, picker: picker),
      child: const StudentApp(),
    ),
  );
  await tester.pumpAndSettle();
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
    expect(find.text('Subscribe for Fall 2026'), findsOneWidget);
    expect(find.textContaining('Starts'), findsOneWidget);
  });

  testWidgets('Send stays off until a stop and a photo are chosen, then sends both and shows the pending request', (tester) async {
    final backend = FakeBackend(current: semester());
    final picker = FakeProofPicker(samplePhoto());
    await open(tester, backend, picker: picker);

    expect(find.text('Subscribe for Fall 2026'), findsOneWidget);
    expect(sendEnabled(tester), isFalse);

    await chooseStop(tester, 'Mvan');
    expect(find.text('Mvan'), findsOneWidget);
    expect(sendEnabled(tester), isFalse, reason: 'a stop alone is not enough');

    await choosePhoto(tester);
    expect(picker.asked, [ProofSource.gallery]);
    expect(find.text('Change photo'), findsOneWidget);
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
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Mvan'), findsOneWidget);
    expect(find.text('Send request'), findsNothing);
  });

  testWidgets('the stop sheet can be searched', (tester) async {
    await open(tester, FakeBackend(current: semester()));
    await tester.tap(find.text('Your stop'));
    await tester.pumpAndSettle();
    expect(find.text('Biyem-Assi'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ekou');
    await tester.pumpAndSettle();
    expect(find.text('Carrefour Ekounou'), findsOneWidget);
    expect(find.text('Biyem-Assi'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No stop matches.'), findsOneWidget);
  });

  testWidgets('backing out of the camera or gallery changes nothing', (tester) async {
    await open(tester, FakeBackend(current: semester()), picker: FakeProofPicker(null));
    await choosePhoto(tester);
    expect(find.text('Change photo'), findsNothing);
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
      await chooseStop(tester, 'Mvan');
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
    await chooseStop(tester, 'Mvan');
    await choosePhoto(tester);
    await tester.tap(find.text('Send request'));
    await tester.pumpAndSettle();

    expect(backend.requests, isEmpty);
    expect(find.text('No connection. Check your network and try again.'), findsOneWidget);
  });

  testWidgets('a pending request shows where it stands, with its stop and no form', (tester) async {
    await open(tester, FakeBackend(current: semester(), mine: [subscription(stopId: 'stop3', proofPath: 's1/u1/a.jpg')]));
    expect(find.text('Request sent'), findsOneWidget);
    expect(find.text('Biyem-Assi'), findsOneWidget);
    expect(find.textContaining('checking your payment proof'), findsOneWidget);
    expect(find.text('Send request'), findsNothing);
  });

  testWidgets('an approved subscription says where to board and leads to the boarding code', (tester) async {
    await open(tester, FakeBackend(current: semester(), mine: [subscription(status: SubscriptionStatus.approved)]));
    expect(find.text('You are subscribed'), findsOneWidget);
    expect(find.text('You can board at Carrefour Ekounou.'), findsOneWidget);

    await tester.tap(find.text('Show boarding code'));
    await tester.pumpAndSettle();
    expect(find.text('Coming soon'), findsOneWidget, reason: 'the boarding code arrives in the next slice');
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
