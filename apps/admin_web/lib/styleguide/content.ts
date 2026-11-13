/**
 * The words of the styleguide, kept as data so the page, the Markdown export (for AI agents) and the PDF export (for
 * reading and printing) all say the same thing. Change a rule here and every form of the guide follows. Values that
 * live in the stylesheets (colours, radii) come from lib/ui; tests keep those in step with the CSS.
 */

export type SectionId =
  | "overview"
  | "voice"
  | "logo"
  | "colour"
  | "type"
  | "shape"
  | "contour"
  | "texture"
  | "icons"
  | "navigation"
  | "motion"
  | "imagery"
  | "components"
  | "rules";

export const SECTIONS: { id: SectionId; title: string; intro: string }[] = [
  {
    id: "overview",
    title: "Overview",
    intro:
      "BusIn helps a school run its campus buses: who is subscribed, who boarded, where the buses stop. The portal is for the people who run that.",
  },
  {
    id: "voice",
    title: "Voice and tone",
    intro:
      "The portal is calm and plain. Staff and administrators read it between other jobs, so it says what happened and what to do next. The student app is warmer and lighter, but uses the same words for the same things.",
  },
  {
    id: "logo",
    title: "Logo",
    intro:
      "The hand-lettered mark. Teal on light surfaces, white on dark ones. Keep clear space of at least one third of its height around it, and never stretch, recolour or outline it.",
  },
  {
    id: "colour",
    title: "Colour",
    intro:
      "Deep teal is the brand, orange is the action. Both themes use the same tokens, so a component never needs to know which theme it is in.",
  },
  {
    id: "type",
    title: "Typography",
    intro:
      "Plus Jakarta Sans, a variable font with a friendly geometric shape. It is open licence and exists for web and Flutter, so every tier can use the same face. It replaces Bevellier, whose licence we could not confirm.",
  },
  {
    id: "shape",
    title: "Shape",
    intro:
      "Rounded beyond normal, never a pill and never a squircle. Five sizes on a 4px grid: xs for chips and small tags, sm for buttons and fields, md, lg for cards and xl for large surfaces. When one shape sits inside another, the inner radius is the outer radius minus the padding between them, so the corners stay concentric.",
  },
  {
    id: "contour",
    title: "Contour",
    intro:
      "A thin rounded stroke drawn inside a container, 16px in on cards, 6px in on the navigation bar, 4px in on buttons. It is drawn as a stitched thread, not a solid line: round-capped dashes. On buttons, links and empty states the thread slides forward when you hover or focus and back when you leave; on cards it stays still. Its colour never changes: it is the element's own colour, mixed toward its text. It is the quiet signature that makes BusIn surfaces recognisable. Empty states use the thread on its own, without a card.",
  },
  {
    id: "texture",
    title: "Texture",
    intro:
      "A little roughness keeps the interface from feeling sterile. Grain and rough edges are decoration: they live on banners, feature cards and backdrops, never behind tables, forms or small text.",
  },
  {
    id: "icons",
    title: "Icons",
    intro:
      "Hugeicons, stroke rounded, free set, drawn at 1.8 stroke. Always through the Icon component so size and stroke stay uniform. Icons come with a label unless the meaning is universal.",
  },
  {
    id: "navigation",
    title: "Navigation",
    intro:
      "One floating bar at the bottom of every page, in place of a sidebar. It never hides on scroll and never changes between pages, so it is always where the thumb expects it.",
  },
  {
    id: "motion",
    title: "Motion",
    intro:
      "Motion is gentle and short. GSAP drives the larger moves (navigation bar reveal, side sheet, logo draw, later the tab indicator); simple state changes use CSS. All of it stops when the device asks for reduced motion.",
  },
  {
    id: "imagery",
    title: "Imagery",
    intro:
      "Illustration only where it carries meaning, such as an empty state or a first-run message. It is never decoration. Keep every image that is already in the app.",
  },
  { id: "components", title: "Components", intro: "Each component is shown in its states. New components are added here first." },
  { id: "rules", title: "Never", intro: "Rules that keep the system honest." },
];

export const section = (id: SectionId) => SECTIONS.find((s) => s.id === id)!;

export const GUIDE = {
  name: "BusIn design system",
  title: "Styleguide",
  summary: "How the admin portal looks, reads and moves. One reference, so everything we build stays consistent over time.",
  upkeep: "Update this page in the same change as any component. It is not linked from the navigation.",
};

export const PRINCIPLES: [string, string][] = [
  ["Gentle", "Soft surfaces, rounded shapes and quiet motion. Nothing shouts."],
  ["Clear", "One main action per screen. Plain words. Every state is labelled, never colour alone."],
  ["Consistent", "Every colour, radius and duration is a token. Components never use a literal value."],
];

