import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'proof_viewer.dart';

/// The small picture of a stored proof on the status card: it opens full screen when tapped. [image] is the proof; if it
/// cannot be loaded the thumbnail simply is not there (the card goes without it).
class ProofThumbnail extends StatelessWidget {
  const ProofThumbnail({super.key, required this.image});

  final ImageProvider image;

  static const double height = 160;

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    return Semantics(
      button: true,
      label: l10n.proofView,
      excludeSemantics: true,
      onTap: () => showProofViewer(context, image),
      child: GestureDetector(
        onTap: () {
          BusinHaptics.light();
          showProofViewer(context, image);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(BusinRadius.xs),
          child: Image(
            image: image,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            // Once the picture is there, a small hint that it opens. The box keeps the thumbnail's own size: a Stack
            // of only positioned children would not have one.
            frameBuilder: (context, child, frame, _) => frame == null
                ? child
                : SizedBox(
                    height: height,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Positioned.fill(child: child),
                        Positioned(
                          right: BusinSpace.x2,
                          bottom: BusinSpace.x2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(BusinRadius.xs)),
                            child: const Padding(padding: EdgeInsets.all(6), child: HugeIcon(icon: HugeIcons.strokeRoundedArrowExpand, color: Colors.white, size: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
