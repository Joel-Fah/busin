# 0011: The design system in the Flutter apps

Status: accepted, 2026-11-05 (owner request: the apps must carry the portal's identity and be responsive from the start).

## Context
[ADR 0009](0009-design-system.md) defines BusIn's design language for the admin portal. The first student app only shared its palette and typeface, and looked like stock Material next to the portal and the legacy app. The owner asked for one design system across every tier, with the apps going furthest (floating navigation, threaded contours, interactive components), and for layouts that work on tablets, including split screens in landscape.

## Decision
Port the language, not the code. The tokens and rules are identical; the components are rebuilt natively in Flutter and live in `packages/busin_ui`, so the ops app inherits them.

| Part | In the portal | In Flutter (`busin_ui`) |
|---|---|---|
| Tokens | `theme.css` | `BusinPalette`, `BusinRamps`, `BusinRadius` (with `innerRadius`), `BusinSpace`, `BusinMotion` (160, 280, 520 ms; the portal's soft curve), `BusinElevation` (soft and float shadows, glass 72% and blur 18) |
| Threaded contour | SVG rect, hover slides | `Contour` and `ContourPainter`: a dashed rounded rectangle drawn from path metrics, with the portal's presets (`ContourStyle.card`, `bar`, `button`, `insightCard`, `sheet`, `banner`, `emptyState`). A phone has no hover, so "live" threads slide on press and focus, and an empty state's thread slides once as it appears |
| Grain | feTurbulence | `Grain`: a small noise picture tiled at one picture pixel per screen pixel and blended soft-light |
| Marker underline | rough displacement filter | `MarkedText`: a seeded, hand-wobbled path (Flutter has no displacement filter) |
| Floating navigation | glass bar, elastic indicator | `FloatingNavBar`: glass with a backdrop blur, the same thread, an elastic two-edge highlight (`indicatorEdges`), a selection haptic, and it hides while the keyboard is open. It adds the system safe-area inset the portal does not need |
| Wide screens | the bar widens | `BusinNavRail`: a slim floating rail with the same highlight running vertically |
| Cards, buttons, chips, empty states, skeletons, sheets | `Card`, `Button`, `Chip`, `EmptyState`, `Skeleton`, `SideSheet` | `BusinCard`, `BusinButton` (squeeze 0.98, light haptic, thread), `StatusChip` (always with an icon), `EmptyState` (framed, with a 3D illustration), `Skeleton` (shimmer 1.6 s), `showBusinSheet` |
| Imagery | thiings.co 3D set, wordmark | The same WebP set and the wordmark SVG bundled in `busin_ui/assets`; a night-bus photo for the sign-in screen |

### Responsive rules
Layouts are chosen by width, never by device name (`BusinLayout`): compact under 600 dp (one column, floating bar), medium 600 to 839 (one column capped at 640, floating bar), expanded from 840 (a rail and room for two panes). `AdaptiveScaffold` picks the navigation and tells screens how much bottom room the bar takes (`BusinScope.bottomInset`); `ContentColumn` caps a reading column; `SplitView` shows two panes side by side when the area is wide enough. Every screen is tested at 360x640, 412x915, 800x1280 and 1280x800 and at 160% text.

### Rules carried over
No pills, no squircles, no one-sided borders; no solid contour; state is never colour alone; grain and the marker are decoration (never behind forms or small text); no emojis; English and French in lockstep; every duration goes through `BusinMotion.of`, so reduced motion removes movement. Contrast of the new surfaces (glass bar over the page, white on the seed banner, the marker, insight cards) is tested to WCAG AA.

### Review tool
A debug-only styleguide screen (`fvm flutter run --route /styleguide`) shows every part in both themes at the window's size, with the real bar and rail. It is not built into release builds.

## Consequences
- New screens compose these parts; a screen that needs something new adds it to `busin_ui` and to the styleguide first.
- Everything animates through Flutter's own implicit animations; the only new dependency is `flutter_svg` for the wordmark.
- Native MapLibre and other platform views are not part of the design system and keep their own styling.
