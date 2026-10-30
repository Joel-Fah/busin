import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../controllers/auth_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/constants.dart';
import '../../../utils/utils.dart';
import 'default_snack_bar.dart';

const String _kSkipSignOutConfirmKey = 'skip_sign_out_confirm';

Future<void> performSignOut(
  BuildContext context, {
  required AuthController authController,
  required AppLocalizations l10n,
}) async {
  HapticFeedback.heavyImpact();
  await authController.signOut().then(
    (_) => snackBarKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        buildSnackBar(
          backgroundColor: successColor,
          prefixIcon: HugeIcon(icon: successIcon, color: lightColor),
          label: Text(l10n.verificationPage_signOutMessage),
        ),
      ),
  );
}

Future<void> showSignOutConfirmation(
  BuildContext context, {
  required AuthController authController,
  required AppLocalizations l10n,
}) async {
  final storage = GetStorage();
  final skip = storage.read<bool>(_kSkipSignOutConfirmKey) ?? false;

  if (skip) {
    await performSignOut(context, authController: authController, l10n: l10n);
    return;
  }

  bool dontAskAgain = false;

  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.paddingOf(ctx).bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: borderRadius * 2.0,
                  ),
                ),
                const Gap(20),
                // Content
                Container(
                  decoration: BoxDecoration(
                    gradient: themeController.isDark
                        ? darkGradient
                        : lightGradient,
                    borderRadius: borderRadius * 3.0,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView(
                    padding: EdgeInsets.all(20.0),
                    shrinkWrap: true,
                    children: [
                      // Title
                      Text(
                        l10n.signOut_confirmTitle,
                        style: AppTextStyles.h2.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(8),
                      // Message
                      Text(
                        l10n.signOut_confirmMessage,
                        style: AppTextStyles.body.copyWith(color: greyColor),
                      ),
                      const Gap(20),
                      // Checkbox
                      InkWell(
                        borderRadius: borderRadius * 2.0,
                        onTap: () =>
                            setModalState(() => dontAskAgain = !dontAskAgain),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: dontAskAgain,
                                  onChanged: (v) => setModalState(
                                    () => dontAskAgain = v ?? false,
                                  ),
                                  activeColor: accentColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: borderRadius,
                                  ),
                                ),
                              ),
                              const Gap(10),
                              Expanded(
                                child: Text(
                                  l10n.signOut_dontShowAgain,
                                  style: AppTextStyles.body,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Gap(20),
                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: greyColor.withValues(alpha: 0.4),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: borderRadius * 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: Text(
                                l10n.signOut_cancelButton,
                                style: AppTextStyles.body,
                              ),
                            ),
                          ),
                          const Gap(12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: errorColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: borderRadius * 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: Text(
                                l10n.signOut_confirmButton,
                                style: AppTextStyles.body.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  if (confirmed == true) {
    if (dontAskAgain) {
      storage.write(_kSkipSignOutConfirmKey, true);
    }
    if (context.mounted) {
      await performSignOut(context, authController: authController, l10n: l10n);
    }
  }
}
