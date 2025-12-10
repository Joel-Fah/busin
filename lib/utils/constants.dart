import 'dart:ui';

import 'package:busin/utils/utils.dart';
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

// Gradients
LinearGradient lightGradient = LinearGradient(
  colors: [seedPalette.shade50, Colors.white],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

LinearGradient darkGradient = LinearGradient(
  colors: [seedColor, seedPalette.shade900],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

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
const List<List<dynamic>> successIcon =
    HugeIcons.strokeRoundedCheckmarkCircle02;

/* ----------- Fonts ----------- */
// Font Family
const String textFont = "Bevellier";

/* ----------- Images ----------- */
// Logo
const String cyanLogo = 'assets/images/logo/cyan.svg';
const String orangeLogo = 'assets/images/logo/orange.svg';
const String whiteLogo = 'assets/images/logo/white.svg';

// Themes
const String dark = 'assets/images/dark.png';
const String light = 'assets/images/light.png';
const String system = 'assets/images/system.png';

// ICTU Logos
const String ictULogoHorizontal = 'assets/images/ictu-logo-horizontal.png';
const String ictULogo = 'assets/images/ICTULogoNew.png';

// Onboarding & Others
const String onboard1 = 'assets/images/onboard1.jpg';
const String onboard1_light = 'assets/images/onboard1_light.jpg';
const String onboard2 = 'assets/images/onboard2.svg';
const String blocked = 'assets/images/blocked.png';
const String bus = 'assets/images/bus.png';
const String papers = 'assets/images/papers.png';
const String seat = 'assets/images/seat.png';
const String ticket1 = 'assets/images/ticket1.png';
const String ticket2 = 'assets/images/ticket2.png';
const String verified = 'assets/images/verified.png';
const String newSubscription = 'assets/images/new_subscription.png';
const String subscriptionDetails = 'assets/images/subscription_details.jpg';
const String busLoader = 'assets/images/bus_loader.gif';

// Icons & Flags
const String googleIcon = 'assets/images/icons/google.svg';
const String usaFlag = 'assets/images/flags/usa.png';
const String franceFlag = 'assets/images/flags/france.png';

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
    fontFamily: textFont,
    fontSize: 34.0,
    height: 40.0 / 34.0,
    fontWeight: FontWeight.w900,
    fontVariations: [FontVariation('wght', 900)],
  );

  static TextStyle h1 = TextStyle(
    fontFamily: textFont,
    fontSize: 28.0,
    height: 36.0 / 28.0,
    fontWeight: FontWeight.bold,
    fontVariations: [FontVariation('wght', 700)],
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: textFont,
    fontSize: 24.0,
    height: 32.0 / 24.0,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: textFont,
    fontSize: 20.0,
    height: 28.0 / 20.0,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
  );

  static const TextStyle h4 = TextStyle(
    fontFamily: textFont,
    fontSize: 18.0,
    height: 24.0 / 18.0,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
  );

  static const TextStyle body = TextStyle(
    fontFamily: textFont,
    fontSize: 16.0,
    height: 24.0 / 16.0,
    fontWeight: FontWeight.normal,
    fontVariations: [FontVariation('wght', 400)],
  );

  static const TextStyle small = TextStyle(
    fontFamily: textFont,
    fontSize: 12.0,
    height: 16.0 / 12.0,
    fontWeight: FontWeight.w300,
    fontVariations: [FontVariation('wght', 300)],
  );
}

// Input Borders
class AppInputBorders {
  static OutlineInputBorder border = OutlineInputBorder(
    borderSide: BorderSide(
      color: themeController.isDark ? lightColor : seedColor,
      width: 1,
    ),
    borderRadius: borderRadius * 2.25,
  );

  static OutlineInputBorder focusedBorder = OutlineInputBorder(
    borderSide: BorderSide(
      color: themeController.isDark ? lightColor : seedColor,
      width: 1,
    ),
    borderRadius: borderRadius * 2.25,
  );

  static OutlineInputBorder errorBorder = OutlineInputBorder(
    borderSide: BorderSide(color: errorColor, width: 1),
    borderRadius: borderRadius * 2.25,
  );

  static OutlineInputBorder focusedErrorBorder = OutlineInputBorder(
    borderSide: BorderSide(color: errorColor, width: 1),
    borderRadius: borderRadius * 2.25,
  );

  static OutlineInputBorder enabledBorder = OutlineInputBorder(
    borderSide: BorderSide(
      color: themeController.isDark ? lightColor : seedColor,
      width: 1,
    ),
    borderRadius: borderRadius * 2.25,
  );

  static OutlineInputBorder disabledBorder = OutlineInputBorder(
    borderSide: BorderSide(color: greyColor, width: 1),
    borderRadius: borderRadius * 2.25,
  );
}

// Create a Cloudinary instance and set your cloud name.
// var cloudinary=Cloudinary.fromStringUrl('cloudinary://${dotenv.env['CLOUDINARY_API_KEY']!}:${dotenv.env['CLOUDINARY_API_SECRET']!}@CLOUD_NAME');
