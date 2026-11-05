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

  for (final entry in {'light': BusinPalette.light, 'dark': BusinPalette.dark}.entries) {
    test('text on the glass bar stays readable over the page in the ${entry.key} theme', () {
      final p = entry.value;
      // The bar keeps 72% of the surface colour and shows 28% of what is behind it: the page, or a card (surface).
      for (final behind in [p.bg, p.surface, p.surface2]) {
        final glass = Color.alphaBlend(p.surface.withValues(alpha: BusinElevation.glassOpacity), behind);
        expect(contrastRatio(p.fg, glass), greaterThanOrEqualTo(4.5), reason: 'selected label on glass over $behind');
        expect(contrastRatio(p.muted, glass), greaterThanOrEqualTo(4.5), reason: 'other labels on glass over $behind');
      }
    });
  }

  test('white text on the seed banner, and the orange marker under it, stay readable in both themes', () {
    const white = Color(0xFFFFFFFF);
    expect(contrastRatio(white, BusinRamps.seed), greaterThanOrEqualTo(7));
    // The marker sits behind the headline at 70%: the headline must still be readable on the blended colour.
    final marked = Color.alphaBlend(BusinPalette.orange.withValues(alpha: 0.7), BusinRamps.seed);
    expect(contrastRatio(white, marked), greaterThanOrEqualTo(3), reason: 'large display text only needs 3');
  });

  test('insight cards read on their pale teal and on the accent', () {
    expect(contrastRatio(BusinRamps.seed, BusinRamps.teal50), greaterThanOrEqualTo(7));
    expect(contrastRatio(BusinPalette.light.onAccent, BusinPalette.orange), greaterThanOrEqualTo(4.5));
  });

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
