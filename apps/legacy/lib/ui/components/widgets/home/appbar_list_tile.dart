import 'package:busin/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../../utils/constants.dart';

class AppBarListTile extends StatelessWidget {
  const AppBarListTile({
    super.key,
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
  });

  final void Function() onTap;
  final Widget leading;
  final String title, subtitle;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: l10n.userProfile,
      child: IntrinsicWidth(
        child: ListTile(
          onTap: onTap,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
          leading: leading,
          title: Text(title),
          subtitle: Align(
            alignment: AlignmentGeometry.centerLeft,
            child: Ink(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 8.0, vertical: 2.0),
              decoration: BoxDecoration(
                color: subtitleColor.withValues(alpha: 0.1),
                borderRadius: borderRadius,
              ),
              child: Text(
                subtitle,
                style: AppTextStyles.small.copyWith(
                  color: subtitleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
