import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';

/// Shown while the session and the profile are being read.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = BusinPalette.of(context);
    return Scaffold(
      body: Center(
        child: Semantics(
          label: BusinL10n.of(context).loadingLabel,
          child: CircularProgressIndicator(color: palette.accent),
        ),
      ),
    );
  }
}
