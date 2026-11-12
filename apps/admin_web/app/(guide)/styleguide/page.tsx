import type { Metadata } from "next";
import Image from "next/image";
import { Suspense } from "react";
import {
  ArrowLeft01Icon,
  Bus01Icon,
  Calendar02Icon,
  Copy01Icon,
  Delete02Icon,
  Edit02Icon,
  FlagTriangleRightIcon,
  GeometricShapes01Icon,
  Mail01Icon,
  Menu03Icon,
  Navigation03Icon,
  ReceiptTextIcon,
  Search01Icon,
  UserMultiple02Icon,
} from "@hugeicons/core-free-icons";

import { Button, ButtonLink } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Avatar } from "@/components/ui/Avatar";
import { Chip } from "@/components/ui/Chip";
import { ColumnFilter } from "@/components/ui/ColumnFilter";
import { FilterChips } from "@/components/ui/FilterChips";
import { Contour } from "@/components/ui/Contour";
import { EmptyState } from "@/components/ui/EmptyState";
import { Icon } from "@/components/ui/Icon";
import { RoughFilter } from "@/components/ui/RoughFilter";
import { Checkbox, RadioGroup, Switch } from "@/components/ui/Choice";
import { DatePicker } from "@/components/ui/DatePicker";
import { DateTimePicker } from "@/components/ui/DateTimePicker";
import { TimePicker } from "@/components/ui/TimePicker";
import { Input } from "@/components/ui/Input";
import { DomainsTagInput } from "@/components/ui/TagInput";
import { Select } from "@/components/ui/Select";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { Notice } from "@/components/ui/Notice";
import { Pager } from "@/components/ui/Pager";
import { Skeleton } from "@/components/ui/Skeleton";
import { DataTable, Head, TableCard, Td, Th, Tr } from "@/components/ui/Table";
import { ThemeToggle } from "@/components/ui/ThemeToggle";
import { requireAdmin } from "@/lib/auth";
import { AA_TEXT, contrastRatio } from "@/lib/ui/contrast";
import { RADIUS, innerRadius } from "@/lib/ui/radius";
import { DARK as dark, LIGHT as light, TEXT_PAIRS } from "@/lib/ui/tokens";

import { MenuDemo, MenuPlacementDemo, ModalDemo, SheetDemo, TabsDemo, ToastDemo } from "./Demos";
import { Pair, Section } from "./Section";
import { SectionRail } from "./SectionRail";

