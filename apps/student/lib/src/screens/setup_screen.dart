import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/access.dart';
import '../greeting.dart';
import '../profile/profile_form.dart';
import '../providers.dart';

/// The first thing a new student sees after signing in with Google: who they are, for the school. Student number and
/// phone are needed (the driver and the school use them); department and program are optional. When it is saved the
/// access rules let them in and the router moves them on by itself.
class SetupScreen extends ConsumerWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              const SizedBox(height: BusinSpace.x5),
              StaggeredIn(index: 1, child: ProfileForm(profile: profile, submitLabel: l10n.setupSave)),
              const SizedBox(height: BusinSpace.x4),
              Center(child: TextButton(onPressed: () => ref.read(signOutProvider)(), child: Text(l10n.setupNotYou))),
            ],
          ),
        ),
      ),
    );
  }
}
