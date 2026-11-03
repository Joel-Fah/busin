# 0009: Design system and frontend stack for the admin portal

Status: accepted, 2026-11-03. Extends [ADR 0002](0002-admin-web-nextjs.md). The Mapbox part is decided here and built in a later PR, where [ADR 0008](0008-map-provider.md) gets its status updated.

## Context
The portal works but looks unfinished: a flat sidebar, plain tables, one global stylesheet. The owner asked for a soft, welcoming identity that stays consistent over time, works on tablets first, and is documented in one place.

## Decision
- **Styling**: Tailwind CSS 4 with the BusIn tokens as CSS variables (`app/theme.css`, colours in `app/globals.css`). Tailwind loads without its reset, and the old stylesheet sits in a lower layer, so pages migrate one at a time. `globals.css` is deleted when the last page moves.
- **Typeface**: Plus Jakarta Sans (variable, SIL Open Font Licence), self-hosted from `@fontsource-variable/plus-jakarta-sans`. It exists for web and Flutter, so every tier can share it. It replaces Bevellier, whose licence is not recorded anywhere in the repository. The Bevellier files stay in `apps/legacy` and `apps/admin_web/app/fonts` until the owner confirms they can go.
- **Icons**: Hugeicons, stroke rounded, free set (`@hugeicons/react`, `@hugeicons/core-free-icons`), always through the `Icon` component. A few icons ship as one filled outline instead of a stroke (FlagTriangleRight is one); the library would add its stroke on top and make them look twice as heavy, so `Icon` adds only the small difference to the common weight (`lib/ui/icons.ts`).
- **Animation**: GSAP for the larger moves (navigation reveal, tab indicator, logo draw, sheets). CSS for simple state changes. Everything respects `prefers-reduced-motion`. `flutter_animate` is the mobile counterpart, later.
- **Shape**: five radii (8, 16, 20, 28, 36). No pills, no squircles. A nested shape uses outer radius minus padding (`lib/ui/radius.ts`).
- **Contour**: a stitched thread drawn inside containers (`Contour`, an SVG with round-capped dashes), 16px in on cards and the navigation bar, 4px on buttons, and on its own around empty states. On buttons, links and empty states the thread slides forward and thickens a little on hover or focus, and eases back on leave; on cards it stays still. Its colour is the element's own colour mixed toward its text, and does not change on hover. One-sided borders, solid contours and underlined links are not used.
- **Theme**: system, light or dark, chosen in the browser and stored in `localStorage`; a small inline script applies it before first paint. No server state.
- **Navigation**: one floating bottom bar replaces the sidebar (glass fill with blur, thread contour 6px in, never hides on scroll). Wide screens show every tab as icon over label; tablets in portrait and phones show the current page and a Menu button that opens the tabs upward in groups. The logo and the profile picture sit at the ends; theme, language and sign out live on the profile page. A dock above the tabs (`NavDock`) lets a page add its own content while the tabs stay put. The bar slides in from below when the dashboard loads, after a logo intro that draws the outline and then fills it (once per session, skippable, off for reduced motion). A pre-paint script sets the page up so nothing flashes.
- **Page header**: a large headline with a help button beside it that opens a side sheet of worked, real-life examples (English and French).
- **Texture**: grain and rough edges for decoration only (banners, feature cards, backdrops), never behind tables, forms or small text. Grain is an inline SVG noise (`--noise-fine`, `--noise-coarse`) blended with soft-light at a strength set by `--grain`, so it costs no download; rough edges use one SVG displacement filter. Both are static and off in high contrast mode.
- **Documentation**: a hidden, admin-only page at `/styleguide` documents brand, voice, colour, type, shape, contour, icons, motion, imagery and every component. It is updated in the same change as any component. A unit test fails if a text and background token pair drops under WCAG AA.
- **Maps**: Mapbox GL JS behind the existing provider-neutral component, with MapLibre kept as the alternative. Built in a later PR. The Mapbox token is a public (`pk.`), URL-restricted token held in `MAPBOX_API_KEY` in the portal's server environment; a secret (`sk.`) token must never be used.
- **Imagery**: 3D objects from thiings.co and photographs from Pexels, only where an image carries meaning. Existing images stay. Files are WebP under `apps/admin_web/public/` (3D at 480px, photographs about 100 to 170 KB).
- **Favicon**: the logo alone on a transparent background (`app/icon.svg`), teal on light and white on dark following the device setting. The ICO fallback is teal; the Apple touch icon sits on white because iOS fills transparency with black.
- **Container**: a Dockerfile for the portal comes last. It does not apply to the mobile apps.

## Consequences
- Pages are redesigned in later PRs. Until then old and new styles coexist, which is why the reset is off.
- The styleguide is English only, since it is internal documentation. Everything user-facing stays in English and French.
- New dependencies are pinned exactly: tailwindcss 4.3.4, postcss 8.5.32, gsap 3.15.0, @hugeicons/react 1.1.10, @hugeicons/core-free-icons 4.4.0, @fontsource-variable/plus-jakarta-sans 5.3.0.
