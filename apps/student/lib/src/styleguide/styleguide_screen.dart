import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// The mobile styleguide: every part of the shared design language, in both themes and at the size of the window you
/// run it in. For developers and for the owner's review on a device; it exists only in debug builds
/// (`fvm flutter run --route /styleguide`). It is English only. Rotate the tablet to watch the floating bar become a rail.
class StyleguideScreen extends StatefulWidget {
  const StyleguideScreen({super.key});

  @override
  State<StyleguideScreen> createState() => _StyleguideScreenState();
}

class _StyleguideScreenState extends State<StyleguideScreen> {
  int _section = 0;
  ThemeMode _mode = ThemeMode.system;

  static final _destinations = [
    BusinDestination(label: 'Basics', icon: HugeIcons.strokeRoundedPaintBoard),
    BusinDestination(label: 'Parts', icon: HugeIcons.strokeRoundedLayers01),
    BusinDestination(label: 'Layout', icon: HugeIcons.strokeRoundedLayoutGrid),
    BusinDestination(label: 'Motion', icon: HugeIcons.strokeRoundedPlay),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = switch (_mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
    return Theme(
      data: dark ? BusinTheme.dark() : BusinTheme.light(),
      child: Builder(
        builder: (context) => AdaptiveScaffold(
          destinations: _destinations,
          currentIndex: _section,
          onDestinationSelected: (i) => setState(() => _section = i),
          railHeader: BrandMark(color: BusinPalette.of(context).fg, height: 28),
          body: Column(
            children: [
              _Header(mode: _mode, onMode: (m) => setState(() => _mode = m)),
              Expanded(
                child: IndexedStack(
                  index: _section,
                  children: const [_Basics(), _Parts(), _LayoutSection(), _MotionSection()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.mode, required this.onMode});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onMode;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final size = MediaQuery.sizeOf(context);
    final layout = BusinLayout.of(context);
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarkedText('Styleguide', style: text.headlineMedium),
        const SizedBox(height: 4),
        Text('${size.width.round()} x ${size.height.round()} dp, ${layout.name} layout', style: text.bodySmall?.copyWith(color: p.muted)),
      ],
    );
    final theme = SegmentedButton<ThemeMode>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: ThemeMode.light, label: Text('Light')),
        ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
        ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
      ],
      selected: {mode},
      onSelectionChanged: (s) => onMode(s.first),
    );
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(BusinSpace.x5, BusinSpace.x3, BusinSpace.x5, BusinSpace.x2),
        // Side by side when there is room; stacked on a phone, where large text would not fit both.
        child: layout.isCompact
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [title, const SizedBox(height: BusinSpace.x3), FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: theme)])
            : Row(children: [Expanded(child: title), theme]),
      ),
    );
  }
}