export const AUDIENCE =
  "Audience: school administrators, mostly on tablets and desktops, and drivers on phones in the ops app. Everything works from 390px wide up, and is designed desktop first.";

export const VOICE_RULES = [
  "Write the way a helpful colleague speaks. Short sentences, active verbs.",
  "Use the product words: semester, subscription, stop, trip, boarding, bus. Do not invent synonyms.",
  "Say what happened, then how to fix it. No blame, no jargon, no error codes on screen.",
  "Directions read Going to school and Going home.",
  "English and French ship together. If a string is not translated, it is not finished.",
  "No emojis, anywhere.",
];

export const VOICE_PAIRS: { do: string; dont: string }[] = [
  { do: "That bus is not available. Pick one that is in service.", dont: "Error 422: invalid bus_id." },
  { do: "Nothing to review right now.", dont: "No records found." },
  { do: "Save stop", dont: "Submit" },
];

export const LOGO_MOTION =
  "Opening animation (arrives with the shell): the outline draws, then the fill fades in. Once per session, skippable, and static when the device asks for reduced motion.";

export const COLOUR_STATE_NOTE =
  "State text is darker than the app fills so it stays readable on its tint. A state always carries an icon or a label as well as its colour.";

/** The type scale as it is used in the portal (sizes in px). */
export const TYPE_SCALE: { role: string; size: number; weight: number; sample: string; extra?: string }[] = [
  { role: "Page headline", size: 48, weight: 800, sample: "Page headline, 48 extra bold", extra: "tight letter spacing" },
  { role: "Section title", size: 30, weight: 700, sample: "Section title, 30 bold", extra: "tight letter spacing" },
  { role: "Card title", size: 20, weight: 700, sample: "Card title, 20 bold" },
  { role: "Body", size: 16, weight: 400, sample: "Body text, 16 regular. Where the buses stop and who boards them." },
  { role: "Secondary", size: 14, weight: 400, sample: "Secondary text, 14 regular, muted. Used for hints and descriptions.", extra: "muted colour" },
  { role: "Label", size: 12, weight: 600, sample: "Label, 12 semibold, spaced", extra: "uppercase, wide letter spacing, muted" },
];

export const TYPE_NOTE =
  "Headlines are larger than before and sit tight; body copy keeps a line height of 1.5. Use weight, not size, to separate neighbours.";

export const RADIUS_USE: Record<string, string> = {
  xs: "chips and small tags",
  sm: "buttons and fields",
  md: "menus and small panels",
  lg: "cards",
  xl: "large surfaces, photographs",
};

export const GRAIN_NOTE =
  "Two strengths of noise, drawn by an inline SVG filter, so there is no image to download and it stays sharp at any size. Set the strength with --grain (about 0.5 to 1, with soft-light blending, which is gentle on light colours). It sits above the background and below the content, does not animate, and is hidden in high contrast mode.";

export const ROUGH_NOTE =
  "The outline wobbles like cut paper or a marker stroke. Use it on a decorative shape behind or beside text, never on the text itself, and render the filter once per page.";

export const TEXTURE_USE = [
  "Page banners and the first card of a page: fine grain.",
  "Large empty-state backdrops and illustrations: coarse grain, kept faint.",
  "Never on tables, forms, buttons or anything under about 18px of text.",
  "Check contrast with the grain on; the strength may never lower it below WCAG AA.",
];

export const NAV_RULES = [
  "Glass: a translucent surface with a blur, so content shows softly behind it.",
  "Tabs are icon above label. The current page is tinted; the others sit on the bar with no background of their own.",
  "The logo and the profile picture sit at the ends and take no label. Theme, language and sign out live on the profile page.",
  "On wide screens every tab shows. On tablets in portrait and on phones the bar shows the current page and a Menu button that opens the tabs upward, grouped.",
  "The bar slides in from below when the dashboard loads, once, after the logo intro. It does not replay between pages.",
  "A page can fill the space above the tabs (the dock). The bar grows upward and the tabs stay in place.",
  "A small accent count sits on a tab's icon when something waits there: subscription requests to review, students to verify. Above nine it reads 9+. On small screens the Menu button shows the total. The exact number is the tab's description for assistive technology, so its name stays the page's name.",
];

export const NAV_HELP =
  "Every page starts with a large headline. A help button beside it opens a side sheet with worked examples from real days, so a new administrator learns the page by reading situations, not instructions. See the Overview page for the first one.";

export const MOTION_STEPS: { name: string; ms: number; use: string }[] = [
  { name: "Fast", ms: 160, use: "Hover and press feedback" },
  { name: "Standard", ms: 280, use: "Menus, sheets, tab changes" },
  { name: "Slow", ms: 520, use: "Page-level entrances, the logo fill" },
];

