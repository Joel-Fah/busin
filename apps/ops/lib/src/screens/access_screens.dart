import 'package:busin_app/busin_app.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../access.dart';
import '../providers.dart';
import 'staff_request_panel.dart';

/// While the session and the profile load.
class LoadingScreen extends ConsumerWidget {
  const LoadingScreen({super.key});

  /// The mark's width on the native splash (144 dp), so the hand-off from it shows no jump.
  static const markWidth = 144.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : BusinRamps.seed;
    // On a cold start the logo draws itself once (a tap skips it), where the native splash left it; then the finished
    // mark stays with the spinner below while the session is read.
    final introDone = ref.watch(introDoneProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        // The native splash's colours: the light page in light mode, the brand teal in dark mode.
        backgroundColor: dark ? BusinRamps.seed : BusinPalette.of(context).bg,
        body: Stack(
          children: [
            // Exactly in the middle, where the splash drew it; the spinner sits under it without moving it.
            Center(
              child: SizedBox(
                key: const ValueKey('loading-mark'),
                width: markWidth,
                height: markWidth * 126 / 205,
                child: introDone
                    ? FittedBox(child: BrandMark(color: ink, height: 100, semanticLabel: BusinL10n.of(context).opsAppName))
                    : BrandIntro(color: ink, width: markWidth, onDone: ref.read(introDoneProvider.notifier).finish),
              ),
            ),
            if (introDone)
              Align(
                alignment: const Alignment(0, 0.45),
                child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3, color: ink.withValues(alpha: 0.8))),
              ),
          ],
        ),
      ),
    );
  }
}

/// A signed-in person who may not use the ops app: a student, or a suspended account.
class BlockedScreen extends ConsumerWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final access = ref.watch(accessProvider);
    final reason = access is OpsBlocked ? access.reason : OpsBlockReason.notStaff;
    final (title, body, art) = switch (reason) {
      OpsBlockReason.notStaff => (l10n.opsNotStaffTitle, l10n.opsNotStaffBody, BusinIllustration.staff),
      OpsBlockReason.pending => (l10n.opsPendingTitle, l10n.opsPendingBody, BusinIllustration.waiting),
      OpsBlockReason.suspended => (l10n.blockedSuspendedTitle, l10n.blockedSuspendedBody, BusinIllustration.blocked),
    };
    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          illustration: art,
          title: title,
          body: body,
          // A student account (signed in before being invited) can ask a school for staff access here (ADR 0026).
          action: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (reason == OpsBlockReason.notStaff) ...[const StaffRequestPanel(), const SizedBox(height: BusinSpace.x3)],
              BusinButton(label: l10n.actionSignOut, variant: BusinButtonVariant.ghost, onPressed: () => ref.read(signOutProvider)()),
              // Deleting the account stays possible from here (ADR 0028).
              DeleteAccountLink(repository: ref.watch(accountDeletionRepositoryProvider)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The account could not be read: offline at first launch, or a server problem.
class ProblemScreen extends ConsumerWidget {
  const ProblemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          illustration: BusinIllustration.waiting,
          title: l10n.opsProblemTitle,
          body: l10n.opsProblemBody,
          action: Wrap(
            spacing: BusinSpace.x3,
            runSpacing: BusinSpace.x3,
            alignment: WrapAlignment.center,
            children: [
              BusinButton(label: l10n.actionRetry, onPressed: () => ref.invalidate(profileProvider)),
              BusinButton(label: l10n.actionSignOut, variant: BusinButtonVariant.secondary, onPressed: () => ref.read(signOutProvider)()),
            ],
          ),
        ),
      ),
    );
  }
}
