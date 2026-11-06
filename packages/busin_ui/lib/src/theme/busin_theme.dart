import 'package:flutter/material.dart';

import '../tokens/palette.dart';
import '../tokens/shape.dart';

/// The Material 3 themes of the BusIn apps. They carry the brand palette, Plus Jakarta Sans and the
/// shape scale, so a stock Material widget already looks like BusIn. Apps use
/// `theme: BusinTheme.light(), darkTheme: BusinTheme.dark()` and let the system choose.
class BusinTheme {
  const BusinTheme._();

  static const String fontFamily = 'PlusJakartaSans';
  static const String fontPackage = 'busin_ui';

  static ThemeData light() => _build(BusinPalette.light, Brightness.light);
  static ThemeData dark() => _build(BusinPalette.dark, Brightness.dark);

  static ThemeData _build(BusinPalette p, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      secondary: p.brand,
      onSecondary: p.onBrand,
      error: p.bad,
      onError: p.badBg,
      surface: p.surface,
      onSurface: p.fg,
      onSurfaceVariant: p.muted,
      surfaceContainerHighest: p.surface2,
      surfaceContainerHigh: p.surface2,
      surfaceContainer: p.surface2,
      surfaceContainerLow: p.bg,
      surfaceContainerLowest: p.bg,
      outline: p.line,
      outlineVariant: p.line,
      tertiary: p.link,
      onTertiary: p.surface,
      errorContainer: p.badBg,
      onErrorContainer: p.bad,
      primaryContainer: p.surface2,
      onPrimaryContainer: p.fg,
      secondaryContainer: p.surface2,
      onSecondaryContainer: p.fg,
    );

    RoundedRectangleBorder shape(double radius) =>
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      package: fontPackage,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      dividerColor: p.line,
      extensions: [p],
    );

    final text = base.textTheme.apply(bodyColor: p.fg, displayColor: p.fg);

    return base.copyWith(
      textTheme: text.copyWith(
        headlineLarge: text.headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4),
        headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.fg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: shape(BusinRadius.lg),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x5),
          shape: shape(BusinRadius.sm),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.surface2,
          foregroundColor: p.fg,
          elevation: 0,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x5),
          shape: shape(BusinRadius.sm),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.fg,
          minimumSize: const Size(64, 48),
          shape: shape(BusinRadius.sm),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: BusinSpace.x4, vertical: BusinSpace.x4),
        hintStyle: TextStyle(color: p.muted),
        prefixIconColor: p.muted,
        border: _inputBorder(p.line),
        enabledBorder: _inputBorder(p.line),
        focusedBorder: _inputBorder(p.link, width: 2),
        errorBorder: _inputBorder(p.bad),
        focusedErrorBorder: _inputBorder(p.bad, width: 2),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        shape: shape(BusinRadius.lg),
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(BusinRadius.lg)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.brand,
        contentTextStyle: TextStyle(color: p.onBrand, fontFamily: fontFamily, package: fontPackage),
        shape: shape(BusinRadius.sm),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface2,
        labelStyle: TextStyle(color: p.fg, fontFamily: fontFamily, package: fontPackage),
        side: BorderSide.none,
        shape: shape(BusinRadius.xs),
      ),
      dividerTheme: DividerThemeData(color: p.line, space: 1, thickness: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent, circularTrackColor: p.surface2),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(BusinRadius.sm),
        borderSide: BorderSide(color: color, width: width),
      );
}
