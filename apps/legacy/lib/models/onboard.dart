import 'package:busin/l10n/app_localizations.dart';
import 'package:busin/utils/constants.dart';
import 'package:flutter/cupertino.dart';

class Onboard {
  final String image;
  final String title;
  final String subtitle;

  Onboard({
    required this.image,
    required this.title,
    required this.subtitle,
  });
}

List<Onboard> onboardData(BuildContext context) => [
  Onboard(
    image: onboard1,
    title: AppLocalizations.of(context)!.onboarding_screen1_title,
    subtitle: AppLocalizations.of(context)!.onboarding_screen1_subtitle,
  ),
  Onboard(
    image: onboard2,
    title: AppLocalizations.of(context)!.onboarding_screen2_title,
    subtitle: AppLocalizations.of(context)!.onboarding_screen2_subtitle,
  ),
];