export const EASING = "cubic-bezier(0.22, 1, 0.36, 1)";

export const MOTION_NOTE =
  "Easing is a soft ease-out (0.22, 1, 0.36, 1) everywhere. Loading uses shimmers shaped like the content they stand in for, never a spinner on its own.";

export const ILLUSTRATION_NOTE =
  "From thiings.co, free to use. They sit on the page background with no frame, at 96 to 160px, and are never used as wallpaper. Stored as WebP at 480px.";

export const PHOTO_NOTE =
  "From Pexels, free to use without credit. Real transport scenes in warm light. Large corners (36px), WebP, about 100 to 170 KB, always with alt text.";

/** The 3D objects in public/illustrations (file name without .webp, label). */
export const THREE_D: [string, string][] = [
  ["bus", "Bus"],
  ["bus-stop", "Bus stop"],
  ["ticket1", "Ticket"],
  ["papers", "Papers"],
  ["seat", "Seat"],
  ["semester", "Semester"],
  ["waiting", "Waiting"],
  ["verified", "Verified"],
  ["blocked", "Blocked"],
  ["staff", "Staff"],
];

/** How each component behaves, in the words the page uses under its demo. */
export const COMPONENT_NOTES: { name: string; note: string }[] = [
  { name: "Buttons", note: "Primary (accent), secondary, ghost and danger, with an optional icon; a disabled button stays readable. A link that looks like a button is ButtonLink. Labels are verbs that say what happens: Save stop, not Submit." },
  {
    name: "Sign in with Google",
    note: "The sign-in button carries Google's own four-colour G on a small white disc (GoogleMark), never a generic icon, as Google's brand rules ask; the label says what happens in the page's language. The student and ops apps use the same mark (GoogleMark in busin_ui).",
  },
  { name: "Chips", note: "A short state label in a tone: neutral, accent, ok (Approved), warn (Pending), bad (Rejected), info (Running). The label always carries the meaning; the tone only supports it." },
  {
    name: "Tags",
    note: "A comma, a space or Enter turns the text into a tag; each tag has a remove button, and clicking it puts it back in the field to edit. Backspace in the empty field edits the last tag. A tag that breaks the rule is shown in the error colour. The tags are sent with the form as one comma-separated field.",
  },
  {
    name: "Dropdown, date and time",
    note: "All three are drawn in the design system, not by the browser, so they match everything else. Each opens up or down, whichever has room, and sits above sheets and modals. Keyboard: arrows move, Home and End jump, Enter picks, Escape closes; in the calendar Page Up and Page Down change the month; in the dropdown, typing jumps to a match. Each sends its value with the form.",
  },
  { name: "Checkbox, radio and switch", note: "Each has a visible label and an optional hint; disabled choices stay readable. A switch is for a setting that takes effect, a checkbox for a choice in a form." },
  {
    name: "Tabs with counters",
    note: "Tabs are links, so each one is a real address and works without scripts. The current tab is raised, and the highlight slides to the next with an elastic stretch. Unselected tabs have no background. Counters take a tone: warn for work waiting, ok for done.",
  },
  { name: "Menu", note: "A menu can open below, above, to the left or to the right of its button. Whatever is asked, it moves to the side with room if it would run off the screen." },
  {
    name: "Table",
    note: "One set of pieces builds every list: TableCard (the raised, rounded surface that scrolls sideways on a narrow screen), DataTable, Head, Th, Tr and Td. They are real table elements, so screen readers get a real table. Headings are quiet uppercase, rows tint on hover, a person is an avatar and a name, a state is a chip with its label, and a name that leads somewhere is a link without an underline. Show only the columns that help; never coordinates or ids.",
  },
  {
    name: "Pagination",
    note: "Under every list that has more than one page: the range on the left, Previous and Next on the right. Each is a link to a real address, so the page can be bookmarked, and a button only appears when there is somewhere to go. A page past the last one is an empty list, never an error. Lists show 20 at a time by default; Per page offers 10, 20, 50 or 100, kept in the address with the filters, and changing it goes back to the first page. Lists are paginated by the server, so a long list never loads more than one page (100 rows at most).",
  },
  {
    name: "Toasts",
    note: "A short message that floats at the top and leaves by itself: the stitched thread, an icon for its state and a close button. The button is a rounded tile in a slightly deeper tint of the state, and a ring along its edge empties as the time runs out; there is no other stroke. It eases in over 460 ms, glides back up over 380 ms (a plain fade under reduced motion) and takes one at a time. Hovering it, or focusing it with the keyboard, pauses the clock and the ring; moving away carries on from where it stopped. Good news leaves quickly (2.8 s), a problem stays to be read (7 s). After a save, a page opens with its confirmation as a toast (FlashToast reads the done value in the address and then clears it). Use it for confirmations and reminders; an error the person must act on stays on the page, as a notice. The apps have the same component with the same times and ring (swipe up to dismiss).",
  },
  {
    name: "Notices",
    note: "A short message in a tone. Successes are announced politely (status), failures at once (alert). Say what happened, then what to do; the tone is never the only signal.",
  },
  {
    name: "Empty and loading states",
    note: "An empty list says so with the thread around it and, where it helps, an illustration; it is not a card. While a list loads, a shimmer in the same shapes holds its place, so nothing jumps when the content arrives.",
  },
  {
    name: "Sticky toolbar",
    note: "The search and filters of a list stay in reach. Scrolled past, they stick to the top and realign into one compact glass row (search and tabs side by side, labels kept for screen readers) while the list moves behind; back at the top they glide to their roomy layout again. The change animates in both directions, is instant for people who prefer less motion, and the list below never jumps. On a narrow screen the compact bar keeps wrapping, because one row would not fit. Wrap a list's controls in StickyToolbar to get it; People, Subscriptions and Trips are the examples to open. When a toolbar is only tabs (Subscriptions, Trips) they stretch to fill the bar as it sticks, so the bar is as wide as the table.",
  },
  {
    name: "Column filters",
    note: "A list is narrowed from its column headings: a small filter button after the name opens a panel of choices (a calendar for a date column), and a dot marks a heading that is filtered. Each filter lives in the page address, so a filtered list can be shared and survives a reload; picking a choice is a link, so it works with the keyboard and without scripts. Every active filter also shows as a chip above the table that removes it with one click, and the numbers on the tabs follow the filters. Long lists of choices (more than eight) get a search box. Use them where a column has a short set of values worth narrowing by; not every column needs one.",
  },
  {
    name: "Tooltip",
    note: "Any element with a data-tip attribute gets one, on hover after a short pause and on keyboard focus; data-tip-side picks the side, and it moves to the side with room. It is drawn by one layer for the whole page, so it also serves map markers, and it replaces the browser's own title tooltip. Icon buttons keep their aria-label: the tooltip is a hint, not the only name.",
  },
  {
    name: "Side sheet and modal",
    note: "Both float with a margin all round and rounded corners, never docked to an edge. Danger actions (delete, suspend, sign out) always use the danger style, and a destructive choice asks first.",
  },
  { name: "Card", note: "A raised surface with the lg radius and the still thread 16px in. A number card puts a quiet label above a large extra bold figure." },
];

