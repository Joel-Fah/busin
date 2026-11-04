import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final entry in {'light': BusinTheme.light(), 'dark': BusinTheme.dark()}.entries) {
    group('the ${entry.key} theme', () {
      final theme = entry.value;

      test('is Material 3 in the brand palette', () {
        expect(theme.useMaterial3, isTrue);
        expect(theme.extension<BusinPalette>(), isNotNull);
        expect(theme.colorScheme.primary, BusinPalette.orange);
        expect(theme.scaffoldBackgroundColor, theme.extension<BusinPalette>()!.bg);
      });

      test('uses Plus Jakarta Sans from this package', () {
        expect(theme.textTheme.bodyMedium?.fontFamily, 'packages/busin_ui/PlusJakartaSans');
      });

      test('shapes follow the radius scale', () {
        final card = theme.cardTheme.shape as RoundedRectangleBorder;
        expect(card.borderRadius, BorderRadius.circular(BusinRadius.lg));
        final dialog = theme.dialogTheme.shape as RoundedRectangleBorder;
        expect(dialog.borderRadius, BorderRadius.circular(BusinRadius.lg));
        final field = theme.inputDecorationTheme.border as OutlineInputBorder;
        expect(field.borderRadius, BorderRadius.circular(BusinRadius.sm));
      });
    });
  }

  test('light and dark are different palettes', () {
    expect(BusinTheme.light().brightness, Brightness.light);
    expect(BusinTheme.dark().brightness, Brightness.dark);
    expect(BusinTheme.light().scaffoldBackgroundColor, isNot(BusinTheme.dark().scaffoldBackgroundColor));
  });
}
