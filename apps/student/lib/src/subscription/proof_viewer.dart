import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Shows a stored proof full screen: pinch to zoom, drag to look around, tap the cross (or go back) to close. [address]
/// is the short-lived signed address the thumbnail already loaded.
Future<void> showProofViewer(BuildContext context, String address) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: BusinMotion.of(context, BusinMotion.normal),
      reverseTransitionDuration: BusinMotion.of(context, BusinMotion.fast),
      pageBuilder: (_, _, _) => _ProofViewer(address: address),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: CurvedAnimation(parent: animation, curve: BusinMotion.soft), child: child),
    ),
  );
}

class _ProofViewer extends StatelessWidget {
  const _ProofViewer({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Center(
              child: Image.network(
                address,
                fit: BoxFit.contain,
                semanticLabel: l10n.subscriptionProofTitle,
                loadingBuilder: (_, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(BusinSpace.x3),
                child: Semantics(
                  button: true,
                  label: l10n.proofClose,
                  child: Material(
                    color: Colors.white24,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BusinRadius.sm)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(BusinRadius.sm),
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(padding: EdgeInsets.all(BusinSpace.x3), child: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: Colors.white, size: 22)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
