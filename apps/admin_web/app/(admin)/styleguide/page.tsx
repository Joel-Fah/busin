import type { Metadata } from "next";
import Image from "next/image";
import { Suspense } from "react";
import {
  ArrowLeft01Icon,
  Bus01Icon,
  Calendar02Icon,
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
import { Chip } from "@/components/ui/Chip";
import { Contour } from "@/components/ui/Contour";
import { EmptyState } from "@/components/ui/EmptyState";
import { Icon } from "@/components/ui/Icon";
import { Input } from "@/components/ui/Input";
import { Skeleton } from "@/components/ui/Skeleton";
import { ThemeToggle } from "@/components/ui/ThemeToggle";
import { requireAdmin } from "@/lib/auth";
import { AA_TEXT, contrastRatio } from "@/lib/ui/contrast";
import { RADIUS, innerRadius } from "@/lib/ui/radius";
import { TEXT_PAIRS, readColourTokens } from "@/lib/ui/tokens";

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
  ["icons", "Icons"],
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

const PHOTOS = [
  ["bus-street", "A yellow school bus turning a snowy street corner between tall buildings", "12564070"],
  ["bus-stop-sun", "A small yellow school bus driving down a sunlit city street under trees", "27662522"],
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
  const { light, dark } = readColourTokens();

  return (
    <div lang="en" className="mx-auto max-w-6xl px-6 pt-8 pb-40">
      <header className="relative isolate overflow-hidden rounded-xl bg-seed text-white">
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

      <nav aria-label="Jump to a section" className="mt-6 flex flex-wrap gap-x-5 gap-y-2 xl:hidden">
        {SECTIONS.map(([id, label]) => (
          <a key={id} href={`#${id}`} className="text-sm font-semibold text-muted no-underline hover:text-fg">
            {label}
          </a>
        ))}
      </nav>

      <div className="mt-4 xl:grid xl:grid-cols-[minmax(0,1fr)_11rem] xl:gap-12">
      <div>
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
        intro="A thin rounded stroke drawn inside a container, 16px in on cards and the navigation bar, 4px in on buttons. It is drawn as a stitched thread, not a solid line: round-capped dashes. On buttons, links and empty states the thread slides forward when you hover or focus and back when you leave; on cards it stays still. Its colour never changes: it is the element's own colour, mixed toward its text. It is the quiet signature that makes BusIn surfaces recognisable. Empty states use the thread on its own, without a card."
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
        id="motion"
        title="Motion"
        intro="Motion is gentle and short. GSAP drives the larger moves (navigation bar reveal, tab indicator, logo draw); simple state changes use CSS. All of it stops when the device asks for reduced motion."
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
              <Image src={`/styleguide/3d/${file}.webp`} alt="" width={96} height={96} className="h-24 w-24" />
              <span className="text-xs font-semibold text-muted">{label}</span>
            </div>
          ))}
        </div>

        <h3 className="mt-8 mb-3 text-lg font-bold">Photographs</h3>
        <p className="mb-4 max-w-2xl text-sm text-muted">
          From Pexels, free to use without credit. Real transport scenes in warm light. Large corners (36px), WebP,
          about 100 to 170 KB, always with alt text.
        </p>
        <div className="grid gap-4 sm:grid-cols-2">
          {PHOTOS.map(([file, alt, source]) => (
            <figure key={file} className="m-0">
              <Image
                src={`/styleguide/photos/${file}.webp`}
                alt={alt}
                width={800}
                height={534}
                sizes="(min-width: 640px) 50vw, 100vw"
                className="aspect-[3/2] h-auto w-full rounded-xl object-cover"
              />
              <figcaption className="mt-2 text-xs text-muted">Pexels photo {source}</figcaption>
            </figure>
          ))}
        </div>

        <h3 className="mt-8 mb-3 text-lg font-bold">In context</h3>
        <EmptyState
          title="No trips scheduled yet"
          body="Schedule the first run of the day and it will show up here."
          illustration="/styleguide/3d/bus.webp"
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

        <h3 className="mt-8 mb-3 text-lg font-bold">Card</h3>
        <div className="grid gap-4 sm:grid-cols-2">
          <Card>
            <p className="text-sm font-semibold text-muted">Subscriptions to review</p>
            <p className="mt-1 text-4xl font-extrabold">12</p>
          </Card>
        </div>
        <p className="mt-6 text-sm text-muted">
          Coming next, in this order: navigation bar, tabs with counters, side sheet, dropdown, date and time pickers,
          checkbox, radio, switch, modal, toast, table.
        </p>
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
