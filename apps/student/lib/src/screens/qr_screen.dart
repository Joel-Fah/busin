import 'dart:async';
import 'dart:typed_data';

import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../auth/access.dart';
import '../providers.dart';
import '../qr/boarding_ticket.dart';
import '../qr/qr_providers.dart';
import '../qr/screen_security.dart';
import '../router.dart';

/// The second tab: the boarding code. A new code is derived on the phone every 30 seconds from the secret,
/// so it works without a connection once the secret is stored. While this tab is on screen the window is
/// marked secure (Android), and a timer that idles while the tab is hidden keeps the code and countdown fresh.
class QrScreen extends ConsumerStatefulWidget {
  const QrScreen({super.key});

  @override
  ConsumerState<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends ConsumerState<QrScreen> {
  Timer? _timer;
  late final ScreenSecurity _security;
  int _second = 0;
  bool? _active;

  @override
  void initState() {
    super.initState();
    _security = ref.read(screenSecurityProvider);
    _second = ref.read(nowProvider)().millisecondsSinceEpoch ~/ 1000;
    // Twice a second is enough: rebuild only when the second changes, and not at all while this tab is hidden.
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_active != true) return;
      final second = ref.read(nowProvider)().millisecondsSinceEpoch ~/ 1000;
      if (second != _second) setState(() => _second = second);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tabs that are not showing have animations switched off; use that to know when this one is on screen.
    final active = TickerMode.valuesOf(context).enabled;
    if (active != _active) {
      _active = active;
      _security.setSecure(active);
      // Coming back after a failure (for example the subscription was approved meanwhile): try again.
      if (active && ref.read(qrSecretProvider).hasError) {
        // After this frame: a provider cannot be changed while the tree is building.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ref.invalidate(qrSecretProvider);
        });
      }
    }
  }

  /// The first time the code is on screen in a session, a short reminder to keep it private (a toast, not a fixture
  /// on the page). It mentions screenshots only where they are really blocked.
  void _tellOnce(AsyncValue<Uint8List> secret) {
    if (!secret.hasValue || _active != true || ref.read(qrPrivacyToldProvider)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ref.read(qrPrivacyToldProvider)) return;
      ref.read(qrPrivacyToldProvider.notifier).told();
      final l10n = BusinL10n.of(context);
      BusinToast.show(
        context,
        _security.supported ? l10n.qrPrivateBodyProtected : l10n.qrPrivateBody,
        title: l10n.qrPrivateTitle,
        tone: ToastTone.warning,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _security.setSecure(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final secret = ref.watch(qrSecretProvider);
    _tellOnce(secret);

    // On a wide screen the page is two columns, so it may use the width.
    return ContentColumn(
      maxWidth: BusinLayout.of(context).isExpanded ? 1180 : BusinLayout.maxColumn,
      child: RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(qrSecretProvider);
        try {
          await ref.read(qrSecretProvider.future);
          if (context.mounted) BusinToast.show(context, BusinL10n.of(context).qrRefreshed, tone: ToastTone.success);
        } catch (_) {
          // The error state on screen says what happened.
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(BusinSpace.x5, BusinSpace.x5, BusinSpace.x5, BusinSpace.x5 + BusinScope.of(context).bottomInset),
        children: [
          secret.when(
            loading: () => const _CodeSkeleton(),
            error: (error, _) => _Problem(error: error),
            data: (bytes) => _Code(secret: bytes),
          ),
        ],
      ),
      ),
    );
  }
}

class _Code extends ConsumerWidget {
  const _Code({required this.secret});

  final Uint8List secret;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final palette = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final access = ref.watch(accessProvider);
    if (access is! Allowed) return const SizedBox.shrink();
    final profile = access.profile;
    final expanded = BusinLayout.of(context).isExpanded;

    final code = QrCodeGenerator.generate(secret: secret, studentId: profile.id, now: ref.read(nowProvider)());

    final ticket = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(0.0, 380.0);
        // The sticker's side: the ticket's width less the ticket's padding and the sticker's own.
        final side = (width - BusinSpace.x6 * 2 - BusinSpace.x5 * 2).clamp(160.0, 300.0);
        return Center(
          child: SizedBox(
            width: width,
            child: BoardingTicket(
              code: code,
              name: profile.fullName,
              matricule: profile.matricule,
              size: side,
              liveLabel: l10n.qrLive,
              imageLabel: l10n.qrImageLabel,
            ),
          ),
        );
      },
    );

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.qrTitle, style: text.headlineMedium),
        const SizedBox(height: BusinSpace.x1),
        Text(l10n.qrHint, style: text.bodyLarge?.copyWith(color: palette.muted)),
        const SizedBox(height: BusinSpace.x5),
      ],
    );

    if (!expanded) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [heading, StaggeredIn(child: ticket)]);
    }
    // A wide screen, two columns: the words and how to board on the left, the ticket alone in the right one.
    return SplitView(
      primary: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [heading, StaggeredIn(child: const _BoardingSteps())]),
      secondary: StaggeredIn(index: 1, child: ticket),
      primaryFlex: 5,
      secondaryFlex: 5,
      gap: BusinSpace.x8,
    );
  }
}