/// Scrolls a section, clear of the floating bar, in a reading column.
class _Page extends StatelessWidget {
  const _Page({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final inset = BusinScope.of(context).bottomInset;
    return ListView(
      padding: EdgeInsets.fromLTRB(BusinSpace.x5, BusinSpace.x2, BusinSpace.x5, inset + BusinSpace.x4),
      children: [ContentColumn(maxWidth: 900, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children))],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text, {this.note});

  final String text;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: BusinSpace.x8, bottom: BusinSpace.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: t.titleLarge),
          if (note != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(note!, style: t.bodyMedium?.copyWith(color: p.muted))),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------- basics

class _Basics extends StatelessWidget {
  const _Basics();

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final t = Theme.of(context).textTheme;
    final swatches = <(String, Color)>[
      ('bg', p.bg), ('surface', p.surface), ('surface 2', p.surface2), ('fg', p.fg), ('muted', p.muted), ('line', p.line),
      ('accent', p.accent), ('link', p.link), ('ok', p.ok), ('warn', p.warn), ('bad', p.bad), ('info', p.info),
    ];
    return _Page(
      children: [
        const _Title('Colour', note: 'The portal\'s tokens. State is never colour alone.'),
        Wrap(
          spacing: BusinSpace.x3,
          runSpacing: BusinSpace.x3,
          children: [
            for (final (name, color) in swatches)
              SizedBox(
                width: 96,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 56, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(BusinRadius.sm), border: Border.all(color: p.line))),
                    const SizedBox(height: 6),
                    Text(name, style: t.labelMedium),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: BusinSpace.x4),
        Row(
          children: [
            for (final c in [BusinRamps.teal50, BusinRamps.teal200, BusinRamps.teal400, BusinRamps.teal600, BusinRamps.teal800, BusinRamps.teal900, BusinRamps.seed])
              Expanded(child: Container(height: 28, color: c)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final c in [BusinRamps.orange50, BusinRamps.orange100, BusinRamps.orange200, BusinRamps.orange300, BusinRamps.orange400, BusinRamps.orange500, BusinRamps.orange700])
              Expanded(child: Container(height: 28, color: c)),
          ],
        ),
        const _Title('Type', note: 'Plus Jakarta Sans, the same face as the portal.'),
        Text('Display', style: t.displaySmall),
        Text('Headline', style: t.headlineMedium),
        Text('Title', style: t.titleLarge),
        Text('Body text reads comfortably at sixteen.', style: t.bodyLarge),
        Text('Secondary text, muted.', style: t.bodyMedium?.copyWith(color: p.muted)),
        Text('LABEL', style: t.labelMedium?.copyWith(letterSpacing: 1.2)),
        const _Title('Shape', note: 'Rounded beyond normal. Never a pill, never a squircle. A shape inside another takes the outer corner minus the gap.'),
        Wrap(
          spacing: BusinSpace.x4,
          runSpacing: BusinSpace.x4,
          children: [
            for (final (name, r) in [('xs 8', BusinRadius.xs), ('sm 16', BusinRadius.sm), ('md 20', BusinRadius.md), ('lg 28', BusinRadius.lg), ('xl 36', BusinRadius.xl)])
              Column(
                children: [
                  Container(width: 72, height: 72, decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(r))),
                  const SizedBox(height: 6),
                  Text(name, style: t.labelMedium),
                ],
              ),
            Column(
              children: [
                Container(
                  width: 96,
                  height: 72,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(BusinRadius.lg)),
                  child: DecoratedBox(decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(BusinRadius.innerRadius(BusinRadius.lg, 12)))),
                ),
                const SizedBox(height: 6),
                Text('28 around 16', style: t.labelMedium),
              ],
            ),
          ],
        ),
        const _Title('Illustrations', note: 'The 3D set, used where it carries meaning.'),
        Wrap(
          spacing: BusinSpace.x3,
          runSpacing: BusinSpace.x3,
          children: [
            for (final art in BusinIllustration.values.where((a) => a != BusinIllustration.busLarge)) Illustration(art, width: 88, height: 88),
          ],
        ),
        const _Title('Logo'),
        Row(
          children: [
            BrandMark(color: p.fg, height: 48),
            const SizedBox(width: BusinSpace.x6),
            Container(color: BusinRamps.seed, padding: const EdgeInsets.all(12), child: const BrandMark(color: Colors.white, height: 40)),
            const SizedBox(width: BusinSpace.x4),
            Container(color: BusinPalette.orange, padding: const EdgeInsets.all(12), child: const BrandMark(color: BusinRamps.seed, height: 40)),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------- parts

class _Parts extends StatelessWidget {
  const _Parts();

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final t = Theme.of(context).textTheme;
    return _Page(
      children: [
        const _Title('Buttons', note: 'Press one: it squeezes, taps, and its thread slides.'),
        Wrap(
          spacing: BusinSpace.x3,
          runSpacing: BusinSpace.x3,
          children: [
            BusinButton(label: 'Primary', onPressed: () {}),
            BusinButton(label: 'Secondary', variant: BusinButtonVariant.secondary, onPressed: () {}),
            BusinButton(label: 'Danger', variant: BusinButtonVariant.danger, onPressed: () {}),
            BusinButton(label: 'Ghost', variant: BusinButtonVariant.ghost, onPressed: () {}),
            BusinButton(label: 'With icon', icon: HugeIcons.strokeRoundedTicket03, onPressed: () {}),
            const BusinButton(label: 'Disabled', onPressed: null),
            BusinButton(label: 'Loading', loading: true, onPressed: () {}),
          ],
        ),
        const SizedBox(height: BusinSpace.x3),
        BusinButton(label: 'Full width', expand: true, onPressed: () {}),
        const _Title('Status chips', note: 'Always an icon beside the colour.'),
        const Wrap(
          spacing: BusinSpace.x2,
          runSpacing: BusinSpace.x2,
          children: [
            StatusChip(label: 'Approved', tone: StatusTone.ok),
            StatusChip(label: 'Pending', tone: StatusTone.warn),
            StatusChip(label: 'Rejected', tone: StatusTone.bad),
            StatusChip(label: 'Running', tone: StatusTone.info),
            StatusChip(label: 'Expired'),
          ],
        ),
        const _Title('Field tiles', note: 'For choices that are not typed: a stop, a photo. The thread slides when pressed.'),
        FieldTile(label: 'Your stop', icon: HugeIcons.strokeRoundedFlag02, placeholder: 'Choose where you board', onTap: () {}),
        const SizedBox(height: BusinSpace.x3),
        FieldTile(label: 'Payment proof', icon: HugeIcons.strokeRoundedReceiptText, placeholder: 'Add a photo', value: 'Photo added', onTap: () {}),
        const _Title('Notices', note: 'Tone, an icon and words together.'),
        const Notice(tone: StatusTone.bad, title: 'Your school\'s reason:', child: Text('The receipt is unreadable.')),
        const SizedBox(height: BusinSpace.x3),
        const Notice(tone: StatusTone.info, child: Text('Only you and your school can see your receipt.')),
        const _Title('Toasts', note: 'A short message that floats at the top and leaves by itself. Good news is quick, problems stay. A ring around the close icon empties as the time runs out. It eases in gently and leaves faster. Swipe up to dismiss.'),
        Builder(
          builder: (context) => Wrap(
            spacing: BusinSpace.x3,
            runSpacing: BusinSpace.x3,
            children: [
              BusinButton(label: 'Success', variant: BusinButtonVariant.secondary, onPressed: () => BusinToast.show(context, 'Request sent.', tone: ToastTone.success)),
              BusinButton(label: 'Info', variant: BusinButtonVariant.secondary, onPressed: () => BusinToast.show(context, 'Your code refreshes by itself.', tone: ToastTone.info)),
              BusinButton(label: 'Warning', variant: BusinButtonVariant.secondary, onPressed: () => BusinToast.show(context, 'Do not share your code.', tone: ToastTone.warning, title: 'Heads up')),
              BusinButton(label: 'Error', variant: BusinButtonVariant.secondary, onPressed: () => BusinToast.show(context, 'No connection. Try again.', tone: ToastTone.error, title: 'Not sent')),
            ],
          ),
        ),
        const _Title('Stage line', note: 'Where something stands: done, current, coming; or ending badly.'),
        const BusinCard(child: Column(children: [
          StepLine(labels: ['Sent', 'Checking', 'Decision'], current: 1),
          SizedBox(height: 24),
          StepLine(labels: ['Sent', 'Checking', 'Decision'], current: 2, failed: true),
          SizedBox(height: 24),
          StepLine(labels: ['Sent', 'Checking', 'Decision'], current: 3),
        ])),
        const _Title('Cards', note: 'Still threads for cards, sliding threads for links.'),
        BusinCard(child: Text('A card holds one idea. The thread sits inside it, clear of the content.', style: t.bodyLarge)),
        const SizedBox(height: BusinSpace.x4),
        BusinCard(onTap: () {}, child: Row(children: [HugeIcon(icon: HugeIcons.strokeRoundedBus01, color: p.fg), const SizedBox(width: 12), Expanded(child: Text('A card that is a link: press it.', style: t.bodyLarge))])),
        const _Title('Banner', note: 'Seed teal with grain, the marker, and art that overflows its edge.'),
        const BusinBanner(eyebrow: 'Thursday, 5 November', title: 'Good afternoon, Joel', body: 'Subscribe for Fall 2026', art: BusinIllustration.ticket),
        const _Title('Empty state', note: 'Not a card: a framed space with art, words and one next step.'),
        EmptyState(
          illustration: BusinIllustration.seat,
          title: 'No boardings yet',
          body: 'Each time you board with your code, it appears here.',
          action: BusinButton(label: 'Show my code', onPressed: () {}),
        ),
        const _Title('Skeleton', note: 'The shape of what is coming. Never a lone spinner.'),
        BusinCard(
          child: Row(
            children: [
              const Skeleton(width: 48, height: 48, radius: BusinRadius.sm),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Skeleton(height: 16), const SizedBox(height: 8), Skeleton(width: 140, height: 12, radius: BusinRadius.xs)])),
            ],
          ),
        ),
        const _Title('Sheet'),
        Align(
          alignment: Alignment.centerLeft,
          child: BusinButton(
            label: 'Open a sheet',
            variant: BusinButtonVariant.secondary,
            onPressed: () => showBusinSheet<void>(
              context,
              builder: (context) => Padding(
                padding: const EdgeInsets.all(BusinSpace.x6),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Choose a stop', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Sheets are for choices that do not deserve a new screen.', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  BusinButton(label: 'Done', expand: true, onPressed: () => Navigator.of(context).pop()),
                ]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------- layout

class _LayoutSection extends StatelessWidget {
  const _LayoutSection();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = BusinPalette.of(context);
    final layout = BusinLayout.of(context);
    Widget pane(String title, String body) => BusinCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: t.titleMedium), const SizedBox(height: 8), Text(body, style: t.bodyMedium?.copyWith(color: p.muted))]),
        );
    return _Page(
      children: [
        _Title('Breakpoints', note: 'Now: ${layout.name}. Compact under 600 dp, medium to 840, expanded from 840.'),
        Text(
          'Compact: one column, floating bar. Medium: one column capped at 640 dp, floating bar. Expanded: a slim rail on the left and room for two panes. '
          'The bar hides while the keyboard is open. Rotate the device, or run on a tablet, to see the rail.',
          style: t.bodyLarge,
        ),
        const _Title('Two panes', note: 'Side by side when the area is wide enough, stacked below when told to, otherwise just the first.'),
        SplitView(
          stackBelow: true,
          primary: pane('Primary', 'The main task: a form, a status, a list.'),
          secondary: pane('Secondary', 'Help, a detail or a summary that earns its space on a tablet.'),
        ),
        const _Title('Reading column', note: 'Lines stay short on a big screen.'),
        ContentColumn(child: BusinCard(child: Text('This card sits in a column capped at ${BusinLayout.maxColumn.round()} dp and is centred when the screen is wider.', style: t.bodyLarge))),
      ],
    );
  }
}

// ---------------------------------------------------------------------------- motion

class _MotionSection extends StatefulWidget {
  const _MotionSection();

