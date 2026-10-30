import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../controllers/locale_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../utils/constants.dart';
import 'default_snack_bar.dart';

class LocalePopupButton extends StatelessWidget {
  const LocalePopupButton({super.key});

  @override
  Widget build(BuildContext context) {
    final LocaleController localeController = Get.find<LocaleController>();
    final locales = L10n.all;

    String _getLabel(Locale locale) {
      switch (locale.languageCode) {
        case 'en':
          return AppLocalizations.of(context)!.language_english;
        case 'fr':
          return AppLocalizations.of(context)!.language_french;
        default:
          return locale.languageCode;
      }
    }

    return Obx(() {
      final current = localeController.locale;

      return PopupMenuButton<Locale>(
        tooltip: AppLocalizations.of(context)!.locale_popup_btn_tooltip,
        padding: EdgeInsetsGeometry.all(16.0),
        onSelected: (Locale selected) {
          localeController.setLocale(selected);

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              buildSnackBar(
                prefixIcon: HugeIcon(
                  icon: HugeIcons.strokeRoundedLanguageCircle,
                  color: lightColor,
                ),
                label: Text(
                  AppLocalizations.of(
                    context,
                  )!.locale_popup_btn_label(_getLabel(selected)),
                ),
              ),
            );
        },
        position: PopupMenuPosition.under,
        borderRadius: borderRadius * 2.75,
        menuPadding: EdgeInsets.zero,
        color: seedPalette.shade50,
        initialValue: current,
        offset: Offset(0, 12),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius * 1.75,
        ),
        clipBehavior: Clip.hardEdge,
        itemBuilder: (context) {
          return locales
              .where((l) => l != current)
              .map(
                (l) => PopupMenuItem<Locale>(
                  value: l,
                  child: Row(
                    children: [
                      Image.asset(L10n.getFlag(l.languageCode), width: 24.0),
                      const SizedBox(width: 8),
                      Text(_getLabel(l), style: AppTextStyles.body,),
                    ],
                  ),
                ),
              )
              .toList();
        },
        child: Row(
          children: [
            Image.asset(
              L10n.getFlag(current.languageCode),
              width: 24.0,
            ),
            const Gap(8.0),
            Text(
              _getLabel(current),
              style: AppTextStyles.body.copyWith(color: lightColor),
            ),
            const Icon(Icons.arrow_drop_down, size: 20.0, color: lightColor,),
          ],
        ),
      );
    });
  }
}
