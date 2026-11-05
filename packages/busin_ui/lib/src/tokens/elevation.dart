import 'package:flutter/material.dart';

/// Shadows and glass, the portal's values. `soft` lifts a card; `float` lifts things that hover over the page (the
/// navigation bar, sheets, insight cards, tooltips).
class BusinElevation {
  const BusinElevation._();

  /// Cards and the selected tab. Heavier in dark mode, where shadows are harder to see.
  static List<BoxShadow> soft(Brightness brightness) => brightness == Brightness.dark
      ? const [
          BoxShadow(color: Color(0x66000000), blurRadius: 2, offset: Offset(0, 1)),
          BoxShadow(color: Color(0x4D000000), blurRadius: 16, offset: Offset(0, 4)),
        ]
      : const [
          BoxShadow(color: Color(0x14002A33), blurRadius: 2, offset: Offset(0, 1)),
          BoxShadow(color: Color(0x0F002A33), blurRadius: 16, offset: Offset(0, 4)),
        ];

  /// Floating surfaces: the same in both themes.
  static const List<BoxShadow> float = [
    BoxShadow(color: Color(0x2E00141A), blurRadius: 36, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x1A00141A), blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// How much of the surface colour a glass bar keeps (the rest is the blurred page behind it).
  static const double glassOpacity = 0.72;

  /// Blur behind a glass bar, in logical pixels.
  static const double glassBlur = 18;
}