class _BoardingSteps extends StatelessWidget {
  const _BoardingSteps();

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final steps = [l10n.boardStep1, l10n.boardStep2, l10n.boardStep3];
    return BusinCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(l10n.boardTitle, style: text.titleLarge)),
              const Illustration(BusinIllustration.seat, width: 72, height: 72),
            ],
          ),
          const SizedBox(height: BusinSpace.x4),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: BusinSpace.x4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(BusinRadius.xs)),
                    alignment: Alignment.center,
                    child: Text('${i + 1}', style: text.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: BusinSpace.x3),
                  Expanded(child: Padding(padding: const EdgeInsets.only(top: 5), child: Text(steps[i], style: text.bodyLarge))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// What is wrong, in the student's terms, with a way forward.
class _Problem extends ConsumerWidget {
  const _Problem({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    Widget retry() => BusinButton(label: l10n.actionRetry, onPressed: () => ref.invalidate(qrSecretProvider));

    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: switch (error) {
        NotAllowed() => EmptyState(
            icon: HugeIcons.strokeRoundedTicket03,
            title: l10n.qrNoSubscriptionTitle,
            body: l10n.qrNoSubscriptionBody,
            action: BusinButton(label: l10n.qrGoToSubscription, onPressed: () => context.go(Routes.subscription)),
          ),
        Offline() => EmptyState(icon: HugeIcons.strokeRoundedWifiDisconnected01, title: l10n.qrOfflineTitle, body: l10n.qrOfflineBody, action: retry()),
        _ => EmptyState(icon: HugeIcons.strokeRoundedAlert02, title: l10n.errorGeneric, action: retry()),
      },
    );
  }
}

/// What the page looks like while it finds out whether there is a subscription: the same layout as the ticket, with
/// shimmering blocks where the heading, the code and the name will be, so nothing jumps when the real page arrives.
class _CodeSkeleton extends StatelessWidget {
  const _CodeSkeleton();

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final expanded = BusinLayout.of(context).isExpanded;

    Widget bars(List<double> widths, {double height = 16}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final w in widths) Padding(padding: const EdgeInsets.only(bottom: BusinSpace.x2), child: Skeleton(width: w, height: height))],
        );

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Skeleton(width: 200, height: 30, radius: BusinRadius.xs),
        const SizedBox(height: BusinSpace.x3),
        bars(const [260, 180]),
        const SizedBox(height: BusinSpace.x4),
      ],
    );

    final ticket = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(0.0, 380.0);
        final side = (width - BusinSpace.x6 * 2 - BusinSpace.x5 * 2).clamp(160.0, 300.0);
        return Center(
          child: SizedBox(
            width: width,
            child: BusinCard(
              child: Column(
                children: [
                  Row(children: [const Skeleton(width: 96, height: 14), const Spacer(), const Skeleton(width: 56, height: 22, radius: BusinRadius.xs)]),
                  const SizedBox(height: BusinSpace.x5),
                  Skeleton(width: side + BusinSpace.x5 * 2, height: side + BusinSpace.x5 * 2, radius: BusinRadius.md),
                  const SizedBox(height: BusinSpace.x5),
                  const Skeleton(width: 160, height: 20),
                  const SizedBox(height: BusinSpace.x2),
                  const Skeleton(width: 110, height: 14),
                ],
              ),
            ),
          ),
        );
      },
    );

    final steps = BusinCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Skeleton(width: 140, height: 22),
          const SizedBox(height: BusinSpace.x4),
          for (var i = 0; i < 3; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: BusinSpace.x4),
              child: Row(children: [Skeleton(width: 32, height: 32, radius: BusinRadius.xs), SizedBox(width: BusinSpace.x3), Expanded(child: Skeleton(height: 16))]),
            ),
        ],
      ),
    );

    return Semantics(
      liveRegion: true,
      label: l10n.qrChecking,
      child: ExcludeSemantics(
        child: expanded
            ? SplitView(primary: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [heading, steps]), secondary: ticket, primaryFlex: 5, secondaryFlex: 5, gap: BusinSpace.x8)
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [heading, ticket]),
      ),
    );
  }
}
