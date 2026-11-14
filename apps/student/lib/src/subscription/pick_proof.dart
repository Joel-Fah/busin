import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'proof_picker.dart';
import 'subscription_providers.dart';

/// Asks camera or photos, then picks the receipt. Null when the student backs out. A photo that cannot be used is told
/// through [onProblem] with the words to show.
Future<PickedProof?> pickProof(BuildContext context, WidgetRef ref, {required void Function(String message) onProblem}) async {
  final l10n = BusinL10n.of(context);
  final source = await showBusinSheet<ProofSource>(
    context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const HugeIcon(icon: HugeIcons.strokeRoundedCamera01),
            title: Text(l10n.proofTakePhoto),
            onTap: () => Navigator.of(context).pop(ProofSource.camera),
          ),
          ListTile(
            leading: const HugeIcon(icon: HugeIcons.strokeRoundedImage01),
            title: Text(l10n.proofChoosePhoto),
            onTap: () => Navigator.of(context).pop(ProofSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;
  try {
    return await ref.read(proofPickerProvider).pick(source);
  } on ProofException catch (e) {
    onProblem(e.problem == ProofProblem.type ? l10n.subscribeErrorType : l10n.subscribeErrorTooLarge);
    return null;
  }
}
