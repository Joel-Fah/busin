import 'package:busin/docs/docs.dart';
import 'package:busin/l10n/app_localizations.dart';
import 'package:busin/utils/constants.dart';
import 'package:busin/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../components/widgets/primary_button.dart';
import '../onboarding/auth_modal.dart';

class AnonymousHomePage extends StatelessWidget {
  const AnonymousHomePage({super.key});

  static const String routeName = '/anonymous-home';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80.0,
        title: IntrinsicWidth(
          child: ListTile(
            onTap: () async {
              await showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (ctx) => const AuthModalSheet(),
              );
            },
            contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
            leading: CircleAvatar(
              radius: 24.0,
              backgroundColor: seedPalette.shade50,
              child: HugeIcon(icon: HugeIcons.strokeRoundedUser),
            ),
            title: Text(l10n.anonymousPage_appBar_title),
            subtitle: Align(
              alignment: AlignmentGeometry.centerLeft,
              child: Ink(
                padding: EdgeInsetsGeometry.symmetric(
                  horizontal: 8.0,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: warningColor.withValues(alpha: 0.1),
                  borderRadius: borderRadius,
                ),
                child: Text(
                  l10n.anonymousPage_appBar_subtitle,
                  style: AppTextStyles.small.copyWith(
                    color: warningColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(
          16.0,
        ).copyWith(bottom: MediaQuery.viewPaddingOf(context).bottom + 24),
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(
                child: IgnorePointer(child: _LightBeamBackground()),
              ),
              Image.asset(seat, height: 250),
            ],
          ),
          const Gap(20.0),
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: EdgeInsetsGeometry.symmetric(
                horizontal: 12.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: warningColor.withValues(alpha: 0.1),
                borderRadius: borderRadius * 1.5,
              ),
              child: Row(
                spacing: 8.0,
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(icon: warningIcon, color: warningColor, size: 16.0),
                  Text(
                    l10n.anonymousPage_warningAlert,
                    style: AppTextStyles.body.copyWith(color: warningColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Text(
            l10n.anonymousPage_headline,
            style: AppTextStyles.title.copyWith(fontSize: 44.0),
            textAlign: TextAlign.center,
          ),
          const Gap(16.0),
          Text(
            l10n.anonymousPage_listTitle,
            style: AppTextStyles.h4.copyWith(color: accentColor),
          ),
          const Gap(16.0),
          ListTile(
            onTap: () => openStudentDocs(context, ''),
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedCatalogue,
              color: accentColor,
            ),
            title: Text(l10n.anonymousPage_list_option1Title),
            subtitle: Text(l10n.anonymousPage_list_option1Subtitle),
            trailing: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowUpRight01,
              color: themeController.isDark ? lightColor : seedColor,
            ),
          ),
          const Gap(8.0),
          ListTile(
            onTap: () => openAdminDocs(context, ''),
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedArchive01,
              color: accentColor,
            ),
            title: Text(l10n.anonymousPage_list_option2Title),
            subtitle: Text(l10n.anonymousPage_list_option2Subtitle),
            trailing: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowUpRight01,
              color: themeController.isDark ? lightColor : seedColor,
            ),
          ),
          const Gap(16.0),
          PrimaryButton.label(
            onPressed: () async {
              await showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (ctx) => const AuthModalSheet(),
              );
            },
            label: l10n.onboarding_cta,
          ),
        ],
      ),
    );
  }
}

class _LightBeamBackground extends StatelessWidget {
  const _LightBeamBackground({
    double rotationDelta = 0.0,
    double pushAlong = 0.0,
    double baseAngle = -0.63,
    Offset baseTranslate = const Offset(0.0, 150.0),
    double skewAmount = 0.42,
    double widthFactor = 2.6,
    double beamHeight = 120.0,
  }) : rotationDelta = rotationDelta,
       pushAlong = pushAlong,
       baseAngle = baseAngle,
       baseTranslate = baseTranslate,
       skewAmount = skewAmount,
       widthFactor = widthFactor,
       beamHeight = beamHeight;

  final double rotationDelta;
  final double pushAlong;
  final double baseAngle;
  final Offset baseTranslate;
  final double skewAmount;
  final double widthFactor;
  final double beamHeight;

  @override
  Widget build(BuildContext context) {
    final beamWidth = mediaWidth(context) * widthFactor;
    final angle = baseAngle + rotationDelta;
    final transform = Matrix4.identity()
      ..translateByDouble(baseTranslate.dx, baseTranslate.dy, 0.0, 1.0)
      ..rotateZ(angle)
      ..translateByDouble(pushAlong, 0.0, 0.0, 1.0)
      ..setEntry(0, 1, skewAmount);

    return OverflowBox(
      maxWidth: mediaWidth(context) * 1.5,
      child: Align(
        alignment: Alignment.topCenter,
        child: Transform(
          alignment: Alignment.topCenter,
          transform: transform,
          child: Container(
            width: beamWidth,
            height: beamHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: themeController.isDark
                    ? [
                        seedPalette.shade900.withValues(alpha: 0.0),
                        seedPalette.shade800.withValues(alpha: 0.50),
                        seedPalette.shade900.withValues(alpha: 0.0),
                      ]
                    : [
                        seedPalette.shade50.withValues(alpha: 0.0),
                        seedPalette.shade100.withValues(alpha: 0.50),
                        seedPalette.shade50.withValues(alpha: 0.0),
                      ],
                stops: const [0.0, 0.35, 0.75],
              ),
              boxShadow: [
                BoxShadow(
                  color: seedPalette.shade100.withValues(alpha: 0.28),
                  blurRadius: 70,
                  spreadRadius: 10,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: seedPalette.shade50.withValues(alpha: 0.2),
                  blurRadius: 50,
                  spreadRadius: 4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
