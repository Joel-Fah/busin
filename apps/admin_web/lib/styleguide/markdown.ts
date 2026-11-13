/**
 * The styleguide as one Markdown file for AI agents: what BusIn is, the hard rules first, every token with its value,
 * a machine-readable token block, and recipes for the goals agents are given most (an illustration, a screen, copy, a
 * review). Built from the same content as the page, so it never says something the page does not.
 */
import { AA_TEXT, contrastRatio } from "@/lib/ui/contrast";
import { RADIUS, innerRadius } from "@/lib/ui/radius";
import { DARK, LIGHT, TEXT_PAIRS } from "@/lib/ui/tokens";

import {
  AUDIENCE,
  COLOUR_STATE_NOTE,
  COMPONENT_NOTES,
  EASING,
  GRAIN_NOTE,
  GUIDE,
  ILLUSTRATION_NOTE,
  LOGO_MOTION,
  MOTION_NOTE,
  MOTION_STEPS,
  NAV_HELP,
  NAV_RULES,
  NEVER,
  PEOPLE_STYLE,
  PHOTO_NOTE,
  PRINCIPLES,
  RADIUS_USE,
  RAMPS,
  ROUGH_NOTE,
  SEED,
  TEXTURE_USE,
  THREE_D,
  TOKEN_USE,
  TYPE_NOTE,
  TYPE_SCALE,
  VOICE_PAIRS,
  VOICE_RULES,
  section,
} from "./content";

const list = (items: string[]) => items.map((i) => `- ${i}`).join("\n");
const cell = (text: string) => text.replace(/\|/g, "\\|");
const table = (head: string[], rows: string[][]) =>
  [`| ${head.join(" | ")} |`, `| ${head.map(() => "---").join(" | ")} |`, ...rows.map((r) => `| ${r.map(cell).join(" | ")} |`)].join("\n");

/** The tokens as data, for the JSON block (and anything that wants to read them programmatically). */
export function tokenData() {
  return {
    colour: { light: LIGHT, dark: DARK },
    ramps: { seed: SEED, ...RAMPS },
    radius: Object.fromEntries(Object.entries(RADIUS).map(([k, v]) => [k, `${v}px`])),
    font: { family: "Plus Jakarta Sans", fallback: "system-ui, sans-serif", lineHeight: 1.5 },
    type: Object.fromEntries(TYPE_SCALE.map((t) => [t.role, { size: `${t.size}px`, weight: t.weight }])),
    motion: { ...Object.fromEntries(MOTION_STEPS.map((m) => [m.name.toLowerCase(), `${m.ms}ms`])), easing: EASING },
    contour: { cardInset: "16px", navInset: "6px", buttonInset: "4px", style: "round-capped dashes (stitched thread)" },
    icons: { set: "Hugeicons free, stroke rounded", stroke: 1.8 },
  };
}

