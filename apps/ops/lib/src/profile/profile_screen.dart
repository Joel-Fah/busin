import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../access.dart';
import '../providers.dart';
import '../scan/scan_providers.dart';
import '../screens/legal_screen.dart';
import 'ops_settings.dart';

/// The staff member's page: who they are, how the app looks and behaves on this phone, what the phone holds (today's
/// list, scans waiting), the legal texts, and signing out (refused while scans wait: they are never dropped).
class OpsProfileScreen extends ConsumerWidget {
  const OpsProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final access = ref.watch(accessProvider);
    final profile = access is OpsAllowed ? access.profile : null;
    final school = ref.watch(schoolProvider).value;
    final settings = ref.watch(opsSettingsProvider);
    final roster = ref.watch(rosterProvider);
    final pending = ref.watch(pendingCountProvider).value ?? 0;
    final zone = school?.timezone ?? 'UTC';
    final list = roster.value;

    Widget heading(String title) => Padding(
          padding: const EdgeInsets.only(top: BusinSpace.x6, bottom: BusinSpace.x2),
          child: Text(title, style: text.titleSmall?.copyWith(color: p.muted)),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: SafeArea(
        child: ContentColumn(
          child: ListView(
            padding: const EdgeInsets.all(BusinSpace.x5),
            children: [
              if (profile != null)
                BusinCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: p.surface2,
                        child: Text(profile.fullName.isEmpty ? '?' : profile.fullName.characters.first.toUpperCase(), style: text.titleLarge),
                      ),
                      const SizedBox(width: BusinSpace.x4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.fullName.isEmpty ? profile.email : profile.fullName, style: text.titleMedium),
                            Text(profile.email, style: text.bodySmall?.copyWith(color: p.muted)),
                            const SizedBox(height: BusinSpace.x2),
                            Wrap(spacing: BusinSpace.x2, runSpacing: BusinSpace.x2, children: [
                              StatusChip(label: profile.role == UserRole.admin ? l10n.roleAdmin : l10n.roleStaff, icon: HugeIcons.strokeRoundedUserShield01),
                              if (school != null) StatusChip(label: school.name, icon: HugeIcons.strokeRoundedSchool),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              heading(l10n.profileAppearance),
              Text(l10n.profileTheme, style: text.bodyMedium),
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
              Text(l10n.profileLanguage, style: text.bodyMedium),
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

              heading(l10n.opsSettingsScanning),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.opsSettingsVibrate),
                value: settings.vibrate,
                onChanged: ref.read(opsSettingsProvider.notifier).setVibrate,
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.opsSettingsSound),
                subtitle: Text(l10n.opsSettingsSoundHint),
                value: settings.sound,
                onChanged: ref.read(opsSettingsProvider.notifier).setSound,
              ),

              heading(l10n.opsSettingsDriving),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.opsSettingsOfferShare),
                subtitle: Text(l10n.opsSettingsOfferShareHint),
                value: settings.offerShare,
                onChanged: ref.read(opsSettingsProvider.notifier).setOfferShare,
              ),

              heading(l10n.opsSettingsPhone),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: HugeIcon(icon: HugeIcons.strokeRoundedKey01, color: list == null ? p.bad : p.fg),
                title: Text(
                  list == null
                      ? l10n.opsKeysMissing
                      : l10n.opsKeysStatus(list.length, MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(const SchoolClock().wallClock(zone, list.downloadedAt)))),
                ),
                trailing: IconButton(
                  tooltip: l10n.opsKeysRefresh,
                  onPressed: roster.isLoading
                      ? null
                      : () => ref.read(rosterProvider.notifier).refresh().catchError((Object _) {
                            if (context.mounted) BusinToast.show(context, l10n.opsKeysMissing, tone: ToastTone.warning);
                          }),
                  icon: HugeIcon(icon: HugeIcons.strokeRoundedRefresh, color: p.fg),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: HugeIcon(icon: HugeIcons.strokeRoundedCloudUpload, color: pending == 0 ? p.muted : p.accent),
                title: Text(l10n.opsPending(pending)),
                trailing: pending == 0
                    ? null
                    : TextButton(
                        onPressed: () async {
                          final report = await ref.read(scanSyncerProvider).run();
                          if (!context.mounted) return;
                          BusinToast.show(context, report.offline ? l10n.opsSettingsNotSent : l10n.opsSettingsAllSent, tone: report.offline ? ToastTone.warning : ToastTone.success);
                        },
                        child: Text(l10n.opsSettingsSendNow),
                      ),
              ),

              heading(l10n.legalTitle),
              const Align(alignment: Alignment.centerLeft, child: LegalLinks()),

              const SizedBox(height: BusinSpace.x6),
              BusinButton(
                label: l10n.profileSignOut,
                variant: BusinButtonVariant.secondary,
                icon: HugeIcons.strokeRoundedLogout01,
                expand: true,
                onPressed: () async {
                  // Scans still on the phone must reach the server first: they are never dropped.
                  if (pending > 0) {
                    BusinToast.show(context, l10n.opsSignOutPending(pending), tone: ToastTone.warning);
                    return;
                  }
                  await ref.read(signOutProvider)();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
