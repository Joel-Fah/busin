import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fake that remembers what was asked, and can refuse.
class FakeDeletion implements AccountDeletionRepository {
  FakeDeletion({this.scheduled, this.refusal});

  ScheduledDeletion? scheduled;
  final Object? refusal;
  int requests = 0;
  int cancels = 0;

  @override
  Future<ScheduledDeletion?> mine() async => scheduled;

  @override
  Future<DateTime> request() async {
    requests += 1;
    if (refusal != null) throw refusal!;
    scheduled = ScheduledDeletion(dueAt: DateTime.utc(2026, 11, 23, 8), byPlatform: false);
    return scheduled!.dueAt;
  }

  @override
  Future<void> cancel() async {
    cancels += 1;
    scheduled = null;
  }
}

Widget host(AccountDeletionRepository repository) => MaterialApp(
      theme: BusinTheme.light(),
      localizationsDelegates: businLocalizationsDelegates,
      supportedLocales: businSupportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(16), child: DeleteAccountSection(repository: repository)))),
    );

void main() {
  testWidgets('asking opens a sheet that says what goes and what stays, then shows the date', (tester) async {
    final fake = FakeDeletion();
    await tester.pumpWidget(host(fake));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete my account').last);
    await tester.pumpAndSettle();
    expect(find.text('Delete your account?'), findsOneWidget);
    expect(find.textContaining('Your school keeps its records without your name'), findsOneWidget);

    await tester.tap(find.text('Delete in 7 days'));
    await tester.pumpAndSettle();
    expect(fake.requests, 1);
    expect(find.textContaining('Your account will be deleted on'), findsOneWidget);
    expect(find.text('Keep my account'), findsOneWidget);
  });

  testWidgets('keeping the account cancels the deletion', (tester) async {
    final fake = FakeDeletion(scheduled: ScheduledDeletion(dueAt: DateTime.utc(2026, 11, 23, 8), byPlatform: true));
    await tester.pumpWidget(host(fake));
    await tester.pumpAndSettle();
    expect(find.textContaining('BusIn scheduled the deletion of your account'), findsOneWidget);

    await tester.tap(find.text('Keep my account'));
    await tester.pumpAndSettle();
    expect(fake.cancels, 1);
    expect(find.text('Delete my account'), findsWidgets);
  });

  testWidgets('closing the sheet asks nothing', (tester) async {
    final fake = FakeDeletion();
    await tester.pumpWidget(host(fake));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete my account').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep my account'));
    await tester.pumpAndSettle();
    expect(fake.requests, 0);
  });

  testWidgets('the last administrator is told to hand the school over', (tester) async {
    final fake = FakeDeletion(refusal: const Conflict('database 55000', reason: 'last_admin'));
    await tester.pumpWidget(host(fake));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete my account').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete in 7 days'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('You are the last administrator of your school.'), findsOneWidget);
    expect(fake.scheduled, isNull);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
