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
  const LegalDocInfo(this.title, this.summary, this.icon, this.banner, this.focus);

  final String title;
  final String summary;
  final List<List<dynamic>> icon;

  /// The photo at the top of the page and the part of it that stays in view when it is cropped.
  final String banner;
  final Alignment focus;

  static LegalDocInfo of(BusinL10n l10n, LegalDoc doc) => switch (doc) {
        LegalDoc.terms => LegalDocInfo(l10n.legalTerms, l10n.legalTermsBody, HugeIcons.strokeRoundedFile01, 'assets/legal/terms.webp', const Alignment(0.3, 0)),
        LegalDoc.privacy => LegalDocInfo(l10n.legalPrivacy, l10n.legalPrivacyBody, HugeIcons.strokeRoundedSquareLock02, 'assets/legal/privacy.webp', const Alignment(0.2, 0)),
        LegalDoc.acceptableUse => LegalDocInfo(l10n.legalAcceptable, l10n.legalAcceptableBody, HugeIcons.strokeRoundedShieldUser, 'assets/legal/acceptable.webp', const Alignment(0.4, 0)),
      };
}

/// One legal document as a page of its own, above the tabs: what it is, the short version first, a banner photo, then
/// each part as a section (all open, each can be closed), and the other documents at the end. The text is bundled with
/// the app, so it reads offline. On a wide screen a table of contents stays in place on the left: tapping a part scrolls
/// to it, and the part being read is marked.
class LegalPage extends ConsumerStatefulWidget {
  const LegalPage({super.key, required this.doc});

  final LegalDoc doc;

  @override
  ConsumerState<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends ConsumerState<LegalPage> {
  final _scroll = ScrollController();
  final _viewport = GlobalKey();
  List<GlobalKey> _keys = const [];
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_track);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// The part being read: the last one whose top has reached the upper part of the viewport, or the last one at the end.
  void _track() {
    final viewportBox = _viewport.currentContext?.findRenderObject() as RenderBox?;
    if (viewportBox == null || _keys.isEmpty) return;
    final top = viewportBox.localToGlobal(Offset.zero).dy;
    var active = 0;
    for (var i = 0; i < _keys.length; i++) {
      final box = _keys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.localToGlobal(Offset.zero).dy - top <= 140) active = i;
    }
    if (_scroll.hasClients && _scroll.position.pixels >= _scroll.position.maxScrollExtent - 4) active = _keys.length - 1;
    if (active != _current) setState(() => _current = active);
  }

  Future<void> _goTo(int index) async {
    BusinHaptics.selection();
    setState(() => _current = index);
    final target = _keys[index].currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(target, alignment: 0, duration: BusinMotion.of(context, const Duration(milliseconds: 420)), curve: BusinMotion.soft);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final info = LegalDocInfo.of(l10n, widget.doc);
    final content = legalDocument(widget.doc, Localizations.localeOf(context).languageCode);
    final school = ref.watch(schoolProvider).value;
    final date = MaterialLocalizations.of(context).formatMediumDate(legalUpdatedAt);
    final others = [for (final d in LegalDoc.values) if (d != widget.doc) d];
    final wide = BusinLayout.of(context).isExpanded;
    if (_keys.length != content.sections.length) _keys = List.generate(content.sections.length, (_) => GlobalKey());

    final header = StaggeredIn(
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
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
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
        const SizedBox(height: BusinSpace.x4),
        StaggeredIn(index: 2, child: _Banner(asset: info.banner, focus: info.focus)),
        const SizedBox(height: BusinSpace.x5),
        for (var i = 0; i < content.sections.length; i++) ...[
          KeyedSubtree(
            key: _keys[i],
            child: StaggeredIn(
              index: i + 3,
              child: BusinAccordion(
                initiallyOpen: true,
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
    );

    const edge = EdgeInsets.fromLTRB(BusinSpace.x5, BusinSpace.x4, BusinSpace.x5, BusinSpace.x8);
    return Scaffold(
      appBar: AppBar(
        title: Text(info.title),
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go(Routes.profile)),
      ),
      body: SafeArea(
        child: wide
            ? ContentColumn(
                maxWidth: 1180,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Outside the scrolling part, so it stays in place.
                      SizedBox(
                        width: 264,
                        child: _Contents(titles: [for (final s in content.sections) s.title], current: _current, onSelect: _goTo),
                      ),
                      const SizedBox(width: BusinSpace.x8),
                      Expanded(
                        child: SingleChildScrollView(
                          key: _viewport,
                          controller: _scroll,
                          padding: const EdgeInsets.only(top: BusinSpace.x4, bottom: BusinSpace.x8),
                          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: body),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ContentColumn(
                maxWidth: 760,
                child: SingleChildScrollView(key: _viewport, controller: _scroll, padding: edge, child: body),
              ),
      ),
    );
  }
}

/// The photo under the short version: a crop of a bundled picture, a fine grain on it and a soft fade at the foot. It
/// is decoration, so a screen reader skips it.
class _Banner extends StatelessWidget {
  const _Banner({required this.asset, required this.focus});

  final String asset;
  final Alignment focus;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BusinRadius.lg),
        child: AspectRatio(
          aspectRatio: 16 / 7,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: p.surface2),
              Image.asset(asset, fit: BoxFit.cover, alignment: focus, gaplessPlayback: true, errorBuilder: (_, _, _) => const SizedBox.shrink()),
              const Grain(opacity: 0.9),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, BusinPalette.seed.withValues(alpha: 0.25)]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The table of contents: every part by number and title, the one being read marked. Tapping one scrolls to it.
class _Contents extends StatelessWidget {
  const _Contents({required this.titles, required this.current, required this.onSelect});

  final List<String> titles;
  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: BusinSpace.x4, bottom: BusinSpace.x8),
      child: BusinCard(
        padding: const EdgeInsets.all(BusinSpace.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(BusinSpace.x3, BusinSpace.x2, BusinSpace.x3, BusinSpace.x3),
              child: Text(l10n.legalOnThisPage, style: text.labelLarge?.copyWith(color: p.muted)),
            ),
            for (var i = 0; i < titles.length; i++)
              Semantics(
                button: true,
                selected: i == current,
                label: '${i + 1}. ${titles[i]}',
                child: ExcludeSemantics(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(BusinRadius.sm),
                    onTap: () => onSelect(i),
                    child: AnimatedContainer(
                      duration: BusinMotion.of(context, BusinMotion.fast),
                      constraints: const BoxConstraints(minHeight: 44),
                      padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x3, vertical: BusinSpace.x2),
                      decoration: BoxDecoration(color: i == current ? p.surface2 : Colors.transparent, borderRadius: BorderRadius.circular(BusinRadius.sm)),
                      child: Row(
                        children: [
                          SizedBox(width: 22, child: Text('${i + 1}', style: text.labelLarge?.copyWith(color: i == current ? p.fg : p.muted))),
                          Expanded(
                            child: Text(titles[i], style: text.bodyMedium?.copyWith(fontWeight: i == current ? FontWeight.w700 : FontWeight.w500, color: i == current ? p.fg : p.muted)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
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
