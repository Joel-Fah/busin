import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../auth/access.dart';
import '../profile/profile_form.dart';
import '../providers.dart';
import '../router.dart';
import '../subscription/subscription_providers.dart';

/// The student's profile, the last tab: who they are to the school, the details they can change, the boarding history
/// and signing out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final access = ref.watch(accessProvider);
    if (access is! Allowed) return const SizedBox.shrink();
    final profile = access.profile;
    final school = ref.watch(schoolProvider).value;
    final material = MaterialLocalizations.of(context);

    Widget row(List<List<dynamic>> icon, String label, String? value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: BusinSpace.x3),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(BusinRadius.sm)),
                child: Padding(padding: const EdgeInsets.all(BusinSpace.x3), child: HugeIcon(icon: icon, size: 20, color: p.muted)),
              ),
              const SizedBox(width: BusinSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: text.labelMedium?.copyWith(color: p.muted)),
                    Text(
                      (value ?? '').trim().isEmpty ? l10n.profileNotSet : value!,
                      style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: (value ?? '').trim().isEmpty ? p.muted : p.fg),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    Future<void> edit() async {
      await showBusinSheet<void>(
        context,
        isScrollControlled: true,
        builder: (sheet) => SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheet).bottom),
          child: Padding(
            padding: const EdgeInsets.all(BusinSpace.x2),
            child: ProfileForm(
              profile: profile,
              submitLabel: l10n.actionSave,
              onSaved: () {
                Navigator.of(sheet).pop();
                BusinToast.show(context, l10n.profileSaved, tone: ToastTone.success);
              },
            ),
          ),
        ),
      );
    }

    Future<void> signOut() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(l10n.profileSignOutTitle),
          content: Text(l10n.profileSignOutBody),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: Text(l10n.actionCancel)),
            TextButton(onPressed: () => Navigator.of(dialog).pop(true), child: Text(l10n.profileSignOut)),
          ],
        ),
      );
      if (confirmed == true) await ref.read(signOutProvider)();
    }

    return ContentColumn(
          child: ListView(
            padding: EdgeInsets.fromLTRB(BusinSpace.x5, BusinSpace.x4, BusinSpace.x5, BusinSpace.x8 + BusinScope.of(context).bottomInset),
            children: [
              StaggeredIn(
                child: Column(
                  children: [
                    UserAvatar(name: profile.fullName, email: profile.email, imageUrl: profile.avatarUrl, size: 96, semanticLabel: profile.fullName),
                    const SizedBox(height: BusinSpace.x4),
                    Text(profile.fullName, style: text.headlineMedium, textAlign: TextAlign.center),
                    const SizedBox(height: BusinSpace.x1),
                    Text(profile.email, style: text.bodyMedium?.copyWith(color: p.muted), textAlign: TextAlign.center),
                    const SizedBox(height: BusinSpace.x3),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: BusinSpace.x2,
                      runSpacing: BusinSpace.x2,
                      children: [
                        StatusChip(label: l10n.accountStatus(profile.status), tone: accountTone(profile.status)),
                        if (school != null) StatusChip(label: school.name, tone: StatusTone.neutral, icon: HugeIcons.strokeRoundedBuilding03),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: BusinSpace.x6),
              StaggeredIn(
                index: 1,
                child: BusinCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: BusinSpace.x3,
                        runSpacing: BusinSpace.x3,
                        children: [
                          Text(l10n.profileDetails, style: text.titleLarge),
                          BusinButton(label: l10n.profileEdit, variant: BusinButtonVariant.secondary, icon: HugeIcons.strokeRoundedEdit02, onPressed: edit),
                        ],
                      ),
                      const SizedBox(height: BusinSpace.x2),
                      row(HugeIcons.strokeRoundedIdVerified, l10n.fieldMatricule, profile.matricule),
                      row(HugeIcons.strokeRoundedSmartPhone01, l10n.fieldPhone, profile.phone),
                      row(HugeIcons.strokeRoundedBuilding03, l10n.fieldDepartment, profile.department),
                      row(HugeIcons.strokeRoundedMortarboard02, l10n.fieldProgram, profile.program),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: BusinSpace.x4),
              StaggeredIn(
                index: 2,
                child: BusinCard(
                  onTap: () {
                    BusinHaptics.light();
                    context.push(Routes.history);
                  },
                  child: Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(BusinRadius.sm)),
                        child: Padding(padding: const EdgeInsets.all(BusinSpace.x3), child: HugeIcon(icon: HugeIcons.strokeRoundedReceiptText, size: 20, color: p.fg)),
                      ),
                      const SizedBox(width: BusinSpace.x3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.profileHistory, style: text.titleMedium),
                            Text(l10n.profileHistoryBody, style: text.bodySmall?.copyWith(color: p.muted)),
                          ],
                        ),
                      ),
                      HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 20, color: p.muted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: BusinSpace.x3),
              Center(child: Text(l10n.profileMemberSince(material.formatMediumDate(profile.createdAt.toLocal())), style: text.bodySmall?.copyWith(color: p.muted))),
              const SizedBox(height: BusinSpace.x6),
              StaggeredIn(index: 3, child: BusinButton(label: l10n.profileSignOut, variant: BusinButtonVariant.danger, icon: HugeIcons.strokeRoundedLogout01, expand: true, onPressed: signOut)),
              const SizedBox(height: BusinSpace.x6),
              Center(child: Text(l10n.profileCredits, style: text.bodySmall?.copyWith(color: p.muted), textAlign: TextAlign.center)),
            ],
          ),
    );
  }
}
