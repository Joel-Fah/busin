import 'package:busin_student/src/join/school_logo.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// A school's logo keeps its own shape: a plate of fixed height that may grow up to two and a half times as wide.
void main() {
  Widget host(Widget child) => MaterialApp(theme: BusinTheme.light(), home: Scaffold(body: Center(child: child)));

  testWidgets('without a logo, a square tile with an icon', (tester) async {
    await tester.pumpWidget(host(const SchoolLogo(url: null, size: 48)));
    final size = tester.getSize(find.byType(SchoolLogo));
    expect(size.width, closeTo(48, 0.01));
    expect(size.height, closeTo(48, 0.01));
  });

  testWidgets('with a logo, the plate keeps its height and lets a wide logo be wide, never cut', (tester) async {
    await tester.pumpWidget(host(const SchoolLogo(url: 'https://example.invalid/logo.webp', size: 48)));
    final plate = tester.widget<Container>(find.descendant(of: find.byType(SchoolLogo), matching: find.byType(Container)).first);
    expect(plate.constraints, const BoxConstraints(minWidth: 48, maxWidth: 120, minHeight: 48, maxHeight: 48));
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.contain, reason: 'fitted, not cropped');
    expect(image.width, isNull, reason: 'its width follows its own shape');
  });
}
