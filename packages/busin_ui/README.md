# busin_ui

Design system for the BusIn Flutter apps: palette, shape scale, Material 3 themes in Plus Jakarta Sans, shared widgets, and English and French strings. It matches the admin portal (see its `/styleguide` page and [ADR 0009](../../docs/decisions/0009-design-system.md)), so every tier looks like one product. No data access lives here.

```dart
MaterialApp(
  theme: BusinTheme.light(),
  darkTheme: BusinTheme.dark(),
  localizationsDelegates: businLocalizationsDelegates,
  supportedLocales: businSupportedLocales,
);
```

- **Tokens**: `BusinPalette` (read it with `BusinPalette.of(context)`; never hard-code a colour), `BusinRadius` (8, 16, 20, 28, 36, and `innerRadius` for nested corners), `BusinSpace` (4 pixel grid), `BusinMotion`. Text and background pairs are tested to WCAG AA in both palettes.
- **Widgets**: `BusinButton` (primary, secondary, danger, ghost; busy state), `BusinTextField` (always a leading icon and a placeholder), `StatusChip`, `UserAvatar`, `StatCard`, `EmptyState`.
- **Words**: `BusinL10n` has the shared strings (actions, errors, roles, statuses, directions, semesters). `BusinLabels` names the `busin_core` enums and turns a `RepositoryException` into a message. A screen's own strings live in its app.
- **Icons**: Hugeicons, stroke rounded (`HugeIcons.strokeRounded...`).
- **Font**: Plus Jakarta Sans, bundled (SIL Open Font Licence, `assets/fonts/OFL.txt`). The portal dropped Bevellier because its licence is unknown, so the Flutter apps do too.

Change the ARB files in `lib/src/l10n`, then run `fvm flutter gen-l10n` inside this folder; the generated files are committed.

Tests: `fvm flutter test`.
