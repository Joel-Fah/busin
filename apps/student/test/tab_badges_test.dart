import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/nav/tab_badges.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'live_changes_test.dart' show open;
import 'support.dart';

Future<void> settleSome(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  test('which tabs a change concerns', () {
    expect(tabsForStatus(SubscriptionStatus.approved), {StudentTabs.subscription, StudentTabs.code});
    expect(tabsForStatus(SubscriptionStatus.rejected), {StudentTabs.subscription});
    expect(tabsForPush('installment_rejected'), {StudentTabs.subscription});
    expect(tabsForPush('bus_near_stop'), {StudentTabs.bus});
    expect(tabsForPush('trip_started'), {StudentTabs.bus});
    expect(tabsForPush('bus_at_campus'), {StudentTabs.bus});
    expect(tabsForPush('school_notice'), isEmpty);
  });

  testWidgets('an approval while on another tab puts a dot on Subscription and Code; opening one clears it', (tester) async {
    final semantics = tester.ensureSemantics();
    final backend = FakeBackend(current: semester(), mine: [subscription(stopId: 'stop2', status: SubscriptionStatus.pending)]);
    await open(tester, backend, FakePushService());
    await tester.tap(find.text('Profile').last);
    await settleSome(tester);
    expect(find.bySemanticsLabel(RegExp(r', new$')), findsNothing);

    final approved = subscription(stopId: 'stop2', status: SubscriptionStatus.approved);
    backend.mine[0] = approved;
    backend.emitLive([approved]);
    await settleSome(tester);
    expect(find.bySemanticsLabel('Subscription, new'), findsOneWidget);
    expect(find.bySemanticsLabel('Boarding code, new'), findsOneWidget);
    expect(find.bySemanticsLabel('Profile, new'), findsNothing, reason: 'the tab on screen is already in view');

    await tester.tap(find.text('Subscription').last);
    await settleSome(tester);
    expect(find.bySemanticsLabel('Subscription, new'), findsNothing);
    expect(find.bySemanticsLabel('Boarding code, new'), findsOneWidget);
    BusinToast.dismiss();
    await tester.pump();
    semantics.dispose();
  });

  testWidgets('the bus near the stop puts a dot on My bus', (tester) async {
    final semantics = tester.ensureSemantics();
    final push = FakePushService();
    final backend = FakeBackend(current: semester(), mine: [subscription(stopId: 'stop2', status: SubscriptionStatus.pending)]);
    await open(tester, backend, push);
    push.arrived.add(const PushMessage(kind: 'bus_near_stop'));
    await settleSome(tester);
    expect(find.bySemanticsLabel('My bus, new'), findsOneWidget);
    semantics.dispose();
  });
}
