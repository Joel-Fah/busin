import 'package:busin_app/busin_app.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../providers.dart';
import 'legal_screen.dart';

/// Staff sign in with their school Google account. Who may use the app is decided after sign-in, from the profile.
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
      // On success the session changes and the router moves on.
    } on SignInException catch (e) {
      if (mounted) setState(() => _failure = e.reason);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final failure = switch (_failure) {
      null => null,
      SignInFailure.cancelled => l10n.signInCancelled,
      SignInFailure.notAllowed => l10n.signInNotAllowed,
      SignInFailure.failed => l10n.signInFailed,
    };
    return Scaffold(
      body: SafeArea(
        child: ContentColumn(
          child: ListView(
            padding: const EdgeInsets.all(BusinSpace.x6),
            children: [
              const SizedBox(height: BusinSpace.x8),
              Row(
                children: [
                  BrandMark(color: p.fg, height: 36),
                  const SizedBox(width: BusinSpace.x3),
                  StatusChip(label: l10n.roleStaff, icon: HugeIcons.strokeRoundedUserShield01),
                ],
              ),
              const SizedBox(height: BusinSpace.x8),
              Text(l10n.opsSignInTitle, style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: BusinSpace.x3),
              Text(l10n.opsSignInSubtitle, style: text.bodyLarge?.copyWith(color: p.muted)),
              const SizedBox(height: BusinSpace.x8),
              BusinButton(
                label: l10n.signInWithGoogle,
                leading: const GoogleMark(),
                expand: true,
                loading: _busy,
                onPressed: _busy ? null : _signIn,
              ),
              if (failure != null) ...[
                const SizedBox(height: BusinSpace.x4),
                Notice(tone: StatusTone.warn, child: Text(failure)),
              ],
              const SizedBox(height: BusinSpace.x8),
              const LegalLinks(),
            ],
          ),
        ),
      ),
    );
  }
}
