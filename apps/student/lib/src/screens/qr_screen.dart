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
import '../qr/boarding_code_image.dart';
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
      if (active && ref.read(qrSecretProvider).hasError) ref.invalidate(qrSecretProvider);
    }
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

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(qrSecretProvider);
        try {
          await ref.read(qrSecretProvider.future);
        } catch (_) {
          // The error state on screen says what happened.
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(BusinSpace.x5),
        children: [
          secret.when(
            loading: () => const Padding(padding: EdgeInsets.only(top: 160), child: Center(child: CircularProgressIndicator())),
            error: (error, _) => _Problem(error: error),
            data: (bytes) => _Code(secret: bytes, security: _security),
          ),
        ],
      ),
    );
  }
}

class _Code extends ConsumerWidget {
  const _Code({required this.secret, required this.security});

  final Uint8List secret;
  final ScreenSecurity security;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final palette = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final access = ref.watch(accessProvider);
    if (access is! Allowed) return const SizedBox.shrink();
    final profile = access.profile;

    final now = ref.read(nowProvider)();
    final code = QrCodeGenerator.generate(secret: secret, studentId: profile.id, now: now);
    final remaining = QrCodeGenerator.secondsRemaining(now);
    final side = (MediaQuery.sizeOf(context).width - BusinSpace.x5 * 2 - BusinSpace.x6 * 2).clamp(180.0, 320.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(l10n.qrTitle, style: text.headlineSmall),
        const SizedBox(height: BusinSpace.x1),
        Text(l10n.qrHint, style: text.bodyMedium?.copyWith(color: palette.muted), textAlign: TextAlign.center),
        const SizedBox(height: BusinSpace.x5),
        Semantics(
          image: true,
          label: l10n.qrImageLabel,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(BusinRadius.lg)),
            child: Padding(
              padding: const EdgeInsets.all(BusinSpace.x6),
              child: ExcludeSemantics(
                child: BoardingCodeImage(key: const ValueKey('boarding-code'), data: code, size: side),
              ),
            ),
          ),
        ),
        const SizedBox(height: BusinSpace.x5),
        Text(profile.fullName, style: text.titleLarge, textAlign: TextAlign.center),
        if (profile.matricule != null) Text(profile.matricule!, style: text.bodyMedium?.copyWith(color: palette.muted)),
        const SizedBox(height: BusinSpace.x4),
        ClipRRect(
          borderRadius: BorderRadius.circular(BusinRadius.xs),
          child: LinearProgressIndicator(
            value: remaining / QrCodeGenerator.windowSeconds,
            minHeight: 8,
            color: palette.accent,
            backgroundColor: palette.surface2,
          ),
        ),
        const SizedBox(height: BusinSpace.x2),
        ExcludeSemantics(child: Text(l10n.qrRefreshesIn('$remaining'), style: text.bodySmall?.copyWith(color: palette.muted))),
        if (security.supported) ...[
          const SizedBox(height: BusinSpace.x5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(icon: HugeIcons.strokeRoundedShield01, size: 16, color: palette.muted),
              const SizedBox(width: BusinSpace.x2),
              Flexible(child: Text(l10n.qrScreenshotsOff, style: text.bodySmall?.copyWith(color: palette.muted))),
            ],
          ),
        ],
      ],
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
