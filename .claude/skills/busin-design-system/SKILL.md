---
name: busin-design-system
description: BusIn visual language - colors, typography, shape, icons, themes and component patterns. Load before building or changing any UI in the Flutter apps or the admin portal so every tier looks like one product.
---

# BusIn design system

Source of truth until `packages/busin_ui` exists: `apps/legacy/lib/utils/constants.dart` and `theme.dart`, components in `apps/legacy/lib/ui/components/`. When `busin_ui` is built, it becomes the source and this skill is updated to match.

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

Font family **Bevellier** (variable, with italic), bundled in the app. Text color defaults to the seed color on light themes. Use the Material 3 text styles from the theme; do not invent sizes.

## Shape and spacing

Default corner radius is 8. Larger surfaces such as the QR card use multiples of it with a superellipse clip. Use `gap` based spacing (the legacy app uses the `gap` package) instead of ad hoc margins.

## Icons and imagery

Icons: `hugeicons`, stroke-rounded style (for example `strokeRoundedInformationCircle`, `strokeRoundedCancelCircle`, `strokeRoundedAlert02`, `strokeRoundedCheckmarkCircle02`). Logos are SVG in teal (`cyan`), orange and white. Illustrations are PNG/SVG under `assets/images`. No emojis anywhere.

## Themes

Material 3, light and dark, plus a system option. Contrast must stay readable in both. Test every screen in both before calling it done.

## Component patterns

Primary, secondary and tertiary buttons; simple text field; stat card; analytics card; list tile; metadata section; user avatar with initials fallback; snackbar for feedback; bus-loading overlay for long waits; pill chips for status. Reuse these from `busin_ui`, do not rebuild them per app.

## Interaction

Bottom sheets and long-press actions rather than extra screens; pull-to-refresh on lists; haptic feedback on key actions; confirmation dialogs for destructive or role-changing actions; loading, empty and error states on every list.

## Admin portal

The web portal follows the same palette, radius and tone (teal and orange, light and dark), expressed as CSS variables. It may use denser layouts and tables, but not different brand colors or fonts.

## Localization

All user-facing strings go through localization (EN and FR). ARB files move to `busin_ui`.
