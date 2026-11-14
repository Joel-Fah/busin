import 'package:busin_app/busin_app.dart';
import 'package:busin_ops/src/providers.dart';
import 'package:busin_ops/src/screens/sign_in_screen.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

class _RefusedAuth extends FakeAuth {
  @override
  Future<void> signInWithGoogle() async => throw const SignInException(SignInFailure.notAllowed);
}

void main() {
  testWidgets('an account no school allows is told it needs the school account or an invited address', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [authServiceProvider.overrideWithValue(_RefusedAuth())],
      child: MaterialApp(
        theme: BusinTheme.light(),
        localizationsDelegates: businLocalizationsDelegates,
        supportedLocales: businSupportedLocales,
        home: const SignInScreen(),
      ),
    ));
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('This Google account is not allowed here. Sign in with your school account or the address your school invited.'), findsOneWidget);
  });
}