export const NEVER = [
  "No one-sided borders on cards or quotes.",
  "No solid contour. It is always the stitched thread.",
  "No underlined links. Use colour, weight or an icon.",
  "No pill shapes. Use the radius scale.",
  "No literal colours, radii or durations in a component. Use tokens.",
  "No state shown by colour alone.",
  "No grain or rough edge behind tables, forms or small text.",
  "No icon without a label unless its meaning is universal.",
  "No emojis.",
  "No text in only one language.",
];

/** The brand ramps (app/theme.css, from the apps' constants). A test keeps them in step with the stylesheet. */
export const RAMPS: Record<"teal" | "orange", Record<number, string>> = {
  teal: { 50: "#e9fffd", 100: "#c9fff9", 200: "#99fff7", 300: "#54fff5", 400: "#07fffc", 500: "#00e3ef", 600: "#00b4c9", 700: "#008fa1", 800: "#087282", 900: "#0c5d6d" },
  orange: { 50: "#fef8ec", 100: "#fde9c8", 200: "#fad28d", 300: "#f7b552", 400: "#ef7611", 500: "#d4550b", 600: "#b0380d", 700: "#8f2c11", 800: "#752512", 900: "#431005" },
};

export const SEED = "#002a33";

/** What each colour token is for, in a few words (for the exports). */
export const TOKEN_USE: Record<string, string> = {
  bg: "page background",
  surface: "cards, sheets, raised surfaces",
  "surface-2": "quiet fills: inputs, list items, hover",
  fg: "main text and icons",
  muted: "secondary text, hints",
  line: "dividers and hairlines",
  brand: "the brand colour (deep teal; light on dark)",
  "on-brand": "text on brand",
  accent: "the one main action, highlights",
  "on-accent": "text on accent",
  link: "links and interactive text",
  focus: "focus outline",
  ok: "success text and icons",
  "ok-bg": "success tint",
  warn: "warning text and icons",
  "warn-bg": "warning tint",
  bad: "error and danger text and icons",
  "bad-bg": "error tint",
  info: "information text and icons",
  "info-bg": "information tint",
};
