import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/* ----------- Colors ----------- */
// Primaries
const Color seedColor = Color(0xFF002A33);
const Color accentColor = Color(0xFFF5951F);

// Neutrals
const Color darkColor = Color(0xFF272727);
const Color lightColor = Colors.white;
const Color greyColor = const Color(0xFF8D8D8D);

// States Colors
const Color infoColor = Color(0xFF4285F4);
const Color successColor = Color(0xFF0F9D58);
const Color errorColor = Color(0xFFDB4437);
const Color warningColor = Color(0xFFEAAB00);

// Material Color Palettes
MaterialColor seedPalette =
MaterialColor(seedColor.toARGB32(), const <int, Color>{
  50: Color(0xFFE9FFFD),
  100: Color(0xFFC9FFF9),
  200: Color(0xFF99FFF7),
  300: Color(0xFF54FFF5),
  400: Color(0xFF07FFFC),
  500: Color(0xFF00E3EF),
  600: Color(0xFF00B4C9),
  700: Color(0xFF008FA1),
  800: Color(0xFF087282),
  900: Color(0xFF0C5D6D),
});

MaterialColor accentPalette =
MaterialColor(seedColor.toARGB32(), const <int, Color>{
  50: Color(0xFFFEF8EC),
  100: Color(0xFFFDE9C8),
  200: Color(0xFFFAD28D),
  300: Color(0xFFF7B552),
  400: Color(0xFFEF7611),
  500: Color(0xFFD4550B),
  600: Color(0xFFB0380D),
  700: Color(0xFF8F2C11),
  800: Color(0xFF752512),
  900: Color(0xFF431005),
});

/* ----------- Icons ----------- */
// States Icons
const List<List<dynamic>> infoIcon = HugeIcons.strokeRoundedInformationCircle;
const List<List<dynamic>> errorIcon = HugeIcons.strokeRoundedCancelCircle;
const List<List<dynamic>> warningIcon = HugeIcons.strokeRoundedAlert02;
const List<List<dynamic>> successIcon = HugeIcons.strokeRoundedCheckmarkCircle02;

/* ----------- Fonts ----------- */
// Font Family
const String textFont = "Bevellier";

/* ----------- Images ----------- */

/* ----------- Widgets ----------- */
// BorderRadii
BorderRadius borderRadius = BorderRadius.circular(8.0);
BorderRadius topRadius = const BorderRadius.vertical(
  top: Radius.circular(16.0),
);

// Duration
const Duration duration = Duration(milliseconds: 300);

// TextStyles
class AppTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 34.0,
    height: 40.0 / 34.0,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle h1 = TextStyle(
    fontSize: 28.0,
    height: 36.0 / 28.0,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24.0,
    height: 32.0 / 24.0,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20.0,
    height: 28.0 / 20.0,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 18.0,
    height: 24.0 / 18.0,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16.0,
    height: 24.0 / 16.0,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle small = TextStyle(
    fontSize: 12.0,
    height: 16.0 / 12.0,
    fontWeight: FontWeight.w300,
  );
}