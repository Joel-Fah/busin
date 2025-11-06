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
        value: (_) => const PredictiveBackPageTransitionsBuilder(),
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
        switch (Theme.of(context).platform) {
          case TargetPlatform.android:
            return const CircleAvatar(
              radius: 28.0,
              backgroundColor: Color(0xFFE5E5EA),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowLeft01,
                size: 20.0,
              ),
            );
          default:
            return const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              size: 20.0,
            );
        }
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
  );

  static ThemeData darkTheme = ThemeData.dark(useMaterial3: true).copyWith(
    colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
    scaffoldBackgroundColor: seedColor,
    brightness: Brightness.dark,
    pageTransitionsTheme: PageTransitionsTheme(
      builders: Map<TargetPlatform, PageTransitionsBuilder>.fromIterable(
        TargetPlatform.values,
        value: (_) => const PredictiveBackPageTransitionsBuilder(),
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
        switch (Theme.of(context).platform) {
          case TargetPlatform.android:
            return const CircleAvatar(
              radius: 28.0,
              backgroundColor: Color(0xFFE5E5EA),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowLeft01,
                size: 20.0,
              ),
            );
          default:
            return const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              size: 20.0,
            );
        }
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
      labelStyle: AppTextStyles.body.copyWith(fontSize: 14.0, color: lightColor,),
      selectedColor: seedPalette.shade800,
      shape: RoundedRectangleBorder(borderRadius: borderRadius * 2.0),
      pressElevation: 0.0,
    ),
  );
}
