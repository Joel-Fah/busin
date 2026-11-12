import 'package:busin_app/busin_app.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router.dart';

/// The name of each document, from the shared strings.
String legalTitle(BusinL10n l10n, LegalDoc doc) => switch (doc) {
      LegalDoc.terms => l10n.legalTerms,
      LegalDoc.privacy => l10n.legalPrivacy,
      LegalDoc.acceptableUse => l10n.legalAcceptable,
    };

/// One legal document, the same text as the student app (busin_app): the short version first, then each part. Bundled,
/// so it reads offline, and open before sign-in too.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.doc});

  final LegalDoc doc;

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final document = legalDocument(doc, l10n.localeName);
    final date = MaterialLocalizations.of(context).formatMediumDate(legalUpdatedAt);

    return Scaffold(
      appBar: AppBar(title: Text(legalTitle(l10n, doc))),
      body: SafeArea(
        child: ContentColumn(
          child: ListView(
            padding: const EdgeInsets.all(BusinSpace.x5),
            children: [
              Text('${l10n.legalUpdated(date)} · ${l10n.legalReadTime(document.minutes)}', style: text.bodySmall?.copyWith(color: p.muted)),
              const SizedBox(height: BusinSpace.x4),
              BusinCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.legalInShort, style: text.titleMedium),
                    const SizedBox(height: BusinSpace.x2),
                    for (final line in document.highlights)
                      Padding(padding: const EdgeInsets.only(top: BusinSpace.x2), child: Text(line, style: text.bodyMedium)),
                  ],
                ),
              ),
              for (final section in document.sections) ...[
                const SizedBox(height: BusinSpace.x5),
                Text(section.title, style: text.titleMedium),
                for (final paragraph in section.paragraphs)
                  Padding(padding: const EdgeInsets.only(top: BusinSpace.x2), child: Text(paragraph, style: text.bodyMedium)),
                for (final bullet in section.bullets)
                  Padding(
                    padding: const EdgeInsets.only(top: BusinSpace.x2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('•  ', style: text.bodyMedium?.copyWith(color: p.muted)),
                        Expanded(child: Text(bullet, style: text.bodyMedium)),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: BusinSpace.x6),
              Text(l10n.legalAlsoRead, style: text.titleSmall?.copyWith(color: p.muted)),
              for (final other in LegalDoc.values)
                if (other != doc)
                  TextButton(
                    style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                    onPressed: () => context.pushReplacement(Routes.legal(other)),
                    child: Text(legalTitle(l10n, other)),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Terms of use · Privacy policy · Acceptable use", as small links.
class LegalLinks extends StatelessWidget {
  const LegalLinks({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        for (final doc in LegalDoc.values)
          TextButton(onPressed: () => context.push(Routes.legal(doc)), child: Text(legalTitle(l10n, doc))),
      ],
    );
  }
}
