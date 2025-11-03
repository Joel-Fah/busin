import 'package:busin/ui/components/widgets/loading_indicator.dart';
import 'package:busin/utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

Widget _buildMarkdown(BuildContext context, String data) {
  final theme = Theme.of(context);
  final style = MarkdownStyleSheet.fromTheme(theme).copyWith(
    p: AppTextStyles.body,
    h1: AppTextStyles.h1,
    h2: AppTextStyles.h2,
    h3: AppTextStyles.h3,
    code: GoogleFonts.jetBrainsMono(
      fontSize: 14.0,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      color: theme.colorScheme.onSurface,
    ),
    codeblockDecoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    blockquote: AppTextStyles.small.copyWith(
      fontSize: 14.0,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
      fontStyle: FontStyle.italic,
    ),
    blockquoteDecoration: BoxDecoration(
      border: Border(
        left: BorderSide(color: theme.colorScheme.outline, width: 3),
      ),
    ),
    listBullet: theme.textTheme.bodyMedium,
    a: AppTextStyles.body.copyWith(color: infoColor),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
    ),
    tableBorder: TableBorder.all(
      color: theme.colorScheme.outlineVariant,
      width: 0.6,
    ),
    tableHead: AppTextStyles.body.copyWith(
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
    ),
  );

  return MarkdownBody(
    data: data,
    selectable: true,
    styleSheet: style,
    softLineBreak: true,
    onTapLink: (text, href, title) =>
        launchUrl(Uri.parse(href!), mode: LaunchMode.inAppWebView),
    sizedImageBuilder: (config) => CachedNetworkImage(
      imageUrl: config.uri.toString(),
      fit: BoxFit.cover,
      width: config.width,
      height: config.height,
      placeholder: (context, url) => Center(
        child: LoadingIndicator(),
      ),
    ),
    listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.start,
  );
}

/// Public widget to render Markdown with the app styling.
class MarkdownStyledView extends StatelessWidget {
  final String data;

  const MarkdownStyledView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return _buildMarkdown(context, data);
  }
}
