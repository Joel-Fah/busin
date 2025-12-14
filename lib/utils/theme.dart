import 'package:busin/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData.light(useMaterial3: true).copyWith(
    colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
    scaffoldBackgroundColor: lightColor,
    brightness: Brightness.light,
    pageTransitionsTheme: PageTransitionsTheme(
      builders: Map<TargetPlatform, PageTransitionsBuilder>.fromIterable(
        TargetPlatform.values,
        value: (_) => const CupertinoPageTransitionsBuilder(),
      ),
    ),
    textTheme: Typography().black.apply(
      fontFamily: textFont,
      bodyColor: seedColor,
      displayColor: seedColor,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      shape: ContinuousRectangleBorder(borderRadius: borderRadius * 4),
      showDragHandle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        alignment: Alignment.center,
        elevation: WidgetStateProperty.resolveWith<double?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return 0.0;
          }
          if (states.contains(WidgetState.pressed)) {
            return 2.0;
          }
          return 6.0;
        }),
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return seedPalette.shade200;
          }
          return accentColor;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return lightColor.withValues(alpha: 0.5);
          }
          return lightColor;
        }),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: borderRadius * 2.0),
        ),
        textStyle: WidgetStateProperty.all<TextStyle>(
          AppTextStyles.body.copyWith(
            fontVariations: [FontVariation('wght', 500)],
          ),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        alignment: Alignment.center,
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return seedPalette.shade200;
          }
          return accentColor;
        }),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: borderRadius * 2.0),
        ),
        textStyle: WidgetStateProperty.all<TextStyle>(
          AppTextStyles.body.copyWith(
            fontVariations: [FontVariation('wght', 500)],
          ),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Container(
            width: 32.0,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: borderRadius * 8.0,
              gradient: LinearGradient(
                colors: [
                  seedColor.withValues(alpha: 0.4),
                  seedColor.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              size: 20.0,
              color: seedColor,
            ),
          ),
        );
      },
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: greyColor,
        borderRadius: borderRadius * 2,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      margin: const EdgeInsets.only(bottom: 10.0),
      enableFeedback: true,
      textStyle: AppTextStyles.body.copyWith(color: lightColor, fontSize: 14.0),
    ),
    appBarTheme: AppBarTheme(
      scrolledUnderElevation: 0.0,
      backgroundColor: lightColor,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      foregroundColor: seedColor,
      titleTextStyle: AppTextStyles.title.copyWith(
        color: seedColor,
        fontWeight: FontWeight.w600,
        fontSize: 48.0,
      ),
      toolbarHeight: 80.0,
      actionsPadding: EdgeInsets.only(right: 16.0),
    ),
    iconTheme: IconThemeData(color: seedColor),
    highlightColor: seedPalette.shade50.withValues(alpha: 0.1),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: borderRadius * 2.0),
      titleTextStyle: AppTextStyles.h4.copyWith(color: seedColor),
      subtitleTextStyle: AppTextStyles.body.copyWith(
        color: seedColor.withValues(alpha: 0.7),
      ),
    ),
    dividerColor: seedColor.withValues(alpha: 0.7),
    dividerTheme: DividerThemeData(color: seedColor.withValues(alpha: 0.7)),
    tabBarTheme: TabBarThemeData(
      dividerHeight: 0.0,
      labelPadding: EdgeInsetsGeometry.all(16.0),
      labelStyle: AppTextStyles.body,
      labelColor: lightColor,
      unselectedLabelColor: lightColor.withValues(alpha: 0.35),
      unselectedLabelStyle: AppTextStyles.body,
      indicator: BoxDecoration(
        borderRadius: borderRadius * 2.0,
        color: seedPalette.shade50.withValues(alpha: 0.1),
      ),
      indicatorAnimation: TabIndicatorAnimation.elastic,
      indicatorSize: TabBarIndicatorSize.tab,
      splashBorderRadius: borderRadius * 2.0,
      tabAlignment: TabAlignment.center,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: lightColor,
      labelStyle: AppTextStyles.body.copyWith(fontSize: 14.0, color: seedColor),
      shape: RoundedRectangleBorder(borderRadius: borderRadius * 2.0),
      pressElevation: 0.0,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: borderRadius * 2.0),
        ),
      ),
    ),
    searchBarTheme: SearchBarThemeData(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.focused)) {
          return seedPalette.shade200;
        }
        if (states.contains(WidgetState.pressed)) {
          return seedPalette.shade300;
        }
        return seedPalette.shade100;
      }),
      textStyle: WidgetStateProperty.all<TextStyle>(
        AppTextStyles.body.copyWith(color: seedColor),
      ),
      hintStyle: WidgetStateProperty.all<TextStyle>(
        AppTextStyles.body.copyWith(
          color: greyColor.withValues(alpha: 0.7),
          fontStyle: FontStyle.italic,
        ),
      ),
      side: WidgetStateProperty.all<BorderSide>(
        BorderSide(
          color: seedPalette.shade400.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(borderRadius: borderRadius * 2.25),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      extendedTextStyle: AppTextStyles.body,
      shape: RoundedRectangleBorder(borderRadius: borderRadius * 2.25),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      contentPadding: const EdgeInsets.symmetric(
        vertical: 12.0,
        horizontal: 16.0,
      ),
      errorStyle: AppTextStyles.small.copyWith(
        color: errorColor,
        fontSize: 14.0,
      ),
      hintStyle: AppTextStyles.body.copyWith(
        color: greyColor,
        fontStyle: FontStyle.italic
      ),
      labelStyle: AppTextStyles.body.copyWith(color: seedColor),
      border: AppInputBorders.border,
      focusedBorder: AppInputBorders.focusedBorder,
      errorBorder: AppInputBorders.errorBorder,
      focusedErrorBorder: AppInputBorders.focusedErrorBorder,
      enabledBorder: AppInputBorders.enabledBorder,
      disabledBorder: AppInputBorders.disabledBorder,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: borderRadius * 2.0),
      backgroundColor: seedPalette.shade100,
      titleTextStyle: AppTextStyles.h2,
      contentTextStyle: AppTextStyles.body,
    ),
  );

  static ThemeData darkTheme = ThemeData.dark(useMaterial3: true).copyWith(
    colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
    scaffoldBackgroundColor: seedColor,
    brightness: Brightness.dark,
    pageTransitionsTheme: PageTransitionsTheme(
      builders: Map<TargetPlatform, PageTransitionsBuilder>.fromIterable(
        TargetPlatform.values,
        value: (_) => const CupertinoPageTransitionsBuilder(),
      ),
    ),
    textTheme: Typography().white.apply(
      fontFamily: textFont,
      bodyColor: lightColor,
      displayColor: lightColor,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      shape: ContinuousRectangleBorder(borderRadius: borderRadius * 4),
      showDragHandle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        alignment: Alignment.center,
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return seedPalette.shade200;
          }
          return accentColor;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return lightColor.withValues(alpha: 0.5);
          }
          return lightColor;
        }),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: borderRadius * 2),
        ),
        textStyle: WidgetStateProperty.all<TextStyle>(
          AppTextStyles.body.copyWith(
            fontVariations: [FontVariation('wght', 500)],
          ),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        alignment: Alignment.center,
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return seedPalette.shade200;
          }
          return accentColor;
        }),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: borderRadius * 2),
        ),
        textStyle: WidgetStateProperty.all<TextStyle>(
          AppTextStyles.body.copyWith(
            fontVariations: [FontVariation('wght', 500)],
          ),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Container(
            width: 32.0,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: borderRadius * 8.0,
              gradient: LinearGradient(
                colors: [
                  lightColor.withValues(alpha: 0.4),
                  lightColor.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              size: 20.0,
              color: lightColor,
            ),
          ),
        );
      },
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: greyColor,
        borderRadius: borderRadius * 2,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      margin: const EdgeInsets.only(bottom: 10.0),
      enableFeedback: true,
      textStyle: AppTextStyles.body.copyWith(color: lightColor, fontSize: 14.0),
    ),
    appBarTheme: AppBarTheme(
      scrolledUnderElevation: 0.0,
      backgroundColor: seedColor,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      foregroundColor: lightColor,
      titleTextStyle: AppTextStyles.title.copyWith(
        color: lightColor,
        fontWeight: FontWeight.w600,
        fontSize: 48.0,
      ),
      toolbarHeight: 80.0,
      actionsPadding: EdgeInsets.only(right: 16.0),
    ),
    iconTheme: IconThemeData(color: lightColor),
    highlightColor: seedPalette.shade50.withValues(alpha: 0.1),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: borderRadius * 2.0),
      titleTextStyle: AppTextStyles.h4.copyWith(color: lightColor),
      subtitleTextStyle: AppTextStyles.body.copyWith(
        color: lightColor.withValues(alpha: 0.7),
      ),
    ),
    dividerColor: lightColor.withValues(alpha: 0.7),
    dividerTheme: DividerThemeData(color: lightColor.withValues(alpha: 0.7)),
    tabBarTheme: TabBarThemeData(
      dividerHeight: 0.0,
      labelPadding: EdgeInsetsGeometry.all(16.0),
      labelStyle: AppTextStyles.body,
      labelColor: lightColor,
      unselectedLabelColor: lightColor.withValues(alpha: 0.35),
      unselectedLabelStyle: AppTextStyles.body,
      indicator: BoxDecoration(
        borderRadius: borderRadius * 2.0,
        color: seedPalette.shade50.withValues(alpha: 0.1),
      ),
      indicatorAnimation: TabIndicatorAnimation.elastic,
      indicatorSize: TabBarIndicatorSize.tab,
      splashBorderRadius: borderRadius * 2.0,
      tabAlignment: TabAlignment.center,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: seedColor,
      labelStyle: AppTextStyles.body.copyWith(
        fontSize: 14.0,
        color: lightColor,
      ),
      selectedColor: seedPalette.shade800,
      shape: RoundedRectangleBorder(borderRadius: borderRadius * 2.0),
      pressElevation: 0.0,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: borderRadius * 2.0),
        ),
      ),
    ),
    searchBarTheme: SearchBarThemeData(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.focused)) {
          return seedPalette.shade800;
        }
        if (states.contains(WidgetState.pressed)) {
          return seedPalette.shade700;
        }
        return seedPalette.shade900;
      }),
      textStyle: WidgetStateProperty.all<TextStyle>(
        AppTextStyles.body.copyWith(color: lightColor),
      ),
      hintStyle: WidgetStateProperty.all<TextStyle>(
        AppTextStyles.body.copyWith(
          color: lightColor.withValues(alpha: 0.7),
          fontStyle: FontStyle.italic,
        ),
      ),
      side: WidgetStateProperty.all<BorderSide>(
        BorderSide(
          color: seedPalette.shade600.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(borderRadius: borderRadius * 2.25),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      extendedTextStyle: AppTextStyles.body,
      shape: RoundedRectangleBorder(borderRadius: borderRadius * 2.25),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      contentPadding: const EdgeInsets.symmetric(
        vertical: 12.0,
        horizontal: 16.0,
      ),
      errorStyle: AppTextStyles.small.copyWith(
        color: errorColor,
        fontSize: 14.0,
      ),
      hintStyle: AppTextStyles.body.copyWith(
          color: seedPalette.shade50,
          fontStyle: FontStyle.italic
      ),
      labelStyle: AppTextStyles.body.copyWith(color: lightColor),
      border: AppInputBorders.border,
      focusedBorder: AppInputBorders.focusedBorder,
      errorBorder: AppInputBorders.errorBorder,
      focusedErrorBorder: AppInputBorders.focusedErrorBorder,
      enabledBorder: AppInputBorders.enabledBorder,
      disabledBorder: AppInputBorders.disabledBorder,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: borderRadius * 2.0),
      backgroundColor: seedPalette.shade900,
      titleTextStyle: AppTextStyles.h2,
      contentTextStyle: AppTextStyles.body,
    ),
  );
}
