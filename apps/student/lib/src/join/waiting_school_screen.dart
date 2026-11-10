import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../auth/access.dart';
import '../providers.dart';
import 'join_providers.dart';
import 'school_logo.dart';

/// While a school checks a request to join it (ADR 0012). A pending account cannot get push messages, so the screen
/// checks again whenever the app comes back to the front, and on demand. The student can choose another school.
class WaitingSchoolScreen extends ConsumerStatefulWidget {
  const WaitingSchoolScreen({super.key});

  @override
  ConsumerState<WaitingSchoolScreen> createState() => _WaitingSchoolScreenState();
}

class _WaitingSchoolScreenState extends ConsumerState<WaitingSchoolScreen> {
  late final AppLifecycleListener _lifecycle;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _recheck);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _recheck() {
    ref.invalidate(profileProvider);
    ref.invalidate(myJoinRequestProvider);
  }

  Future<void> _checkNow() async {
    final l10n = BusinL10n.of(context);
    _recheck();
    await ref.read(profileProvider.future).catchError((_) => null);
    if (mounted && ref.read(accessProvider) is AwaitingSchool) BusinToast.show(context, l10n.waitingStill);
  }

  Future<void> _changeSchool() async {
    final l10n = BusinL10n.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(requestSchoolProvider)(null);
    } catch (error) {
      if (mounted) BusinToast.show(context, isTooSoon(error) ? l10n.joinTooSoon : l10n.errorGeneric, tone: ToastTone.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final access = ref.watch(accessProvider);
    if (access is! AwaitingSchool) return const Scaffold(body: SizedBox.shrink());
    final request = ref.watch(myJoinRequestProvider).value;
    final school = request?.schoolName ?? '';
    final asked = request?.requestedAt;
    final date = asked == null ? '' : DateFormat.yMMMMd(Localizations.localeOf(context).toLanguageTag()).format(asked.toLocal());

    return Scaffold(
      body: SafeArea(
        child: ContentColumn(
          child: RefreshIndicator(
            onRefresh: _checkNow,
            // A short page: a scrolling column builds all of it at once, so nothing waits below the fold.
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(BusinSpace.x5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: BusinSpace.x6),
                  const Center(child: Illustration(BusinIllustration.waiting, height: 140)),
                  const SizedBox(height: BusinSpace.x5),
                  if (request?.schoolLogoPath != null) ...[
                    Center(child: SchoolLogo(url: request!.logoUrl(ref.watch(appConfigProvider).supabaseUrl), size: 64)),
                    const SizedBox(height: BusinSpace.x4),
                  ],
                  Text(l10n.waitingTitle(school), textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: BusinSpace.x2),
                  Text(
                    l10n.waitingBody(date),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: p.muted),
                  ),
                  const SizedBox(height: BusinSpace.x6),
                  BusinButton(label: l10n.waitingCheck, expand: true, onPressed: _busy ? null : _checkNow),
                  const SizedBox(height: BusinSpace.x3),
                  BusinButton(
                    label: l10n.waitingChange,
                    variant: BusinButtonVariant.secondary,
                    expand: true,
                    loading: _busy,
                    onPressed: _busy ? null : _changeSchool,
                  ),
                  const SizedBox(height: BusinSpace.x4),
                  Center(
                    child: TextButton(onPressed: () => ref.read(signOutProvider)(), child: Text(l10n.actionSignOut)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
