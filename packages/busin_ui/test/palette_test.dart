import 'dart:ui' show Color;

import 'package:busin_ui/busin_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final entry in {'light': BusinPalette.light, 'dark': BusinPalette.dark}.entries) {
    test('every text and background pair reaches WCAG AA in the ${entry.key} palette', () {
      for (final (name, ink, ground) in entry.value.textPairs) {
        expect(contrastRatio(ink, ground), greaterThanOrEqualTo(4.5), reason: '$name in ${entry.key}');
      }
    });
  }

  test('contrast ratio is symmetric and spans 1 to 21', () {
    final black = const Color(0xFF000000);
    final white = const Color(0xFFFFFFFF);
    expect(contrastRatio(black, white), closeTo(21, 0.01));
    expect(contrastRatio(white, black), closeTo(21, 0.01));
    expect(contrastRatio(white, white), 1);
  });

  test('the brand colours match the portal', () {
    expect(BusinPalette.seed, const Color(0xFF002A33));
    expect(BusinPalette.orange, const Color(0xFFF5951F));
    expect(BusinPalette.light.accent, BusinPalette.orange);
    expect(BusinPalette.dark.accent, BusinPalette.orange);
  });

  test('lerp moves between the two palettes', () {
    final middle = BusinPalette.light.lerp(BusinPalette.dark, 0.5);
    expect(middle.bg, isNot(BusinPalette.light.bg));
    expect(BusinPalette.light.lerp(BusinPalette.dark, 0).bg, BusinPalette.light.bg);
    expect(BusinPalette.light.lerp(BusinPalette.dark, 1).bg, BusinPalette.dark.bg);
  });
}
