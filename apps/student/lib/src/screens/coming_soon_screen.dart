import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Stands in for the screens built in the next slices of Phase 3.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    return EmptyState(icon: HugeIcons.strokeRoundedConstruction, title: l10n.comingSoonTitle, body: l10n.comingSoonBody);
  }
}
