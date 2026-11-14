import 'package:busin_core/busin_core.dart';
import '../l10n/busin_l10n.dart';
import '../tokens/palette.dart';
import '../tokens/shape.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// A person's school as a small badge: its logo (or a building icon while there is none, or if it cannot load) and its
/// name, in the same quiet style as the status chips beside it. With [onTap] it is a button (the profiles open the
/// school's details).
class SchoolBadge extends StatelessWidget {
  const SchoolBadge({super.key, required this.school, required this.supabaseUrl, this.onTap});

  final School school;
  final String supabaseUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final url = school.logoUrl(supabaseUrl);
    final fallback = HugeIcon(icon: HugeIcons.strokeRoundedBuilding03, size: 14, color: p.muted);
    final badge = DecoratedBox(
      decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(BusinRadius.xs)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(url == null ? BusinSpace.x3 : BusinSpace.x1 + 1, BusinSpace.x1, BusinSpace.x3, BusinSpace.x1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (url == null)
              fallback
            else
              // The logo keeps its shape: 20 high, up to 50 wide, on a white plate (never cropped).
              Container(
                constraints: const BoxConstraints(minWidth: 20, maxWidth: 50, minHeight: 20, maxHeight: 20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.all(2),
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Image.network(
                    url,
                    height: 16,
                    fit: BoxFit.contain,
                    semanticLabel: '',
                    errorBuilder: (_, _, _) => fallback,
                  ),
                ),
              ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                school.name,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: p.muted, fontWeight: FontWeight.w700),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 14, color: p.muted),
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return badge;
    return Semantics(
      button: true,
      hint: BusinL10n.of(context).schoolDetailsHint,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(borderRadius: BorderRadius.circular(BusinRadius.xs), onTap: onTap, child: badge),
      ),
    );
  }
}