export const metadata: Metadata = { title: "Styleguide" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

const SECTIONS = [
  ["overview", "Overview"],
  ["voice", "Voice and tone"],
  ["logo", "Logo"],
  ["colour", "Colour"],
  ["type", "Typography"],
  ["shape", "Shape"],
  ["contour", "Contour"],
  ["texture", "Texture"],
  ["icons", "Icons"],
  ["navigation", "Navigation"],
  ["motion", "Motion"],
  ["imagery", "Imagery"],
  ["components", "Components"],
  ["rules", "Never"],
] as const;

const NAV_ICONS = [
  ["Overview", GeometricShapes01Icon],
  ["People", UserMultiple02Icon],
  ["Stops", FlagTriangleRightIcon],
  ["Trips", Navigation03Icon],
  ["Boardings", ReceiptTextIcon],
  ["Semesters", Calendar02Icon],
  ["Buses", Bus01Icon],
  ["Menu", Menu03Icon],
  ["Back", ArrowLeft01Icon],
] as const;

const THREE_D = [
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
] as const;

// A bento layout: each tile has its own size and crop. Wide tiles take the middle of a tall photo.
const BENTO = [
  {
    file: "bus-aerial",
    id: "21576182",
    alt: "A blue and white city bus at a stop beside a busy road, seen from above, with people walking on the pavement",
    tile: "row-span-2 sm:col-span-2 sm:row-span-3",
    focus: "50% 40%",
  },
  {
    file: "bus-stop-street",
    id: "17859087",
    alt: "A city street in warm evening light with a bus stop sign and shelter in front of an old stone building",
    tile: "sm:col-span-2 sm:row-span-2",
    focus: "50% 62%",
  },
  {
    file: "bus-shelter-bw",
    id: "19443791",
    alt: "Black and white photo of people waiting together under a bus shelter",
    tile: "row-span-2 sm:col-span-2 sm:row-span-3",
    focus: "50% 55%",
  },
  {
    file: "school-bus-brick",
    id: "40615028",
    alt: "A white school bus parked on an empty lot beside a red brick building",
    tile: "col-span-2 sm:col-span-2 sm:row-span-1",
    focus: "50% 74%",
  },
] as const;

const SURFACE_TOKENS = ["bg", "surface", "surface-2", "line", "fg", "muted", "brand", "accent", "link"];
const STATE_TOKENS = ["ok", "warn", "bad", "info"];

export default function StyleguidePage() {
  return (
    <Suspense fallback={<section aria-busy="true" />}>
      <Styleguide />
    </Suspense>
  );
}

async function Styleguide() {
  await requireAdmin();

  return (
    <div lang="en" className="relative mx-auto w-full min-w-0 max-w-5xl">
      <RoughFilter />
      <div className="mb-4">
        <ButtonLink href="/" variant="ghost" icon={ArrowLeft01Icon} className="-ml-4">
          Back to the portal
        </ButtonLink>
      </div>

      <header className="texture-grain relative overflow-hidden rounded-xl bg-seed text-white [--grain:1]">
        <Image
          src="/styleguide/photos/banner-brand-board.webp"
          alt="A brand strategy board with a colour palette, mood cards and a clipboard on a concrete floor"
          fill
          priority
          sizes="(min-width: 1152px) 1100px, 100vw"
          className="-z-10 object-cover"
        />
        <div className="absolute inset-0 -z-10 bg-gradient-to-r from-seed via-seed/80 to-transparent" />
        <div className="flex min-h-72 flex-col justify-end gap-3 p-8 sm:p-12">
          <p className="text-sm font-semibold text-white/80">BusIn design system</p>
          <h1 className="text-5xl font-extrabold tracking-tight sm:text-6xl">Styleguide</h1>
          <p className="max-w-lg text-base text-white/85">
            How the admin portal looks, reads and moves. One reference, so everything we build stays consistent over
            time.
          </p>
        </div>
      </header>

      <div className="mt-6 flex flex-wrap items-center justify-between gap-4">
        <p className="max-w-xl text-sm text-muted">
          Update this page in the same change as any component. It is not linked from the navigation.
        </p>
        <ThemeToggle labels={{ group: "Theme", system: "System", light: "Light", dark: "Dark" }} />
      </div>

      <nav aria-label="Jump to a section" className="mt-6 flex flex-wrap gap-x-5 gap-y-2 min-[94rem]:hidden">
        {SECTIONS.map(([id, label]) => (
          <a key={id} href={`#${id}`} className="text-sm font-semibold text-muted no-underline hover:text-fg">
            {label}
          </a>
        ))}
      </nav>

      <div className="mt-4">
      <Section
        id="overview"
        title="Overview"
        intro="BusIn helps a school run its campus buses: who is subscribed, who boarded, where the buses stop. The portal is for the people who run that."
      >
        <div className="grid gap-4 sm:grid-cols-3">
          {[
            ["Gentle", "Soft surfaces, rounded shapes and quiet motion. Nothing shouts."],
            ["Clear", "One main action per screen. Plain words. Every state is labelled, never colour alone."],
            ["Consistent", "Every colour, radius and duration is a token. Components never use a literal value."],
          ].map(([title, body]) => (
            <Card key={title} className="p-7">
              <h3 className="text-lg font-bold">{title}</h3>
              <p className="mt-2 text-sm text-muted">{body}</p>
            </Card>
          ))}
        </div>
        <p className="mt-6 max-w-2xl text-sm text-muted">
          Audience: school administrators, mostly on tablets and desktops, and drivers on phones in the ops app.
          Everything works from 390px wide up, and is designed desktop first.
        </p>
      </Section>

      <Section
        id="voice"
        title="Voice and tone"
        intro="The portal is calm and plain. Staff and administrators read it between other jobs, so it says what happened and what to do next. The student app is warmer and lighter, but uses the same words for the same things."
      >
        <ul className="m-0 grid list-none gap-2 p-0 text-sm sm:grid-cols-2">
          {[
            "Write the way a helpful colleague speaks. Short sentences, active verbs.",
            "Use the product words: semester, subscription, stop, trip, boarding, bus. Do not invent synonyms.",
            "Say what happened, then how to fix it. No blame, no jargon, no error codes on screen.",
            "Directions read Going to school and Going home.",
            "English and French ship together. If a string is not translated, it is not finished.",
            "No emojis, anywhere.",
          ].map((line) => (
            <li key={line} className="rounded-md bg-surface-2 p-4">
              {line}
            </li>
          ))}
        </ul>
        <div className="mt-6 space-y-3">
          <Pair doText="That bus is not available. Pick one that is in service." dontText="Error 422: invalid bus_id." />
          <Pair doText="Nothing to review right now." dontText="No records found." />
          <Pair doText="Save stop" dontText="Submit" />
        </div>
      </Section>

      <Section id="logo" title="Logo" intro="The hand-lettered mark. Teal on light surfaces, white on dark ones. Keep clear space of at least one third of its height around it, and never stretch, recolour or outline it.">
        <div className="grid gap-4 sm:grid-cols-2">
          <div className="relative flex h-44 items-center justify-center rounded-lg bg-surface shadow-soft">
            <Contour radius={28} />
            <Image src="/brand/cyan.svg" alt="BusIn logo, teal" width={164} height={101} />
          </div>
          <div className="relative flex h-44 items-center justify-center rounded-lg bg-seed">
            <Contour radius={28} />
            <Image src="/brand/white.svg" alt="BusIn logo, white" width={164} height={101} />
          </div>
        </div>
        <p className="mt-4 text-sm text-muted">
          Opening animation (arrives with the shell): the outline draws, then the fill fades in. Once per session,
          skippable, and static when the device asks for reduced motion.
        </p>
      </Section>

      <Section
        id="colour"
        title="Colour"
        intro="Deep teal is the brand, orange is the action. Both themes use the same tokens, so a component never needs to know which theme it is in."
      >
        <h3 className="mb-3 text-lg font-bold">Surface and text tokens</h3>
        <Swatches names={SURFACE_TOKENS} light={light} dark={dark} />
        <h3 className="mt-8 mb-3 text-lg font-bold">State tokens</h3>
        <p className="mb-3 text-sm text-muted">
          State text is darker than the app fills so it stays readable on its tint. A state always carries an icon or a
          label as well as its colour.
        </p>
        <Swatches names={STATE_TOKENS.flatMap((n) => [n, `${n}-bg`])} light={light} dark={dark} />
        <h3 className="mt-8 mb-3 text-lg font-bold">Brand ramps</h3>
        <Ramp name="teal" />
        <Ramp name="orange" />
        <h3 className="mt-8 mb-3 text-lg font-bold">Contrast (WCAG AA needs {AA_TEXT} for text)</h3>
        <div className="overflow-x-auto rounded-md bg-surface shadow-soft">
          <table className="w-full text-left text-sm">
            <thead className="text-muted">
              <tr>
                <th className="px-4 py-3 font-semibold">Text on background</th>
                <th className="px-4 py-3 font-semibold">Light</th>
                <th className="px-4 py-3 font-semibold">Dark</th>
              </tr>
            </thead>
            <tbody>
              {TEXT_PAIRS.map(([fg, bg]) => (
                <tr key={`${fg}-${bg}`} className="border-t border-line">
                  <td className="px-4 py-3">
                    {fg} on {bg}
                  </td>
                  <Ratio value={contrastRatio(light[fg], light[bg])} />
                  <Ratio value={contrastRatio(dark[fg], dark[bg])} />
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <p className="mt-3 text-sm text-muted">A unit test fails if any pair above drops under {AA_TEXT}.</p>
      </Section>

      <Section
        id="type"
        title="Typography"
        intro="Plus Jakarta Sans, a variable font with a friendly geometric shape. It is open licence and exists for web and Flutter, so every tier can use the same face. It replaces Bevellier, whose licence we could not confirm."
      >
        <div className="space-y-5 rounded-lg bg-surface p-8 shadow-soft">
          <p className="text-5xl font-extrabold tracking-tight">Page headline, 48 extra bold</p>
          <p className="text-3xl font-bold tracking-tight">Section title, 30 bold</p>
          <p className="text-xl font-bold">Card title, 20 bold</p>
          <p className="text-base">Body text, 16 regular. Where the buses stop and who boards them.</p>
          <p className="text-sm text-muted">Secondary text, 14 regular, muted. Used for hints and descriptions.</p>
          <p className="text-xs font-semibold tracking-wide text-muted uppercase">Label, 12 semibold, spaced</p>
        </div>
        <p className="mt-4 text-sm text-muted">
          Headlines are larger than before and sit tight; body copy keeps a line height of 1.5. Use weight, not size,
          to separate neighbours.
        </p>
      </Section>

      <Section
        id="shape"
        title="Shape"
        intro="Rounded beyond normal, never a pill and never a squircle. Five sizes on a 4px grid: xs for chips and small tags, sm for buttons and fields, md, lg for cards and xl for large surfaces. When one shape sits inside another, the inner radius is the outer radius minus the padding between them, so the corners stay concentric."
      >
        <div className="grid gap-4 sm:grid-cols-5">
          {(Object.entries(RADIUS) as [string, number][]).map(([name, px]) => (
            <div key={name} className="flex flex-col items-start gap-2">
              <div className="h-24 w-full bg-surface-2" style={{ borderRadius: px }} />
              <p className="text-sm font-semibold">
                {name} <span className="font-normal text-muted">{px}px</span>
              </p>
            </div>
          ))}
        </div>
        <div className="mt-8 flex flex-wrap items-center gap-8">
          <div className="bg-surface-2 p-4 shadow-soft" style={{ borderRadius: RADIUS.lg }}>
            <div className="h-24 w-40 bg-accent" style={{ borderRadius: innerRadius(RADIUS.lg, 16) }} />
          </div>
          <p className="max-w-sm text-sm text-muted">
            Outer {RADIUS.lg}px, padding 16px, inner {innerRadius(RADIUS.lg, 16)}px. Use innerRadius() from
            lib/ui/radius so nobody has to do the sum by hand.
          </p>
        </div>
      </Section>

      <Section
        id="contour"
        title="Contour"
        intro="A thin rounded stroke drawn inside a container, 16px in on cards, 6px in on the navigation bar, 4px in on buttons. It is drawn as a stitched thread, not a solid line: round-capped dashes. On buttons, links and empty states the thread slides forward when you hover or focus and back when you leave; on cards it stays still. Its colour never changes: it is the element's own colour, mixed toward its text. It is the quiet signature that makes BusIn surfaces recognisable. Empty states use the thread on its own, without a card."
      >
        <div className="grid gap-4 sm:grid-cols-2">
          <Card>
            <h3 className="text-lg font-bold">A card</h3>
            <p className="mt-2 text-sm text-muted">Corner 28, thread 16 in, so the thread corner is 12. It stays still, since a card is not interactive.</p>
          </Card>
          <EmptyState title="Nothing to review right now" body="An empty state has no card. The thread frames the message, and slides when you hover it." />
        </div>
      </Section>

      <Section
        id="texture"
        title="Texture"
        intro="A little roughness keeps the interface from feeling sterile. Grain and rough edges are decoration: they live on banners, feature cards and backdrops, never behind tables, forms or small text."
      >
        <h3 className="mb-3 text-lg font-bold">Grain</h3>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {[
            ["Fine on surface", "texture-grain bg-surface-2 text-fg [--grain:1]"],
            ["Fine on accent", "texture-grain bg-accent text-on-accent [--grain:0.8]"],
            ["Coarse on brand", "texture-grain-coarse bg-seed text-white [--grain:0.9]"],
            ["Coarse on teal", "texture-grain-coarse bg-teal-800 text-white [--grain:1]"],
          ].map(([label, classes]) => (
            <div key={label} className={`flex h-36 items-end rounded-lg p-4 text-sm font-semibold ${classes}`}>
              {label}
            </div>
          ))}
        </div>
        <p className="mt-3 max-w-2xl text-sm text-muted">
          Two strengths of noise, drawn by an inline SVG filter, so there is no image to download and it stays sharp at
          any size. Set the strength with --grain (about 0.5 to 1, with soft-light blending, which is gentle on light colours). It sits above the
          background and below the content, does not animate, and is hidden in high contrast mode.
        </p>

        <h3 className="mt-8 mb-3 text-lg font-bold">Rough edge</h3>
        <div className="flex flex-wrap items-center gap-6">
          <div className="texture-rough h-24 w-44 rounded-lg bg-accent" aria-hidden />
          <div className="texture-rough h-24 w-44 rounded-lg bg-teal-800" aria-hidden />
          <p className="relative max-w-xs text-2xl font-extrabold tracking-tight">
            A marker
            <span aria-hidden className="texture-rough absolute inset-x-[-0.2em] bottom-[0.05em] -z-10 h-[0.45em] rounded-xs bg-accent/60" />
            <span className="relative"> highlight</span>
          </p>
        </div>
        <p className="mt-3 max-w-2xl text-sm text-muted">
          The outline wobbles like cut paper or a marker stroke. Use it on a decorative shape behind or beside text,
          never on the text itself, and render the filter once per page.
        </p>

        <h3 className="mt-8 mb-3 text-lg font-bold">In use</h3>
        <ul className="m-0 grid list-none gap-2 p-0 text-sm sm:grid-cols-2">
          {[
            "Page banners and the first card of a page: fine grain.",
            "Large empty-state backdrops and illustrations: coarse grain, kept faint.",
            "Never on tables, forms, buttons or anything under about 18px of text.",
            "Check contrast with the grain on; the strength may never lower it below WCAG AA.",
          ].map((line) => (
            <li key={line} className="rounded-md bg-surface-2 p-4">
              {line}
            </li>
          ))}
        </ul>
      </Section>

      <Section
        id="icons"
        title="Icons"
        intro="Hugeicons, stroke rounded, free set, drawn at 1.8 stroke. Always through the Icon component so size and stroke stay uniform. Icons come with a label unless the meaning is universal."
      >
        <div className="grid grid-cols-3 gap-3 sm:grid-cols-5 lg:grid-cols-9">
          {NAV_ICONS.map(([label, icon]) => (
            <div key={label} className="flex flex-col items-center gap-2 rounded-md bg-surface p-4 shadow-soft">
              <Icon icon={icon} size={24} />
              <span className="text-xs font-semibold text-muted">{label}</span>
            </div>
          ))}
        </div>
      </Section>

      <Section
        id="navigation"
        title="Navigation"
        intro="One floating bar at the bottom of every page, in place of a sidebar. It never hides on scroll and never changes between pages, so it is always where the thumb expects it."
      >
        <ul className="m-0 grid list-none gap-2 p-0 text-sm sm:grid-cols-2">
          {[
            "Glass: a translucent surface with a blur, so content shows softly behind it.",
            "Tabs are icon above label. The current page is tinted; the others sit on the bar with no background of their own.",
            "The logo and the profile picture sit at the ends and take no label. Theme, language and sign out live on the profile page.",
            "On wide screens every tab shows. On tablets in portrait and on phones the bar shows the current page and a Menu button that opens the tabs upward, grouped.",
            "The bar slides in from below when the dashboard loads, once, after the logo intro. It does not replay between pages.",
            "A page can fill the space above the tabs (the dock). The bar grows upward and the tabs stay in place.",
            "A small accent count sits on a tab's icon when something waits there: subscription requests to review, students to verify. Above nine it reads 9+. On small screens the Menu button shows the total. The exact number is the tab's description for assistive technology, so its name stays the page's name.",
          ].map((line) => (
            <li key={line} className="rounded-md bg-surface-2 p-4">
              {line}
            </li>
          ))}
        </ul>
        <p className="mt-4 text-sm text-muted">The bar is not drawn on this page, so the documentation stays uncluttered. Open any portal page to see it.</p>
        <h3 className="mt-8 mb-3 text-lg font-bold">Page header and help</h3>
        <p className="max-w-2xl text-sm text-muted">
          Every page starts with a large headline. A help button beside it opens a side sheet with worked examples from
          real days, so a new administrator learns the page by reading situations, not instructions. See the Overview
          page for the first one.
        </p>
      </Section>

      <Section
        id="motion"
        title="Motion"
        intro="Motion is gentle and short. GSAP drives the larger moves (navigation bar reveal, side sheet, logo draw, later the tab indicator); simple state changes use CSS. All of it stops when the device asks for reduced motion."
      >
        <div className="grid gap-3 sm:grid-cols-3">
          {[
            ["Fast", "160ms", "Hover and press feedback"],
            ["Standard", "280ms", "Menus, sheets, tab changes"],
            ["Slow", "520ms", "Page-level entrances, the logo fill"],
          ].map(([name, ms, use]) => (
            <div key={name} className="rounded-md bg-surface p-5 shadow-soft">
              <p className="text-2xl font-bold">{ms}</p>
              <p className="text-sm font-semibold">{name}</p>
              <p className="mt-1 text-sm text-muted">{use}</p>
            </div>
          ))}
        </div>
        <p className="mt-4 text-sm text-muted">
          Easing is a soft ease-out (0.22, 1, 0.36, 1) everywhere. Loading uses shimmers shaped like the content they
          stand in for, never a spinner on its own.
        </p>
        <div className="mt-4 space-y-3 rounded-lg bg-surface p-6 shadow-soft" aria-label="Shimmer example">
          <Skeleton className="h-6 w-1/3" />
          <Skeleton className="h-4 w-full" />
          <Skeleton className="h-4 w-2/3" />
        </div>
      </Section>

      <Section
        id="imagery"
        title="Imagery"
        intro="Illustration only where it carries meaning, such as an empty state or a first-run message. It is never decoration. Keep every image that is already in the app."
      >
        <h3 className="mb-3 text-lg font-bold">3D objects</h3>
        <p className="mb-4 max-w-2xl text-sm text-muted">
          From thiings.co, free to use. They sit on the page background with no frame, at 96 to 160px, and are never
          used as wallpaper. Stored as WebP at 480px.
        </p>
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-5">
          {THREE_D.map(([file, label]) => (
            <div key={file} className="flex flex-col items-center gap-2 rounded-lg bg-surface p-4 shadow-soft">
              <Image src={`/illustrations/${file}.webp`} alt="" width={96} height={96} className="h-24 w-24" />
              <span className="text-xs font-semibold text-muted">{label}</span>
            </div>
          ))}
        </div>

        <h3 className="mt-8 mb-3 text-lg font-bold">Photographs</h3>
        <p className="mb-4 max-w-2xl text-sm text-muted">
          From Pexels, free to use without credit. Real transport scenes in warm light. Large corners (36px), WebP,
          about 100 to 170 KB, always with alt text.
        </p>
        <div className="grid auto-rows-[10rem] grid-flow-dense grid-cols-2 gap-3 sm:auto-rows-[10.5rem] sm:grid-cols-6">
          {BENTO.map((photo) => (
            <figure key={photo.file} className={`group relative m-0 overflow-hidden rounded-lg bg-surface-2 ${photo.tile}`}>
              <Image
                src={`/styleguide/photos/${photo.file}.webp`}
                alt={photo.alt}
                fill
                sizes="(min-width: 640px) 33vw, 50vw"
                className="object-cover transition-transform duration-(--dur-slow) ease-soft group-hover:scale-[1.04] motion-reduce:transition-none"
                style={{ objectPosition: photo.focus }}
              />
              <figcaption className="absolute bottom-3 left-3 rounded-xs bg-glass px-2.5 py-1 text-xs font-semibold backdrop-blur-[10px]">
                Pexels {photo.id}
              </figcaption>
            </figure>
          ))}
        </div>

        <h3 className="mt-8 mb-3 text-lg font-bold">In context</h3>
        <EmptyState
          title="No trips scheduled yet"
          body="Schedule the first run of the day and it will show up here."
          illustration="/illustrations/bus.webp"
        />
      </Section>

      <Section id="components" title="Components" intro="Each component is shown in its states. New components are added here first.">
        <h3 className="mb-3 text-lg font-bold">Buttons</h3>
        <div className="flex flex-wrap items-center gap-3">
          <Button>Save stop</Button>
          <Button variant="secondary">Cancel</Button>
          <Button variant="ghost">Skip</Button>
          <Button variant="danger">Suspend</Button>
          <Button icon={Search01Icon}>With icon</Button>
          <Button disabled>Disabled</Button>
          <ButtonLink href="/styleguide" variant="secondary" icon={ArrowLeft01Icon}>
            As a link
          </ButtonLink>
        </div>

        <h3 className="mt-8 mb-3 text-lg font-bold">Chips</h3>
        <div className="flex flex-wrap gap-2">
          <Chip>Neutral</Chip>
          <Chip tone="accent">Accent</Chip>
          <Chip tone="ok">Approved</Chip>
          <Chip tone="warn">Pending</Chip>
          <Chip tone="bad">Rejected</Chip>
          <Chip tone="info">Running</Chip>
        </div>

        <h3 className="mt-8 mb-3 text-lg font-bold">Fields</h3>
        <div className="grid max-w-3xl gap-4 sm:grid-cols-2">
          <Input id="sg-search" label="Search" icon={Search01Icon} placeholder="Name, email or matricule" />
          <Input id="sg-email" label="Email" icon={Mail01Icon} type="email" hint="We never share it." />
          <Input id="sg-error" label="Plate" icon={Bus01Icon} defaultValue="LT 123" error="That plate is already used." />
        </div>
        <div className="mt-4 max-w-3xl">
          <DomainsTagInput
            id="sg-tags"
            name="sg-tags"
            label="Allowed email domains"
            hint="Type a domain and press comma, space or Enter. Click a tag to edit it."
            placeholder="gmail.com, yahoo.fr"
            defaultValue={["gmail.com", "yahoo.fr"]}
            invalidHint="One of these is not a valid domain. Click it to edit it."
            removeLabel="Remove"
          />
        </div>
        <p className="mt-3 max-w-2xl text-sm text-muted">
          Tags: a comma, a space or Enter turns the text into a tag; each tag has a remove button, and clicking it puts it
          back in the field to edit. Backspace in the empty field edits the last tag. A tag that breaks the rule is shown
          in the error colour. The tags are sent with the form as one comma-separated field.
        </p>

        <h3 className="mt-8 mb-3 text-lg font-bold">Dropdown, date and time</h3>
        <div className="grid max-w-3xl gap-4 sm:grid-cols-2">
          <Select
            id="sg-bus"
            label="Bus"
            icon={Bus01Icon}
            placeholder="Choose a bus"
            options={[
              { value: "1", label: "LT 123 AB" },
              { value: "2", label: "LT 456 CD" },
              { value: "3", label: "LT 789 EF (out of service)", disabled: true },
            ]}
          />
          <Select
            id="sg-dir"
            label="Direction"
            icon={Navigation03Icon}
            hint="Going to school or going home."
            defaultValue="in"
            options={[
              { value: "in", label: "Going to school" },
              { value: "out", label: "Going home" },
            ]}
          />
          <DatePicker id="sg-date" label="First day" defaultValue="2026-09-07" />
          <TimePicker id="sg-time" label="Departure" defaultValue="07:30" />
          <DateTimePicker id="sg-dt" name="start" label="Start time" hint="Local time of the school." className="sm:col-span-2" />
        </div>
        <p className="mt-3 max-w-2xl text-sm text-muted">
          All three are drawn in the design system, not by the browser, so they match everything else. Each opens up or
          down, whichever has room, and sits above sheets and modals. Keyboard: arrows move, Home and End jump, Enter
          picks, Escape closes; in the calendar Page Up and Page Down change the month; in the dropdown, typing jumps
          to a match. Each sends its value with the form.
        </p>

        <h3 className="mt-8 mb-3 text-lg font-bold">Checkbox, radio and switch</h3>
        <div className="grid max-w-3xl gap-6 sm:grid-cols-3">
          <div className="flex flex-col gap-4">
            <Checkbox label="Send a receipt" hint="By email." defaultChecked />
            <Checkbox label="Remember me" />
            <Checkbox label="Not available" disabled />
          </div>
          <RadioGroup
            legend="Payment"
            name="sg-pay"
            defaultValue="mobile"
            options={[
              { value: "mobile", label: "Mobile money" },
              { value: "cash", label: "Cash at the office" },
              { value: "other", label: "Not available", disabled: true },
            ]}
          />
          <div className="flex flex-col gap-4">
            <Switch label="Active" hint="Offered to students." defaultChecked />
            <Switch label="In service" />
            <Switch label="Not available" disabled />
          </div>
        </div>

        <h3 id="tabs" className="mt-8 mb-3 text-lg font-bold">
          Tabs with counters
        </h3>
        <TabsDemo />
        <p className="mt-3 max-w-2xl text-sm text-muted">
          Tabs are links, so each one is a real address and works without scripts. The current tab is raised, and the
          highlight slides to the next with an elastic stretch. Unselected tabs have no background. Counters take a tone:
          warn for work waiting, ok for done.
        </p>

        <h3 className="mt-8 mb-3 text-lg font-bold">Menu</h3>
        <MenuDemo />
        <p className="mt-4 mb-3 max-w-2xl text-sm text-muted">
          A menu can open below, above, to the left or to the right of its button. Whatever is asked, it moves to the side
          with room if it would run off the screen.
        </p>
        <MenuPlacementDemo />

        <h3 className="mt-8 mb-3 text-lg font-bold">Table</h3>
        <TableCard>
          <DataTable minWidth="34rem">
            <Head>
              <Th>Student</Th>
              <Th>Stop</Th>
              <Th>Submitted</Th>
              <Th>Status</Th>
            </Head>
            <tbody>
              {(
                [
                  ["Amina Tchoua", "Shell Nsimeyong", "Nov 4, 2026", "Pending", "warn"],
                  ["Joseph Mbarga", "Carrefour Vogt", "Nov 3, 2026", "Approved", "ok"],
                  ["Lea Fotso", "Shell Nsimeyong", "Nov 1, 2026", "Rejected", "bad"],
                ] as const
              ).map(([name, stop, date, status, tone]) => (
                <Tr key={name}>
                  <Td>
                    <div className="flex items-center gap-3">
                      <Avatar name={name} url={null} size={40} />
                      <span className="font-semibold">{name}</span>
                    </div>
                  </Td>
                  <Td>{stop}</Td>
                  <Td className="text-muted">{date}</Td>
                  <Td>
                    <Chip tone={tone}>{status}</Chip>
                  </Td>
                </Tr>
              ))}
            </tbody>
          </DataTable>
        </TableCard>
        <p className="mt-3 max-w-2xl text-sm text-muted">
          One set of pieces builds every list: TableCard (the raised, rounded surface that scrolls sideways on a narrow
          screen), DataTable, Head, Th, Tr and Td. They are real table elements, so screen readers get a real table.
          Headings are quiet uppercase, rows tint on hover, a person is an avatar and a name, a state is a chip with its
          label, and a name that leads somewhere is a link without an underline. Show only the columns that help; never
          coordinates or ids.
        </p>

        <h3 className="mt-8 mb-3 text-lg font-bold">Pagination</h3>
        <Pager
          range="Showing 21 to 40 of 87"
          label="Pages"
          previous={{ href: "#components", label: "Previous" }}
          next={{ href: "#components", label: "Next" }}
          perPage={{ label: "Per page", groupLabel: "Items per page", current: 20, options: [10, 20, 50, 100].map((size) => ({ size, href: "#components" })) }}
        />
        <p className="mt-3 max-w-2xl text-sm text-muted">
          Under every list that has more than one page: the range on the left, Previous and Next on the right. Each is a
          link to a real address, so the page can be bookmarked, and a button only appears when there is somewhere to go.
          A page past the last one is an empty list, never an error. Lists show 20 at a time by default; Per page offers
          10, 20, 50 or 100, kept in the address with the filters, and changing it goes back to the first page. Lists are
          paginated by the server, so a long list never loads more than one page (100 rows at most).
        </p>

        <h3 className="mt-8 mb-3 text-lg font-bold">Toasts</h3>
        <ToastDemo />
        <p className="mt-3 max-w-2xl text-sm text-muted">
          A short message that floats at the top and leaves by itself: the stitched thread, an icon for its state and a
          close button. The button is a rounded tile in a slightly deeper tint of the state, and a ring along its edge empties
          as the time runs out; there is no other stroke. It eases in over 460 ms, glides back up over 380 ms (a plain fade under reduced motion)
          and takes one at a time. Hovering it, or focusing it with the keyboard, pauses the clock and the ring; moving away carries on from where it stopped. Good news leaves quickly (2.8 s), a problem stays to be read (7 s). After a save, a
          page opens with its confirmation as a toast (FlashToast reads the done value in the address and then clears
          it). Use it for confirmations and reminders; an error the person must act on stays on the page, as a notice.
          The apps have the same component with the same times and ring (swipe up to dismiss).
        </p>

        <h3 className="mt-8 mb-3 text-lg font-bold">Notices</h3>
        <div className="flex max-w-2xl flex-col gap-3">
          <Notice tone="ok">Stop saved.</Notice>
          <Notice tone="bad">The stop could not be saved. Try again.</Notice>
          <Notice tone="warn">This bus is out of service.</Notice>
          <Notice tone="info">Distances are approximate.</Notice>
        </div>
        <p className="mt-3 max-w-2xl text-sm text-muted">
          A short message in a tone. Successes are announced politely (status), failures at once (alert). Say what
          happened, then what to do; the tone is never the only signal.
        </p>

        <h3 className="mt-8 mb-3 text-lg font-bold">Empty and loading states</h3>
        <div className="grid gap-6 lg:grid-cols-2">
          <EmptyState illustration="/illustrations/papers.webp" title="No subscriptions here" body="Try another tab." />
          <ListSkeleton rows={3} />
        </div>
        <p className="mt-3 max-w-2xl text-sm text-muted">
          An empty list says so with the thread around it and, where it helps, an illustration; it is not a card. While a
          list loads, a shimmer in the same shapes holds its place, so nothing jumps when the content arrives.
        </p>

        <h3 className="mt-8 mb-3 text-lg font-bold">Sticky toolbar</h3>
        <p className="max-w-2xl text-sm text-muted">
          The search and filters of a list stay in reach. Scrolled past, they stick to the top and realign into one
          compact glass row (search and tabs side by side, labels kept for screen readers) while the list moves behind;
          back at the top they glide to their roomy layout again. The change animates in both directions, is instant for
          people who prefer less motion, and the list below never jumps. On a narrow screen the compact bar keeps
          wrapping, because one row would not fit. Wrap a list&apos;s controls in StickyToolbar to get it; People,
          Subscriptions and Trips are the examples to open. When a toolbar is only tabs (Subscriptions,
          Trips) they stretch to fill the bar as it sticks, so the bar is as wide as the table.
        </p>

        <h3 className="mt-8 mb-3 text-lg font-bold">Column filters</h3>
        <div className="flex max-w-3xl flex-col gap-4">
          <FilterChips
            chips={[{ label: "Stop", value: "Poste Centrale", href: "#" }, { label: "Direction", value: "Going home", href: "#" }]}
            clearAllHref="#"
            clearAllLabel="Clear all"
            groupLabel="Active filters"
            removeLabel="Remove filter"
          />
          <TableCard>
            <DataTable minWidth="28rem">
              <Head>
                <Th>Student</Th>
                <Th>
                  <ColumnFilter
                    label="Stop"
                    value="a"
                    clearHref="#"
                    allLabel="All stops"
                    options={[
                      { value: "a", label: "Poste Centrale", href: "#" },
                      { value: "b", label: "Olezoa", href: "#" },
                    ]}
                    searchLabel="Search"
                    noMatchLabel="Nothing matches"
                    activeLabel="(filtered)"
                  />
                </Th>
                <Th>
                  <ColumnFilter
                    label="Direction"
                    value={null}
                    clearHref="#"
                    allLabel="Both directions"
                    options={[
                      { value: "in", label: "Going to school", href: "#" },
                      { value: "out", label: "Going home", href: "#" },
                    ]}
                    searchLabel="Search"
                    noMatchLabel="Nothing matches"
                    activeLabel="(filtered)"
                  />
                </Th>
              </Head>
              <tbody>
                <Tr>
                  <Td>Ada Lovelace</Td>
                  <Td>Poste Centrale</Td>
                  <Td className="text-muted">Going home</Td>
                </Tr>
              </tbody>
            </DataTable>
          </TableCard>
        </div>
        <p className="mt-3 max-w-2xl text-sm text-muted">
          A list is narrowed from its column headings: a small filter button after the name opens a panel of choices (a
          calendar for a date column), and a dot marks a heading that is filtered. Each filter lives in the
          page address, so a filtered list can be shared and survives a reload; picking a choice is a link, so it works
          with the keyboard and without scripts. Every active filter also shows as a chip above the table that removes
          it with one click, and the numbers on the tabs follow the filters. Long lists of choices (more than eight)
          get a search box. Use them where a column has a short set of values worth narrowing by; not every column needs one.
        </p>

        <h3 className="mt-8 mb-3 text-lg font-bold">Tooltip</h3>
        <div className="flex flex-wrap items-center gap-3">
          {(
            [
              ["Copy the link", Copy01Icon, "top"],
              ["Edit the stop", Edit02Icon, "right"],
              ["Delete the stop", Delete02Icon, "bottom"],
            ] as const
          ).map(([label, icon, side]) => (
            <button
              key={label}
              type="button"
              aria-label={label}
              data-tip={label}
              data-tip-side={side}
              className="inline-flex size-11 cursor-pointer items-center justify-center rounded-sm border-0 bg-surface-2 text-fg transition-colors duration-(--dur-fast) hover:bg-line focus-visible:outline-3 focus-visible:outline-focus"
            >
              <Icon icon={icon} size={20} />
            </button>
          ))}
        </div>
        <p className="mt-3 max-w-2xl text-sm text-muted">
          Any element with a data-tip attribute gets one, on hover after a short pause and on keyboard focus; data-tip-side
          picks the side, and it moves to the side with room. It is drawn by one layer for the whole page, so it also
          serves map markers, and it replaces the browser&apos;s own title tooltip. Icon buttons keep their aria-label:
          the tooltip is a hint, not the only name.
        </p>

        <h3 className="mt-8 mb-3 text-lg font-bold">Side sheet and modal</h3>
        <div className="flex flex-wrap items-start gap-3">
          <SheetDemo />
          <ModalDemo />
        </div>
        <p className="mt-3 max-w-2xl text-sm text-muted">
          Both float with a margin all round and rounded corners, never docked to an edge. Danger actions (delete,
          suspend, sign out) always use the danger style, and a destructive choice asks first.
        </p>

        <h3 className="mt-8 mb-3 text-lg font-bold">Card</h3>
        <div className="grid gap-4 sm:grid-cols-2">
          <Card>
            <p className="text-sm font-semibold text-muted">Subscriptions to review</p>
            <p className="mt-1 text-4xl font-extrabold">12</p>
          </Card>
        </div>
        <p className="mt-6 text-sm text-muted">
          Coming next: toast, table, pagination.</p>
      </Section>

      <Section id="rules" title="Never" intro="Rules that keep the system honest.">
        <ul className="m-0 grid list-none gap-2 p-0 text-sm sm:grid-cols-2">
          {[
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
          ].map((rule) => (
            <li key={rule} className="rounded-md bg-surface-2 p-4">
              {rule}
            </li>
          ))}
        </ul>
      </Section>
      </div>

      {/* The rail lives in the right margin, outside the content column, so it takes no reading space. */}
      <div className="absolute top-0 left-full hidden h-full pl-10 min-[94rem]:block">
        <SectionRail items={SECTIONS.map(([id, label]) => ({ id, label }))} />
      </div>
    </div>
  );
}

function Swatches({ names, light, dark }: { names: string[]; light: Record<string, string>; dark: Record<string, string> }) {
  return (
    <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
      {names.map((name) => (
        <div key={name} className="rounded-md bg-surface p-3 shadow-soft">
          <div className="h-14 rounded-xs border border-line" style={{ background: `var(--${name})` }} />
          <p className="mt-2 text-sm font-semibold">{name}</p>
          <p className="text-xs text-muted">
            {light[name]} / {dark[name]}
          </p>
        </div>
      ))}
    </div>
  );
}

function Ramp({ name }: { name: "teal" | "orange" }) {
  const steps = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900];
  return (
    <div className="mb-4 grid grid-cols-10 gap-1">
      {steps.map((step) => (
        <div key={step}>
          <div className="h-14 rounded-xs" style={{ background: `var(--color-${name}-${step})` }} />
          <p className="mt-1 text-center text-[11px] font-semibold text-muted">{step}</p>
        </div>
      ))}
    </div>
  );
}

function Ratio({ value }: { value: number }) {
  const passes = value >= AA_TEXT;
  return (
    <td className="px-4 py-3">
      <Chip tone={passes ? "ok" : "bad"}>
        {value.toFixed(1)} : 1 {passes ? "AA" : "fails"}
      </Chip>
    </td>
  );
}
