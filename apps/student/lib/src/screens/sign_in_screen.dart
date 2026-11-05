import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../auth/auth_service.dart';
import '../providers.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _busy = false;
  SignInFailure? _failure;

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      // On success the session changes and the router moves on; this screen is gone.
    } on SignInException catch (e) {
      if (mounted) setState(() => _failure = e.reason);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final palette = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final message = switch (_failure) {
      SignInFailure.cancelled => l10n.signInCancelled,
      SignInFailure.notAllowed => l10n.signInNotAllowed,
      SignInFailure.failed => l10n.signInFailed,
      null => null,
    };

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(BusinSpace.x6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: palette.brand, borderRadius: BorderRadius.circular(BusinRadius.lg)),
                      child: Padding(
                        padding: const EdgeInsets.all(BusinSpace.x5),
                        child: HugeIcon(icon: HugeIcons.strokeRoundedBus01, size: 36, color: palette.onBrand),
                      ),
                    ),
                  ),
                  const SizedBox(height: BusinSpace.x6),
                  Text(l10n.signInTitle, style: text.headlineLarge),
                  const SizedBox(height: BusinSpace.x3),
                  Text(l10n.signInSubtitle, style: text.bodyLarge?.copyWith(color: palette.muted)),
                  const SizedBox(height: BusinSpace.x8),
                  BusinButton(label: l10n.signInWithGoogle, onPressed: _busy ? null : _signIn, loading: _busy, expand: true),
                  if (message != null) ...[
                    const SizedBox(height: BusinSpace.x4),
                    Semantics(
                      liveRegion: true,
                      child: Text(message, style: text.bodyMedium?.copyWith(color: palette.bad)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
