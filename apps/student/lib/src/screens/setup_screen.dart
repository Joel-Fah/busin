import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../area/area_providers.dart';
import '../auth/access.dart';
import '../greeting.dart';
import '../join/join_providers.dart';
import '../join/school_logo.dart';
import '../profile/profile_form.dart';
import '../providers.dart';

/// The first thing a new student sees after signing in with Google: who they are, for the school. Student number and
/// phone are needed (the driver and the school use them); department and program are optional. When it is saved the
/// access rules let them in and the router moves them on by itself.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  @override
  void initState() {
    super.initState();
    // Noted before saving, because saving lets the student in and the router moves on at once: the first landing after
    // setup then offers My area (ADR 0023).
    ref.read(markAreaIntroProvider)();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final access = ref.watch(accessProvider);
    if (access is! NeedsSetup) return const Scaffold(body: SizedBox.shrink());
    final profile = access.profile;
    final first = firstNameOf(profile.fullName);

    return Scaffold(
      body: SafeArea(
        child: ContentColumn(
          child: ListView(
            padding: const EdgeInsets.all(BusinSpace.x5),
            children: [
              StaggeredIn(
                child: BusinBanner(
                  title: l10n.setupWelcome(first.isEmpty ? profile.email : first),
                  body: l10n.setupBody,
                  art: BusinIllustration.papers,
                  minHeight: 200,
                ),
              ),
              if (ref.watch(setupSchoolProvider).value case final school?) ...[
                const SizedBox(height: BusinSpace.x4),
                StaggeredIn(index: 1, child: _JoiningCard(school: school)),
              ],
              const SizedBox(height: BusinSpace.x5),
              StaggeredIn(index: 2, child: ProfileForm(profile: profile, submitLabel: l10n.setupSave)),
              const SizedBox(height: BusinSpace.x4),
              Center(child: TextButton(onPressed: () => ref.read(signOutProvider)(), child: Text(l10n.setupNotYou))),
            ],
          ),
        ),
      ),
    );
  }
}

/// "You are joining X", with the school's logo, and a way out for someone who signed in with the wrong account.
class _JoiningCard extends ConsumerWidget {
  const _JoiningCard({required this.school});

  final School school;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    return BusinCard(
      padding: const EdgeInsets.all(BusinSpace.x4),
      child: Row(
        children: [
          SchoolLogo(url: school.logoUrl(ref.watch(appConfigProvider).supabaseUrl), size: 52),
          const SizedBox(width: BusinSpace.x4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.joiningTitle(school.name), style: text.titleMedium),
                Text(l10n.joiningBody, style: text.bodySmall?.copyWith(color: p.muted)),
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  onPressed: () => showBusinSheet<void>(
                    context,
                    builder: (sheet) => Padding(
                      padding: EdgeInsets.all(BusinSheetFrame.contentInset),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.joiningNotMineTitle, style: Theme.of(sheet).textTheme.titleLarge),
                          const SizedBox(height: BusinSpace.x2),
                          Text(l10n.joiningNotMineBody(school.name), style: Theme.of(sheet).textTheme.bodyMedium?.copyWith(color: p.muted)),
                          const SizedBox(height: BusinSpace.x5),
                          BusinButton(
                            label: l10n.actionSignOut,
                            expand: true,
                            onPressed: () {
                              Navigator.of(sheet).pop();
                              ref.read(signOutProvider)();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  child: Text(l10n.joiningNotMine),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