  @override
  State<_MotionSection> createState() => _MotionSectionState();
}

class _MotionSectionState extends State<_MotionSection> {
  int _run = 0;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = BusinPalette.of(context);
    return _Page(
      children: [
        _Title('Staggered entrance', note: BusinMotion.reduced(context) ? 'Reduced motion is on: things simply appear.' : '280 ms on the portal\'s easing, 50 ms apart.'),
        BusinButton(label: 'Play again', variant: BusinButtonVariant.secondary, onPressed: () => setState(() => _run++)),
        const SizedBox(height: BusinSpace.x3),
        Column(
          key: ValueKey(_run),
          children: [
            for (var i = 0; i < 5; i++)
              StaggeredIn(
                index: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: BusinSpace.x3),
                  child: BusinCard(padding: const EdgeInsets.all(BusinSpace.x5), child: Text('Row ${i + 1}', style: t.bodyLarge)),
                ),
              ),
          ],
        ),
        const _Title('Durations', note: 'fast 160 ms, normal 280 ms, slow 520 ms, one soft curve.'),
        Text('Under the system\'s reduced-motion setting every duration is zero.', style: t.bodyLarge?.copyWith(color: p.muted)),
        const _Title('Haptics'),
        Wrap(
          spacing: BusinSpace.x3,
          children: [
            BusinButton(label: 'Selection', variant: BusinButtonVariant.secondary, onPressed: BusinHaptics.selection),
            BusinButton(label: 'Light', variant: BusinButtonVariant.secondary, onPressed: BusinHaptics.light),
            BusinButton(label: 'Medium', variant: BusinButtonVariant.secondary, onPressed: BusinHaptics.medium),
          ],
        ),
      ],
    );
  }
}