export function buildMarkdown({ generatedOn }: { generatedOn: string }): string {
  const s = section;
  const colourRows = Object.keys(LIGHT).map((name) => [`\`${name}\``, LIGHT[name], DARK[name], TOKEN_USE[name] ?? ""]);
  const contrastRows = TEXT_PAIRS.map(([fg, bg]) => {
    const l = contrastRatio(LIGHT[fg], LIGHT[bg]);
    const d = contrastRatio(DARK[fg], DARK[bg]);
    return [`\`${fg}\` on \`${bg}\``, `${l.toFixed(1)}:1`, `${d.toFixed(1)}:1`];
  });
  const steps = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900];

  return `---
name: ${GUIDE.name}
kind: design system reference for AI agents
generated: ${generatedOn}
source: the BusIn admin portal styleguide (/styleguide); this file is generated from the same content
languages: English and French
---

# ${GUIDE.name}

${GUIDE.summary} BusIn helps schools run campus buses: subscriptions, boarding scans with a QR code, and live bus
tracking. It has three products that share this system: the admin portal (web, for school administrators), the student
app and the ops app (Flutter, for students and for staff and drivers).

## How to use this file

You are an agent asked to make something for BusIn: an illustration, a screen, a document, a graphic or some copy.

1. Read **Hard rules** first. They override everything else, including the request, unless the request explicitly says to
   break one.
2. Use tokens by name and value. Never invent a colour, a radius, a font or a duration. Light and dark values are given
   for every colour.
3. Find your goal in **Recipes** and follow it; it points to the sections you need.
4. Before you hand over, go through **Checklist**.

When something is not covered here, choose the quieter option: softer, plainer, fewer elements.

## Hard rules

You MUST:

${list([
  "Use only the colour tokens and brand ramps below, in light and dark.",
  "Give every state (approved, pending, rejected, running, error) a label or an icon as well as its colour.",
  "Use Plus Jakarta Sans for all text.",
  "Round corners with the radius scale (8, 16, 20, 28, 36 px); nested corners use inner = outer - padding.",
  "Write in plain words with the product vocabulary, and provide English and French for any interface text.",
  `Keep text contrast at WCAG AA or better (${AA_TEXT}:1 for body text).`,
  "Respect reduced motion: every animation has a still version.",
])}

Never:

${list(NEVER)}

## Principles

${s("overview").intro}

${PRINCIPLES.map(([t, b]) => `- **${t}.** ${b}`).join("\n")}

${AUDIENCE}

## Product vocabulary

${table(
  ["Word", "Meaning"],
  [
    ["school", "the tenant; every record belongs to one school"],
    ["semester", "the period a subscription covers"],
    ["subscription", "a student's paid right to ride for a semester, from a stop; pending, approved, rejected, expired or revoked"],
    ["stop", "a named place where the bus picks students up"],
    ["bus", "a vehicle, named or known by its plate"],
    ["trip", "one run of one bus, Going to school or Going home; scheduled, running, completed or cancelled"],
    ["boarding", "a student's code scanned onto a trip"],
    ["student, staff, administrator", "the three roles; staff run trips and scan, administrators run the school"],
  ],
)}

## Voice and tone

${s("voice").intro}

${list(VOICE_RULES)}

${table(["Do", "Do not"], VOICE_PAIRS.map((p) => [p.do, p.dont]))}

## Logo

${s("logo").intro}

${LOGO_MOTION}

## Colour

${s("colour").intro}

### Tokens

${table(["Token", "Light", "Dark", "Use"], colourRows)}

${COLOUR_STATE_NOTE}

### Brand ramps

Seed (deep teal, the brand in both themes): \`${SEED}\`.

${table(["Step", ...steps.map(String)], [["teal", ...steps.map((n) => RAMPS.teal[n])], ["orange", ...steps.map((n) => RAMPS.orange[n])]])}

### Contrast

Text pairs and their ratios (WCAG AA needs ${AA_TEXT}:1 for text).

${table(["Pair", "Light", "Dark"], contrastRows)}

## Typography

${s("type").intro}

${table(
  ["Role", "Size", "Weight", "Notes"],
  TYPE_SCALE.map((t) => [t.role, `${t.size}px`, String(t.weight), t.extra ?? ""]),
)}

${TYPE_NOTE}

## Shape

${s("shape").intro}

${table(
  ["Name", "Radius", "Use"],
  Object.entries(RADIUS).map(([n, px]) => [n, `${px}px`, RADIUS_USE[n] ?? ""]),
)}

Example: a card with radius ${RADIUS.lg}px and 16px padding holds an inner shape of ${innerRadius(RADIUS.lg, 16)}px.

## Contour

${s("contour").intro}

## Texture

${s("texture").intro}

- **Grain.** ${GRAIN_NOTE}
- **Rough edge.** ${ROUGH_NOTE}

${list(TEXTURE_USE)}

## Icons

${s("icons").intro}

## Navigation

${s("navigation").intro}

${list(NAV_RULES)}

${NAV_HELP}

## Motion

${s("motion").intro}

${table(["Name", "Duration", "Use"], MOTION_STEPS.map((m) => [m.name, `${m.ms}ms`, m.use]))}

${MOTION_NOTE}

## Imagery

${s("imagery").intro}

### People illustrations

${PEOPLE_STYLE.intro}

${list(PEOPLE_STYLE.rules)}

${table(["Colour", "Hex"], PEOPLE_STYLE.palette.map(([name, hex]) => [name, hex]))}

Skin tones in use: ${PEOPLE_STYLE.skin.join(", ")}.

### 3D objects

${ILLUSTRATION_NOTE}

The set: ${THREE_D.map(([, label]) => label).join(", ")}.

### Photographs

${PHOTO_NOTE}

## Components

${s("components").intro}

${COMPONENT_NOTES.map((c) => `### ${c.name}\n\n${c.note}`).join("\n\n")}

