import 'package:busin/controllers/auth_controller.dart';
import 'package:busin/models/scannings.dart';
import 'package:busin/ui/components/widgets/custom_list_tile.dart';
import 'package:busin/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../models/actors/roles.dart';
import '../../../utils/constants.dart';
import '../../components/widgets/home/appbar_list_tile.dart';
import '../../components/widgets/user_avatar.dart';
import '../profile/profile.dart';

class ScanningsTab extends StatelessWidget {
  const ScanningsTab({super.key});
  static const String routeName = '/scannings_tab';

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: AppBarListTile(
          onTap: () => context.pushNamed(
            removeLeadingSlash(ProfilePage.routeName),
            pathParameters: {'tag': authController.userProfileImage},
          ),
          leading: UserAvatar(tag: authController.userProfileImage,),
          title: authController.userDisplayName,
          subtitle: authController.isVerified
              ? AccountStatus.verified.label
              : AccountStatus.pending.label,
          subtitleColor: authController.isVerified ? successColor : infoColor,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: ClipRSuperellipse(
              borderRadius: borderRadius * 8.0,
              child:
                  Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: themeController.isDark
                                ? [
                                    seedPalette.shade800.withValues(alpha: 0.8),
                                    seedPalette.shade900.withValues(alpha: 0.3),
                                  ]
                                : [
                                    seedPalette.shade50.withValues(alpha: 0.8),
                                    seedPalette.shade100.withValues(alpha: 0.5),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0),
                              blurRadius: 17.0,
                              offset: const Offset(0, 62),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 16.0,
                              offset: const Offset(0, 40),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 13.0,
                              offset: const Offset(0, 22),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 5.0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRSuperellipse(
                          borderRadius: borderRadius * 6.0,
                          child: QrImageView(
                            data: authController.currentUser.value!.id
                                .toString(),
                            backgroundColor: lightColor,
                            padding: EdgeInsets.all(20),
                            dataModuleStyle: QrDataModuleStyle(
                              color: seedColor,
                              dataModuleShape: QrDataModuleShape.circle,
                            ),
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.circle,
                              color: seedColor,
                            ),
                            gapless: false,
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                      .slideY(
                        begin: 0.05,
                        end: 0,
                        duration: 350.ms,
                        curve: Curves.easeOut,
                      )
                      .scale(
                        begin: const Offset(0.98, 0.98),
                        end: const Offset(1, 1),
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child:
                Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Scannings",
                          style: AppTextStyles.title.copyWith(fontSize: 48.0),
                        ),
                        TextButton.icon(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            overlayColor: accentColor.withValues(alpha: 0.1),
                          ),
                          iconAlignment: IconAlignment.end,
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowUpRight02,
                          ),
                          label: Text(
                            "View all",
                            style: AppTextStyles.body.copyWith(fontSize: 14.0),
                          ),
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                    .slideY(
                      begin: 0.06,
                      end: 0,
                      duration: 380.ms,
                      curve: Curves.easeOut,
                    ),
          ),
          const Gap(20.0),
          Expanded(
            child: Container(
              constraints: BoxConstraints(maxHeight: 300.0),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32.0),
                ),
                color: themeController.isDark
                    ? seedPalette.shade900
                    : seedPalette.shade50,
              ),
              child: ListView(
                padding: EdgeInsets.all(16.0),
                children: [
                  Text(
                        "Latest activity",
                        style: AppTextStyles.h3.copyWith(
                          fontWeight: FontWeight.normal,
                          fontVariations: [FontVariation('wght', 400)],
                          fontSize: 24.0,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 320.ms, curve: Curves.easeOut)
                      .slideY(
                        begin: 0.08,
                        end: 0,
                        duration: 420.ms,
                        curve: Curves.easeOut,
                      ),
                  const Gap(20.0)
                      .animate()
                      .fadeIn(duration: 350.ms)
                      .scale(
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1, 1),
                        duration: 420.ms,
                      ),
                  CustomListTile(
                        onTap: () {},
                        primaryPillLabel:
                            "#" +
                            (dummyScannings.indexOf(dummyScannings.last) + 1)
                                .toString(),
                        title: Text(
                          dummyScannings.last.location,
                          style: Theme.of(context).listTileTheme.titleTextStyle
                              ?.copyWith(color: accentColor),
                        ),
                        subtitle: Row(
                          spacing: 8.0,
                          children: [
                            Text(
                              "On: ${dateTimeFormatter(dummyScannings.last.scanTime)}",
                            ),
                            Expanded(child: Divider()),
                            Text(dummyScannings.last.location),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 380.ms, curve: Curves.easeOut)
                      .slideY(
                        begin: 0.1,
                        end: 0,
                        duration: 450.ms,
                        curve: Curves.easeOut,
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
