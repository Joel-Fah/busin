import 'package:busin_ui/busin_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ops_shell_test.dart' show open, settle;
import 'support.dart';

void main() {
  testWidgets('a trip put on the crew while on another tab puts a dot on Trips; opening Trips clears it', (tester) async {
    final semantics = tester.ensureSemantics();
    final trips = FakeTrips([]);
    await open(tester, auth: FakeAuth(signedInAs: 'u1'), profiles: {'u1': staff()}, trips: trips);
    expect(trips.crewListeners, 1, reason: 'one live listener, for this staff member');
    await tester.tap(find.text('History').last);
    await settle(tester);

    trips.crewNews.add('t9');
    await settle(tester, 3);
    expect(find.bySemanticsLabel('Trips, new'), findsOneWidget);

    await tester.tap(find.text('Trips').last);
    await settle(tester);
    expect(find.bySemanticsLabel('Trips, new'), findsNothing);
    BusinToast.dismiss();
    semantics.dispose();
  });

  testWidgets('on the Trips tab, news reloads the list without a dot', (tester) async {
    final semantics = tester.ensureSemantics();
    final trips = FakeTrips([]);
    await open(tester, auth: FakeAuth(signedInAs: 'u1'), profiles: {'u1': staff()}, trips: trips);
    trips.crewNews.add('t9');
    await settle(tester, 3);
    expect(find.bySemanticsLabel('Trips, new'), findsNothing);
    semantics.dispose();
  });
}