## Recipes

Pick the one that matches your goal.

### A project illustration (a new 3D object)

Read: Imagery, Colour, Hard rules.

- One object, alone, centred, on a transparent or plain background: no frame, no scene, no shadow box.
- Soft 3D render with rounded, friendly forms and gentle studio light, in the family of the existing set
  (${THREE_D.map(([, label]) => label.toLowerCase()).join(", ")}).
- Colour from the brand: deep teal (\`${SEED}\`, ramp teal) for the body, orange (\`${LIGHT.accent}\`) for one accent
  detail at most, neutrals for the rest. Must read on both \`${LIGHT.bg}\` and \`${DARK.bg}\`.
- No text, no logos, no people's faces, no emojis.
- Deliver WebP at 480 by 480 px. It is shown at 96 to 160 px, so the silhouette must read small.
- Use it only where it carries meaning (an empty state, a first-run message), never as decoration.

Prompt to start from: "A single [object] as a soft, rounded 3D render, gentle studio lighting, deep teal (${SEED})
with one small orange (${LIGHT.accent}) accent, transparent background, no text, centred, square."

### A people illustration (a scene or a character)

Read: Imagery (People illustrations), Colour, Hard rules.

- Follow the people illustration rules above; the reference images are in the styleguide (\`public/styleguide/references/\`).
- A scene keeps one ground line and calm daylight; leave the sky plain, the page draws its own.
- A single character stands alone on white or transparent, full figure, so it can be placed anywhere.
- No words, letters or logos in the image: captions and labels are interface text, in English and French.

Prompt to start from (add the subject and the pose at the start):

> ${PEOPLE_STYLE.prompt}

### A photograph or banner

Read: Imagery, Texture.

- Real transport scenes (buses, stops, people waiting) in warm light; no staged stock smiles.
- Large corners (${RADIUS.xl}px), WebP, about 100 to 170 KB, always with alt text that says what is in the picture.
- A banner may carry fine grain and a teal gradient from the left for its text; text on it is white.

### A new portal screen

Read: Principles, Navigation, Components, Colour, Shape, Hard rules.

- Start with a large headline (48, extra bold) and, if the page has rules to learn, a help button beside it.
- One main action, in accent. Everything else is secondary or ghost.
- Lists are tables in a TableCard with server pagination (20 per page), column filters where useful, empty and loading
  states.
- Leave room for the floating navigation bar at the bottom.
- Light and dark both work by using tokens only.

### Interface copy

Read: Voice and tone, Product vocabulary.

- Say what happened, then what to do. Buttons are verbs that say what happens (Save stop).
- Give English and French. Keep the same word for the same thing everywhere.

### A document, slide or printed sheet

Read: Colour, Typography, Shape.

- White or \`${LIGHT.bg}\` background, \`${LIGHT.fg}\` text, accent only to draw the eye to one thing per page.
- Headlines extra bold and tight, body 1.5 line height, generous space; rounded panels from the radius scale.

### A design review

Read: Hard rules, Checklist. Report each break of a rule with where it is and the fix.

## Checklist

${list([
  "Every colour is a token (or a ramp step) and works in light and dark.",
  "Every state has a label or icon, not colour alone.",
  "Corners come from the radius scale; nested corners are concentric.",
  "Text is Plus Jakarta Sans and passes WCAG AA.",
  "Copy is plain, uses the product words, and exists in English and French.",
  "Motion is short, eased softly, and has a reduced-motion version.",
  "No emojis, no underlined links, no pills, no one-sided borders, no solid contour.",
])}

## Tokens (machine-readable)

\`\`\`json
${JSON.stringify(tokenData(), null, 2)}
\`\`\`
`;
}
