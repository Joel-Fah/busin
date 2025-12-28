import 'package:busin/controllers/locale_controller.dart';
import 'package:busin/l10n/l10n.dart';
import 'package:busin/ui/components/widgets/default_snack_bar.dart';
import 'package:busin/ui/components/widgets/list_subheading.dart';
import 'package:busin/utils/constants.dart';
import 'package:busin/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  static const String routeName = "/appearance";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(fit: BoxFit.contain, child: const Text("Appearance")),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        children:
            [
                  const ListSubHeading(label: "Theme"),
                  const Gap(12.0),
                  _ThemeSection(),
                  const Gap(24.0),
                  const ListSubHeading(label: "Language"),
                  const Gap(12.0),
                  _LanguageSection(),
                ]
                .animate(interval: 50.ms)
                .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
      ),
    );
  }
}

class _ThemeSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentMode = themeController.themeMode;

      return Column(
        spacing: 12.0,
        children: [
          _ThemeTile(
            title: "System",
            subtitle: "Automatically adjust to system settings",
            imagePath: system,
            isSelected: currentMode == ThemeMode.system,
            onTap: () {
              HapticFeedback.lightImpact();
              themeController.setSystem();
            },
          ),
          _ThemeTile(
            title: "Bright",
            subtitle:
                "Sets the app’s theme to light with brighter colors. Suitable for daytime.",
            imagePath: light,
            isSelected: currentMode == ThemeMode.light,
            onTap: () {
              HapticFeedback.lightImpact();
              themeController.setLight();
            },
          ),
          _ThemeTile(
            title: "Dimmed",
            subtitle:
                "Sets the app’s theme to dark with darker colors. Easy on the eyes in low light",
            imagePath: dark,
            isSelected: currentMode == ThemeMode.dark,
            onTap: () {
              HapticFeedback.lightImpact();
              themeController.setDark();
            },
          ),
        ],
      );
    });
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius * 2.75,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.0).copyWith(left: 8.0),
              decoration: BoxDecoration(
                color: themeController.isDark
                    ? seedColor.withValues(alpha: 0.4)
                    : isSelected
                    ? seedPalette.shade100.withValues(alpha: 0.6)
                    : seedPalette.shade100.withValues(alpha: 0.4),
                borderRadius: borderRadius * 2.75,
                border: isSelected
                    ? Border.all(
                        color: themeController.isDark
                            ? seedPalette.shade50
                            : seedColor,
                        width: 2.0,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  // Image Preview
                  Image.asset(imagePath, width: 80.0),
                  // Title and Subtitle
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: Theme.of(
                              context,
                            ).listTileTheme.titleTextStyle,
                          ),
                          const Gap(4.0),
                          Text(
                            subtitle,
                            style: Theme.of(context)
                                .listTileTheme
                                .subtitleTextStyle
                                ?.copyWith(fontSize: 14.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Trailing Icon
                  if (!isSelected)
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: HugeIcon(
                        icon: isSelected
                            ? HugeIcons.strokeRoundedCheckmarkCircle02
                            : HugeIcons.strokeRoundedCircle,
                        color: isSelected
                            ? seedColor
                            : (themeController.isDark ? lightColor : seedColor)
                                  .withValues(alpha: 0.5),
                        size: 24.0,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // Selected Pill
        if (isSelected)
          Positioned(
            top: -14.0,
            right: 16.0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: themeController.isDark
                    ? seedPalette.shade100
                    : seedPalette.shade500,
                borderRadius: borderRadius * 1.5,
                border: Border.all(
                  color: themeController.isDark ? seedColor : lightColor,
                  width: 4.0,
                ),
              ),
              child: Text(
                "Selected",
                style: AppTextStyles.small.copyWith(
                  color: seedColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LanguageSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final LocaleController localeController = Get.put(LocaleController());

    return Obx(() {
      final currentLocale = localeController.locale;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          DropdownButtonFormField<Locale>(
            initialValue: currentLocale,
            decoration: InputDecoration(
              filled: true,
              fillColor: themeController.isDark
                  ? seedPalette.shade800
                  : seedPalette.shade50,
              contentPadding: const EdgeInsets.all(16.0),
              border: AppInputBorders.border,
              focusedBorder: AppInputBorders.focusedBorder,
              enabledBorder: AppInputBorders.enabledBorder,
            ),
            icon: const SizedBox.shrink(),
            dropdownColor: themeController.isDark
                ? seedPalette.shade900
                : seedPalette.shade100,
            borderRadius: borderRadius * 2.75,
            items: L10n.all.map((locale) {
              return DropdownMenuItem<Locale>(
                value: locale,
                child: Text(
                  _getLanguageName(locale.languageCode),
                  style: AppTextStyles.body,
                ),
              );
            }).toList(),
            onChanged: (Locale? locale) {
              if (locale == null) return;
              HapticFeedback.lightImpact();

              localeController.setLocale(locale);

              // Show notification snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                buildSnackBar(
                  prefixIcon: HugeIcon(
                    icon: HugeIcons.strokeRoundedLanguageCircle,
                    color: lightColor,
                  ),
                  label: Text(
                    'Language changed to ${_getLanguageName(locale.languageCode)}',
                  ),
                  backgroundColor: infoColor,
                ),
              );
            },
          ),
          // Flag stacked on the right
          Positioned(
            right: 16.0,
            bottom: 0,
            child: Image.asset(
              L10n.getFlag(currentLocale.languageCode),
              width: 80.0,
            ),
          ),
        ],
      );
    });
  }

  String _getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      default:
        return 'English';
    }
  }
}
