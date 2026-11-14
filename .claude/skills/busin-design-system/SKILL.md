---
name: busin-design-system
description: BusIn visual language - colors, typography, shape, icons, themes and component patterns. Load before building or changing any UI in the Flutter apps or the admin portal so every tier looks like one product.
---

# BusIn design system

Source of truth for the Flutter apps: `packages/busin_ui` (see its README): `BusinPalette`, `BusinRadius`, `BusinTheme`, the shared widgets and `BusinL10n`. It matches the admin portal's tokens (`apps/admin_web/app/globals.css`, the `/styleguide` page, [ADR 0009](../../../docs/decisions/0009-design-system.md)), so every tier looks like one product. The legacy app (`apps/legacy`) is history; the table below is what it used and the portal and `busin_ui` replaced.

## Color

| Token | Value | Use |
|---|---|---|
| seed | `#002A33` | Brand deep teal. Seed for Material 3 `ColorScheme.fromSeed`, text on light, dark-mode surface |
| accent | `#F5951F` | Brand orange. Primary actions, highlights, route lines |
| dark | `#272727` | Dark neutral |
| light | `#FFFFFF` | Light neutral |
| grey | `#8D8D8D` | Secondary text and borders |
| info | `#4285F4` (light) | Informational states |
| success | `#0F9D58` (light) | Approved, verified |
| error | `#DB4437` (light) | Rejected, failures |
| warning | `#EAAB00` (light) | Pending, caution |

Dark mode uses the brighter state variants (light blue accent, green, red accent, amber accent). Both a teal palette (shade 50 to 900, 50 is `#E9FFFD`, 900 is `#0C5D6D`) and an orange palette (shade 50 `#FEF8EC` up to dark browns) exist in `constants.dart`.

Gradients: light is teal shade 50 to white, top to bottom; dark is seed to teal shade 900.

Never hard-code a color in a widget. Read it from the theme or the tokens so light and dark both work. State is never conveyed by color alone; pair it with an icon or label.

## Type

Font family **Plus Jakarta Sans** (bundled in `busin_ui`, SIL Open Font Licence), the same as the portal. The legacy app used Bevellier, dropped because its licence is unknown. Text color defaults to the seed color on light themes. Use the Material 3 text styles from the theme; do not invent sizes. Button labels are weight 700 (a little heavier than body text) so they read as buttons on a small, bright screen.

## Shape and spacing

Radius scale 8, 16, 20, 28, 36 (`BusinRadius`), the same as the portal: rounded beyond normal, never a pill or a squircle; nested shapes use `innerRadius`. Use `gap` based spacing (the legacy app uses the `gap` package) instead of ad hoc margins.

## Icons and imagery

People illustrations follow one house style (owner direction, 2026-11-13): flat, warm (mustard, terracotta, olive and leaf greens, sage, sand around the brand teal and orange), a stippled speckle on clothes and foliage but never skin, rounded students with expressive hair and round rosy cheeks, no text or logos inside. The owner's reference images are in `apps/admin_web/public/styleguide/references/`; the rules and a ready prompt live in the styleguide content (`PEOPLE_STYLE`) and its Markdown export; the prompts for the landing hero layers are in `docs/guides/landing-hero-art.md`.

Icons: `hugeicons`, stroke-rounded style (for example `strokeRoundedInformationCircle`, `strokeRoundedCancelCircle`, `strokeRoundedAlert02`, `strokeRoundedCheckmarkCircle02`). Logos are SVG in teal (`cyan`), orange and white. Illustrations are PNG/SVG under `assets/images`. No emojis anywhere.

## Themes

Material 3, light and dark, plus a system option. Contrast must stay readable in both. Test every screen in both before calling it done.

## Component patterns

Primary, secondary and tertiary buttons; simple text field; stat card; analytics card; list tile; metadata section; user avatar with initials fallback; snackbar for feedback; bus-loading overlay for long waits; pill chips for status. Reuse these from `busin_ui`, do not rebuild them per app.

## Interaction

Bottom sheets and long-press actions rather than extra screens; pull-to-refresh on lists; haptic feedback on key actions; confirmation dialogs for destructive or role-changing actions; loading, empty and error states on every list.

## Admin portal

The web portal keeps the same palette (teal and orange, light and dark) as CSS variables, but has its own documented system: Plus Jakarta Sans, Hugeicons, radii 8 to 36 (no pills, no squircles), the inner contour, Tailwind and GSAP. The source of truth is the hidden admin-only `/styleguide` page (`apps/admin_web/app/(admin)/styleguide/`) and [ADR 0009](../../../docs/decisions/0009-design-system.md). Read the styleguide before building any portal UI, and update it in the same change as any new component. Its words live in `apps/admin_web/lib/styleguide/content.ts`, which also feeds two admin-only downloads: `/styleguide/export/markdown` (a file written for AI agents) and `/styleguide/export/pdf` (for reading and printing); change the content there, not in the page. Never use one-sided borders or underlined links.

## Mobile apps

The apps carry the same language as the portal, ported natively into `packages/busin_ui` (see [ADR 0011](../../../docs/decisions/0011-mobile-design-system.md)). Do not hand-roll a card, button, bar, chip or empty state in an app screen: use `BusinCard`, `BusinButton`, `FloatingNavBar` or `BusinNavRail` through `AdaptiveScaffold`, `StatusChip`, `EmptyState`, `Skeleton`, `showBusinSheet`; threads come from `Contour` and its `ContourStyle` presets, never a plain border. Layouts are chosen by width with `BusinLayout` (compact under 600, medium to 840, expanded from 840: rail and two panes via `SplitView`). Durations go through `BusinMotion.of(context, ...)` so reduced motion works. Review any new part in the debug styleguide (`fvm flutter run --route /styleguide`) in both themes, in portrait and landscape, before using it on a screen.

## Student web app

The PWA at `/app` (ADR 0021) uses the portal's components and tokens with the phone layout of the student app (a
640 px column, a floating tab bar). Its icon is the teal mark on white, to tell it apart from the installed app.

## Phone numbers

Every phone field is the country and phone field (`BusinPhoneField` in `busin_ui`, `PhoneField` in the portal): the country (flag and dialling code, opening a searchable list) and the number on one row, the number written the country's way as it is typed. Numbers are saved as E.164 (`+237677123456`, digits only) and shown in international form with spaces (`PhoneNumbers.display`, `displayPhone`). The starting country is the saved number's, else the school's, else the device's region. Flags are SVG files, never emoji. See ADR 0024.

## Localization

All user-facing strings go through localization (EN and FR). Shared strings live in `busin_ui` (`BusinL10n`); a screen's own strings live in its app. Student-facing wording will be friendlier than the admin's.
