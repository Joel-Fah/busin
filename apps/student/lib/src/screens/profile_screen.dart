import 'package:busin_core/busin_core.dart';
import 'package:busin_app/busin_app.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../area/area_providers.dart';
import '../auth/access.dart';
import '../legal/legal_screen.dart';
import '../profile/payment_preference_card.dart';
import '../profile/profile_form.dart';
import '../profile/school_badge.dart';
import '../providers.dart';
import '../router.dart';
import '../streaks/streak_providers.dart';
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

    final identity = StaggeredIn(
      // Fill the width: a column only as wide as its content sits at the start of a wider card, not in its middle.
      child: SizedBox(
        width: double.infinity,
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
              if (school != null) SchoolBadge(school: school, supabaseUrl: ref.watch(appConfigProvider).supabaseUrl),
            ],
          ),
        ],
      ),
      ),
    );
    final details = StaggeredIn(
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
            row(HugeIcons.strokeRoundedSmartPhone01, l10n.fieldPhone, profile.phone == null ? null : PhoneNumbers.display(profile.phone!)),
            row(HugeIcons.strokeRoundedBuilding03, l10n.fieldDepartment, profile.department),
            row(HugeIcons.strokeRoundedMortarboard02, l10n.fieldProgram, profile.program),
          ],
        ),
      ),
    );
    final history = StaggeredIn(
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
    );
    final notifications = StaggeredIn(
      index: 2,
      child: BusinCard(
        onTap: () {
          BusinHaptics.light();
          context.push(Routes.notifications);
        },
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(BusinRadius.sm)),
              child: Padding(padding: const EdgeInsets.all(BusinSpace.x3), child: HugeIcon(icon: HugeIcons.strokeRoundedNotification03, size: 20, color: p.fg)),
            ),
            const SizedBox(width: BusinSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.notificationsTitle, style: text.titleMedium),
                  Text(l10n.notificationsHint, style: text.bodySmall?.copyWith(color: p.muted)),
                ],
              ),
            ),
            HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 20, color: p.muted),
          ],
        ),
      ),
    );
    final areaLater = ref.watch(areaLaterProvider).value ?? false;
    final myArea = ref.watch(myAreaProvider).value;
    final area = StaggeredIn(
      index: 2,
      child: BusinCard(
        onTap: () {
          BusinHaptics.light();
          context.push(Routes.area);
        },
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(BusinRadius.sm)),
              child: Padding(padding: const EdgeInsets.all(BusinSpace.x3), child: HugeIcon(icon: HugeIcons.strokeRoundedHome01, size: 20, color: p.fg)),
            ),
            const SizedBox(width: BusinSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.areaTitle, style: text.titleMedium),
                  Text(
                    myArea?.label ?? (areaLater ? l10n.areaLaterHint : l10n.areaHint),
                    style: text.bodySmall?.copyWith(color: areaLater && myArea == null ? p.accent : p.muted),
                  ),
                ],
              ),
            ),
            HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 20, color: p.muted),
          ],
        ),
      ),
    );
    final streaks = StaggeredIn(
      index: 2,
      child: BusinCard(
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(BusinRadius.sm)),
              child: Padding(padding: const EdgeInsets.all(BusinSpace.x3), child: HugeIcon(icon: HugeIcons.strokeRoundedFire, size: 20, color: p.fg)),
            ),
            const SizedBox(width: BusinSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.streakTitle, style: text.titleMedium),
                  Text(l10n.streakHint, style: text.bodySmall?.copyWith(color: p.muted)),
                ],
              ),
            ),
            Switch.adaptive(
              value: profile.streakOptIn,
              onChanged: (on) async {
                // Turning on says plainly that it also puts the student on the school's leaderboard.
                if (on) {
                  final yes = await showBusinSheet<bool>(
                    context,
                    builder: (sheet) => Padding(
                      padding: EdgeInsets.all(BusinSheetFrame.contentInset),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.streakOnTitle, style: Theme.of(sheet).textTheme.titleLarge),
                          const SizedBox(height: BusinSpace.x2),
                          Text(l10n.streakOnBody(leaderboardName(profile.fullName)), style: Theme.of(sheet).textTheme.bodyMedium?.copyWith(color: p.muted)),
                          const SizedBox(height: BusinSpace.x5),
                          BusinButton(label: l10n.streakOnAction, expand: true, onPressed: () => Navigator.of(sheet).pop(true)),
                        ],
                      ),
                    ),
                  );
                  if (yes != true) return;
                }
                try {
                  await ref.read(setStreakOptInProvider)(on);
                } catch (_) {
                  if (context.mounted) BusinToast.show(context, l10n.errorGeneric, tone: ToastTone.error);
                }
              },
            ),
          ],
        ),
      ),
    );
    final appearance = StaggeredIn(
      index: 3,
      child: BusinCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.profileAppearance, style: text.titleLarge),
            const SizedBox(height: BusinSpace.x1),
            Text(l10n.profileAppearanceHint, style: text.bodySmall?.copyWith(color: p.muted)),
            const SizedBox(height: BusinSpace.x4),
            Text(l10n.profileTheme, style: text.labelLarge),
            const SizedBox(height: BusinSpace.x2),
            BusinSegmented<ThemeMode>(
              groupLabel: l10n.profileTheme,
              selected: ref.watch(themeModeProvider),
              onChanged: ref.read(themeModeProvider.notifier).choose,
              segments: [
                BusinSegment(value: ThemeMode.system, label: l10n.themeSystem, icon: HugeIcons.strokeRoundedSmartPhone01),
                BusinSegment(value: ThemeMode.light, label: l10n.themeLight, icon: HugeIcons.strokeRoundedSun03),
                BusinSegment(value: ThemeMode.dark, label: l10n.themeDark, icon: HugeIcons.strokeRoundedMoon02),
              ],
            ),
            const SizedBox(height: BusinSpace.x4),
            Text(l10n.profileLanguage, style: text.labelLarge),
            const SizedBox(height: BusinSpace.x2),
            BusinSegmented<String>(
              groupLabel: l10n.profileLanguage,
              selected: ref.watch(localeProvider)?.languageCode ?? 'system',
              onChanged: (code) => ref.read(localeProvider.notifier).choose(code == 'system' ? null : Locale(code)),
              segments: [
                BusinSegment(value: 'system', label: l10n.languageSystem),
                // Each language is named in itself, whatever the app speaks now.
                const BusinSegment(value: 'en', label: 'English'),
                const BusinSegment(value: 'fr', label: 'Français'),
              ],
            ),
          ],
        ),
      ),
    );

    const legal = StaggeredIn(index: 4, child: LegalLinksCard());

    final footer = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: Text(l10n.profileMemberSince(material.formatMediumDate(profile.createdAt.toLocal())), style: text.bodySmall?.copyWith(color: p.muted))),
        const SizedBox(height: BusinSpace.x6),
        StaggeredIn(index: 5, child: BusinButton(label: l10n.profileSignOut, variant: BusinButtonVariant.danger, icon: HugeIcons.strokeRoundedLogout01, expand: true, onPressed: signOut)),
        const SizedBox(height: BusinSpace.x6),
        Center(child: Text(l10n.profileCredits, style: text.bodySmall?.copyWith(color: p.muted), textAlign: TextAlign.center)),
      ],
    );

    final padding = EdgeInsets.fromLTRB(BusinSpace.x5, BusinSpace.x4, BusinSpace.x5, BusinSpace.x8 + BusinScope.of(context).bottomInset);
    final expanded = BusinLayout.of(context).isExpanded;

    // A wide screen, two columns that scroll on their own: who you are, with signing out, stays in place on the left
    // (it scrolls by itself only when the screen is too short for it); the details and the rest scroll on the right.
    if (expanded) {
      final side = EdgeInsets.only(top: padding.top, bottom: padding.bottom);
      return ContentColumn(
        maxWidth: 1180,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding.left),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  padding: side,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BusinCard(child: identity),
                      const SizedBox(height: BusinSpace.x6),
                      footer,
                    ],
                  ),
                ),
              ),
              const SizedBox(width: BusinSpace.x8),
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  padding: side,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [details, const SizedBox(height: BusinSpace.x4), history, const SizedBox(height: BusinSpace.x4), notifications, const SizedBox(height: BusinSpace.x4), area, const PaymentPreferenceCard(), const SizedBox(height: BusinSpace.x4), streaks, const SizedBox(height: BusinSpace.x4), appearance, const SizedBox(height: BusinSpace.x4), legal],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ContentColumn(
      child: ListView(
        padding: padding,
        children: [
          identity,
          const SizedBox(height: BusinSpace.x6),
          details,
          const SizedBox(height: BusinSpace.x4),
          history,
          const SizedBox(height: BusinSpace.x4),
          notifications,
          const SizedBox(height: BusinSpace.x4),
          area,
          const PaymentPreferenceCard(),
          const SizedBox(height: BusinSpace.x4),
          streaks,
          const SizedBox(height: BusinSpace.x4),
          appearance,
          const SizedBox(height: BusinSpace.x4),
          legal,
          const SizedBox(height: BusinSpace.x3),
          footer,
        ],
      ),
    );
  }
}
