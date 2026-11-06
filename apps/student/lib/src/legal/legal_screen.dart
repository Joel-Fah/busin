import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../router.dart';
import '../subscription/subscription_providers.dart';
import 'legal_documents.dart';

/// What each document is called, says in one line, and looks like: shared by the profile list and the page header.
class LegalDocInfo {
  const LegalDocInfo(this.title, this.summary, this.icon);

  final String title;
  final String summary;
  final List<List<dynamic>> icon;

  static LegalDocInfo of(BusinL10n l10n, LegalDoc doc) => switch (doc) {
        LegalDoc.terms => LegalDocInfo(l10n.legalTerms, l10n.legalTermsBody, HugeIcons.strokeRoundedFile01),
        LegalDoc.privacy => LegalDocInfo(l10n.legalPrivacy, l10n.legalPrivacyBody, HugeIcons.strokeRoundedSquareLock02),
        LegalDoc.acceptableUse => LegalDocInfo(l10n.legalAcceptable, l10n.legalAcceptableBody, HugeIcons.strokeRoundedShieldUser),
      };
}

/// One legal document as a page of its own, above the tabs: what it is, the short version first, then each part as a
/// section that opens (the first one is already open), and the other documents at the end. The text is bundled with the
/// app, so it reads offline.
class LegalPage extends ConsumerWidget {
  const LegalPage({super.key, required this.doc});

  final LegalDoc doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final info = LegalDocInfo.of(l10n, doc);
    final content = legalDocument(doc, Localizations.localeOf(context).languageCode);
    final school = ref.watch(schoolProvider).value;
    final date = MaterialLocalizations.of(context).formatMediumDate(legalUpdatedAt);
    final others = [for (final d in LegalDoc.values) if (d != doc) d];

    return Scaffold(
      appBar: AppBar(
        title: Text(info.title),
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go(Routes.profile)),
      ),
      body: SafeArea(
        child: ContentColumn(
          maxWidth: 760,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(BusinSpace.x5, BusinSpace.x4, BusinSpace.x5, BusinSpace.x8),
            children: [
              StaggeredIn(
                index: 0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(BusinRadius.md)),
                      child: Padding(padding: const EdgeInsets.all(BusinSpace.x4), child: HugeIcon(icon: info.icon, size: 28, color: p.fg)),
                    ),
                    const SizedBox(width: BusinSpace.x4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(info.title, style: text.headlineSmall),
                          const SizedBox(height: BusinSpace.x1),
                          Text(
                            [
                              l10n.legalUpdated(date),
                              l10n.legalReadTime(content.minutes),
                              if (school != null) l10n.legalAppliesTo(school.shortName ?? school.name),
                            ].join('  ·  '),
                            style: text.bodySmall?.copyWith(color: p.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: BusinSpace.x5),
              StaggeredIn(
                index: 1,
                child: Notice(
                  title: l10n.legalInShort,
                  icon: HugeIcons.strokeRoundedSparkles,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [for (final line in content.highlights) _Bullet(line, color: p.fg)],
                  ),
                ),
              ),
              const SizedBox(height: BusinSpace.x5),
              for (var i = 0; i < content.sections.length; i++) ...[
                StaggeredIn(
                  index: i + 2,
                  child: BusinAccordion(
                    initiallyOpen: i == 0,
                    semanticLabel: '${i + 1}. ${content.sections[i].title}',
                    title: Row(
                      children: [
                        Text('${i + 1}', style: text.titleMedium?.copyWith(color: p.muted)),
                        const SizedBox(width: BusinSpace.x3),
                        Expanded(child: Text(content.sections[i].title, style: text.titleMedium)),
                      ],
                    ),
                    child: _SectionBody(content.sections[i]),
                  ),
                ),
                const SizedBox(height: BusinSpace.x3),
              ],
              const SizedBox(height: BusinSpace.x3),
              BusinCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedHelpCircle, size: 22, color: p.muted),
                    const SizedBox(width: BusinSpace.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.legalQuestionsTitle, style: text.titleSmall),
                          const SizedBox(height: BusinSpace.x1),
                          Text(l10n.legalQuestionsBody, style: text.bodyMedium?.copyWith(color: p.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: BusinSpace.x6),
              Text(l10n.legalAlsoRead, style: text.titleMedium),
              const SizedBox(height: BusinSpace.x3),
              for (final other in others) ...[
                LegalLinkTile(doc: other, replace: true),
                const SizedBox(height: BusinSpace.x2),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody(this.section);

  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final paragraph in section.paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: BusinSpace.x3),
            child: Text(paragraph, style: text.bodyMedium?.copyWith(color: p.fg, height: 1.5)),
          ),
        for (final line in section.bullets) _Bullet(line, color: p.fg),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.line, {required this.color});

  final String line;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: BusinSpace.x2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 9, right: BusinSpace.x3),
            child: DecoratedBox(decoration: BoxDecoration(color: p.muted, shape: BoxShape.circle), child: const SizedBox(width: 5, height: 5)),
          ),
          Expanded(child: Text(line, style: text.bodyMedium?.copyWith(color: color, height: 1.5))),
        ],
      ),
    );
  }
}

/// A row that opens one document: an icon, the title, one line of what it covers, and a chevron. In the profile it
/// pushes the page; at the end of a document it replaces it, so back still returns to the profile.
class LegalLinkTile extends StatelessWidget {
  const LegalLinkTile({super.key, required this.doc, this.replace = false});

  final LegalDoc doc;
  final bool replace;

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final info = LegalDocInfo.of(l10n, doc);
    return Semantics(
      button: true,
      label: '${info.title}. ${info.summary}',
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(BusinRadius.md),
          onTap: () {
            BusinHaptics.light();
            if (replace) {
              context.pushReplacement(Routes.legalFor(doc));
            } else {
              context.push(Routes.legalFor(doc));
            }
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: BusinSpace.x2, horizontal: BusinSpace.x1),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(BusinRadius.sm)),
                    child: Padding(padding: const EdgeInsets.all(BusinSpace.x3), child: HugeIcon(icon: info.icon, size: 20, color: p.fg)),
                  ),
                  const SizedBox(width: BusinSpace.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(info.title, style: text.titleSmall),
                        Text(info.summary, style: text.bodySmall?.copyWith(color: p.muted)),
                      ],
                    ),
                  ),
                  HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 20, color: p.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The profile's legal card: a heading, a line on why it is there, and one row per document.
class LegalLinksCard extends StatelessWidget {
  const LegalLinksCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    return BusinCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.legalTitle, style: text.titleLarge),
          const SizedBox(height: BusinSpace.x1),
          Text(l10n.legalHint, style: text.bodySmall?.copyWith(color: p.muted)),
          const SizedBox(height: BusinSpace.x3),
          for (final doc in LegalDoc.values) LegalLinkTile(doc: doc),
        ],
      ),
    );
  }
}
