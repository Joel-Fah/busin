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
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 20,
                  height: 20,
                  color: Colors.white,
                  child: Image.network(
                    url,
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                    semanticLabel: '',
                    errorBuilder: (_, _, _) => Center(child: fallback),
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
