import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../auth/access.dart';
import '../providers.dart';
import 'join_providers.dart';
import 'school_logo.dart';

/// For a student without a school email (ADR 0012): the schools that accept their email, a search, and a way to ask to
/// join one. If a school declined them before, that is said first, with the reason.
class ChooseSchoolScreen extends ConsumerStatefulWidget {
  const ChooseSchoolScreen({super.key});

  @override
  ConsumerState<ChooseSchoolScreen> createState() => _ChooseSchoolScreenState();
}

class _ChooseSchoolScreenState extends ConsumerState<ChooseSchoolScreen> {
  String _query = '';
  bool _sending = false;

  Future<void> _ask(OpenSchool school) async {
    final l10n = BusinL10n.of(context);
    final confirmed = await showBusinSheet<bool>(
      context,
      builder: (context) => Padding(
        padding: EdgeInsets.all(BusinSheetFrame.contentInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SchoolLogo(url: school.logoUrl(ref.read(appConfigProvider).supabaseUrl), size: 56),
            const SizedBox(height: BusinSpace.x3),
            Text(l10n.joinConfirmTitle(school.name), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: BusinSpace.x2),
            Text(l10n.joinConfirmBody(school.name), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: BusinPalette.of(context).muted)),
            const SizedBox(height: BusinSpace.x5),
            BusinButton(label: l10n.joinConfirmAction, expand: true, onPressed: () => Navigator.of(context).pop(true)),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _sending = true);
    try {
      await ref.read(requestSchoolProvider)(school.id);
      if (mounted) BusinToast.show(context, l10n.joinSent, tone: ToastTone.success);
    } catch (error) {
      if (mounted) BusinToast.show(context, isTooSoon(error) ? l10n.joinTooSoon : l10n.errorGeneric, tone: ToastTone.error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    if (ref.watch(accessProvider) is! NeedsSchool) return const Scaffold(body: SizedBox.shrink());
    final schools = ref.watch(openSchoolsProvider);
    final request = ref.watch(myJoinRequestProvider).value;
    final url = ref.watch(appConfigProvider).supabaseUrl;
    final needle = _query.trim().toLowerCase();

    Widget list(List<OpenSchool> all) {
      if (all.isEmpty) {
        return EmptyState(illustration: BusinIllustration.waiting, title: l10n.joinEmptyTitle, body: l10n.joinEmptyBody);
      }
      final shown = all.where((s) => needle.isEmpty || '${s.name} ${s.shortName ?? ''} ${s.place ?? ''}'.toLowerCase().contains(needle)).toList();
      return Column(
        children: [
          BusinTextField(
            label: l10n.joinSearch,
            icon: HugeIcons.strokeRoundedSearch01,
            hint: l10n.joinSearchHint,
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: BusinSpace.x4),
          if (shown.isEmpty)
            Padding(padding: const EdgeInsets.all(BusinSpace.x4), child: Text(l10n.joinNoMatch, style: TextStyle(color: p.muted)))
          else
            for (final school in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: BusinSpace.x3),
                child: BusinCard(
                  padding: const EdgeInsets.all(BusinSpace.x4),
                  onTap: _sending ? null : () => _ask(school),
                  child: Row(
                    children: [
                      SchoolLogo(url: school.logoUrl(url)),
                      const SizedBox(width: BusinSpace.x4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(school.name, style: Theme.of(context).textTheme.titleMedium),
                            if (school.place != null) Text(school.place!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: p.muted)),
                          ],
                        ),
                      ),
                      HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 20, color: p.muted),
                    ],
                  ),
                ),
              ),
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ContentColumn(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(openSchoolsProvider),
            child: ListView(
              padding: const EdgeInsets.all(BusinSpace.x5),
              children: [
                StaggeredIn(child: BusinBanner(title: l10n.joinTitle, body: l10n.joinBody, art: BusinIllustration.papers, minHeight: 180)),
                if (request != null && request.wasDeclined) ...[
                  const SizedBox(height: BusinSpace.x4),
                  Notice(
                    tone: StatusTone.warn,
                    title: l10n.joinDeclinedTitle(request.declinedSchoolName ?? ''),
                    child: Text(request.declineNote == null ? l10n.joinDeclinedNoReason : l10n.joinDeclinedReason(request.declineNote!)),
                  ),
                ],
                const SizedBox(height: BusinSpace.x5),
                StaggeredIn(
                  index: 1,
                  child: schools.when(
                    data: list,
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(BusinSpace.x6), child: CircularProgressIndicator())),
                    error: (_, _) => EmptyState(
                      illustration: BusinIllustration.blocked,
                      title: l10n.errorGeneric,
                      action: BusinButton(label: l10n.actionRetry, variant: BusinButtonVariant.secondary, onPressed: () => ref.invalidate(openSchoolsProvider)),
                    ),
                  ),
                ),
                const SizedBox(height: BusinSpace.x4),
                Center(child: TextButton(onPressed: () => ref.read(signOutProvider)(), child: Text(l10n.actionSignOut))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
