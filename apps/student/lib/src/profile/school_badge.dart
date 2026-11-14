import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// The student's school as a small badge: its logo (or a building icon while there is none, or if it cannot load) and
/// its name, in the same quiet style as the status chips beside it.
class SchoolBadge extends StatelessWidget {
  const SchoolBadge({super.key, required this.school, required this.supabaseUrl});

  final School school;
  final String supabaseUrl;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final url = school.logoUrl(supabaseUrl);
    final fallback = HugeIcon(icon: HugeIcons.strokeRoundedBuilding03, size: 14, color: p.muted);
    return DecoratedBox(
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
          ],
        ),
      ),
    );
  }
}
