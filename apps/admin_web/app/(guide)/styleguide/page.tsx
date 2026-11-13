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
import {
  AUDIENCE,
  COLOUR_STATE_NOTE,
  COMPONENT_NOTES,
  GRAIN_NOTE,
  GUIDE,
  ILLUSTRATION_NOTE,
  LOGO_MOTION,
  MOTION_NOTE,
  MOTION_STEPS,
  NAV_HELP,
  NAV_RULES,
  NEVER,
  PHOTO_NOTE,
  PRINCIPLES,
  ROUGH_NOTE,
  SECTIONS,
  TEXTURE_USE,
  THREE_D,
  TYPE_NOTE,
  VOICE_PAIRS,
  VOICE_RULES,
  section,
  type SectionId,
} from "@/lib/styleguide/content";

import { MenuDemo, MenuPlacementDemo, ModalDemo, SheetDemo, TabsDemo, ToastDemo } from "./Demos";
import { ExportLinks } from "./ExportLinks";
import { Pair, Section } from "./Section";
import { SectionRail } from "./SectionRail";

export const metadata: Metadata = { title: "Styleguide" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

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
          <p className="text-sm font-semibold text-white/80">{GUIDE.name}</p>
          <h1 className="text-5xl font-extrabold tracking-tight sm:text-6xl">{GUIDE.title}</h1>
          <p className="max-w-lg text-base text-white/85">{GUIDE.summary}</p>
        </div>
      </header>

      <div className="mt-6 flex flex-wrap items-center justify-between gap-4">
        <p className="max-w-xl text-sm text-muted">{GUIDE.upkeep}</p>
        <div className="flex flex-wrap items-center gap-3">
          <ExportLinks />
          <ThemeToggle labels={{ group: "Theme", system: "System", light: "Light", dark: "Dark" }} />
        </div>
      </div>

      <nav aria-label="Jump to a section" className="mt-6 flex flex-wrap gap-x-5 gap-y-2 min-[94rem]:hidden">
        {SECTIONS.map(({ id, title }) => (
          <a key={id} href={`#${id}`} className="text-sm font-semibold text-muted no-underline hover:text-fg">
            {title}
          </a>
        ))}
      </nav>

      <div className="mt-4">
      <Section {...sectionProps("overview")}>
        <div className="grid gap-4 sm:grid-cols-3">
          {PRINCIPLES.map(([title, body]) => (
            <Card key={title} className="p-7">
              <h3 className="text-lg font-bold">{title}</h3>
              <p className="mt-2 text-sm text-muted">{body}</p>
            </Card>
          ))}
        </div>
        <p className="mt-6 max-w-2xl text-sm text-muted">{AUDIENCE}</p>
      </Section>

      <Section {...sectionProps("voice")}>
        <ul className="m-0 grid list-none gap-2 p-0 text-sm sm:grid-cols-2">
          {VOICE_RULES.map((line) => (
            <li key={line} className="rounded-md bg-surface-2 p-4">
              {line}
            </li>
          ))}
        </ul>
        <div className="mt-6 space-y-3">
          {VOICE_PAIRS.map((pair) => (
            <Pair key={pair.do} doText={pair.do} dontText={pair.dont} />
          ))}
        </div>
      </Section>

      <Section {...sectionProps("logo")}>
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
        <p className="mt-4 text-sm text-muted">{LOGO_MOTION}</p>
      </Section>

      <Section {...sectionProps("colour")}>
        <h3 className="mb-3 text-lg font-bold">Surface and text tokens</h3>
        <Swatches names={SURFACE_TOKENS} light={light} dark={dark} />
        <h3 className="mt-8 mb-3 text-lg font-bold">State tokens</h3>
        <p className="mb-3 text-sm text-muted">{COLOUR_STATE_NOTE}</p>
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

      <Section {...sectionProps("type")}>
        <div className="space-y-5 rounded-lg bg-surface p-8 shadow-soft">
          <p className="text-5xl font-extrabold tracking-tight">Page headline, 48 extra bold</p>
          <p className="text-3xl font-bold tracking-tight">Section title, 30 bold</p>
          <p className="text-xl font-bold">Card title, 20 bold</p>
          <p className="text-base">Body text, 16 regular. Where the buses stop and who boards them.</p>
          <p className="text-sm text-muted">Secondary text, 14 regular, muted. Used for hints and descriptions.</p>
          <p className="text-xs font-semibold tracking-wide text-muted uppercase">Label, 12 semibold, spaced</p>
        </div>
        <p className="mt-4 text-sm text-muted">{TYPE_NOTE}</p>
      </Section>

      <Section {...sectionProps("shape")}>
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

      <Section {...sectionProps("contour")}>
        <div className="grid gap-4 sm:grid-cols-2">
          <Card>
            <h3 className="text-lg font-bold">A card</h3>
            <p className="mt-2 text-sm text-muted">Corner 28, thread 16 in, so the thread corner is 12. It stays still, since a card is not interactive.</p>
          </Card>
          <EmptyState title="Nothing to review right now" body="An empty state has no card. The thread frames the message, and slides when you hover it." />
        </div>
      </Section>

      <Section {...sectionProps("texture")}>
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
        <p className="mt-3 max-w-2xl text-sm text-muted">{GRAIN_NOTE}</p>

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
        <p className="mt-3 max-w-2xl text-sm text-muted">{ROUGH_NOTE}</p>

        <h3 className="mt-8 mb-3 text-lg font-bold">In use</h3>
        <ul className="m-0 grid list-none gap-2 p-0 text-sm sm:grid-cols-2">
          {TEXTURE_USE.map((line) => (
            <li key={line} className="rounded-md bg-surface-2 p-4">
              {line}
            </li>
          ))}
        </ul>
      </Section>

      <Section {...sectionProps("icons")}>
        <div className="grid grid-cols-3 gap-3 sm:grid-cols-5 lg:grid-cols-9">
          {NAV_ICONS.map(([label, icon]) => (
            <div key={label} className="flex flex-col items-center gap-2 rounded-md bg-surface p-4 shadow-soft">
              <Icon icon={icon} size={24} />
              <span className="text-xs font-semibold text-muted">{label}</span>
            </div>
          ))}
        </div>
      </Section>

      <Section {...sectionProps("navigation")}>
        <ul className="m-0 grid list-none gap-2 p-0 text-sm sm:grid-cols-2">
          {NAV_RULES.map((line) => (
            <li key={line} className="rounded-md bg-surface-2 p-4">
              {line}
            </li>
          ))}
        </ul>
        <p className="mt-4 text-sm text-muted">The bar is not drawn on this page, so the documentation stays uncluttered. Open any portal page to see it.</p>
        <h3 className="mt-8 mb-3 text-lg font-bold">Page header and help</h3>
        <p className="max-w-2xl text-sm text-muted">{NAV_HELP}</p>
      </Section>

      <Section {...sectionProps("motion")}>
        <div className="grid gap-3 sm:grid-cols-3">
          {MOTION_STEPS.map(({ name, ms, use }) => (
            <div key={name} className="rounded-md bg-surface p-5 shadow-soft">
              <p className="text-2xl font-bold">{ms}ms</p>
              <p className="text-sm font-semibold">{name}</p>
              <p className="mt-1 text-sm text-muted">{use}</p>
            </div>
          ))}
        </div>
        <p className="mt-4 text-sm text-muted">{MOTION_NOTE}</p>
        <div className="mt-4 space-y-3 rounded-lg bg-surface p-6 shadow-soft" aria-label="Shimmer example">
          <Skeleton className="h-6 w-1/3" />
          <Skeleton className="h-4 w-full" />
          <Skeleton className="h-4 w-2/3" />
        </div>
      </Section>

      <Section {...sectionProps("imagery")}>
        <h3 className="mb-3 text-lg font-bold">3D objects</h3>
        <p className="mb-4 max-w-2xl text-sm text-muted">{ILLUSTRATION_NOTE}</p>
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-5">
          {THREE_D.map(([file, label]) => (
            <div key={file} className="flex flex-col items-center gap-2 rounded-lg bg-surface p-4 shadow-soft">
              <Image src={`/illustrations/${file}.webp`} alt="" width={96} height={96} className="h-24 w-24" />
              <span className="text-xs font-semibold text-muted">{label}</span>
            </div>
          ))}
        </div>

        <h3 className="mt-8 mb-3 text-lg font-bold">Photographs</h3>
        <p className="mb-4 max-w-2xl text-sm text-muted">{PHOTO_NOTE}</p>
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

      <Section {...sectionProps("components")}>
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
        <p className="mt-3 max-w-2xl text-sm text-muted">{note("Buttons")}</p>

        <h3 className="mt-8 mb-3 text-lg font-bold">Chips</h3>
        <div className="flex flex-wrap gap-2">
          <Chip>Neutral</Chip>
          <Chip tone="accent">Accent</Chip>
          <Chip tone="ok">Approved</Chip>
          <Chip tone="warn">Pending</Chip>
          <Chip tone="bad">Rejected</Chip>
          <Chip tone="info">Running</Chip>
        </div>
        <p className="mt-3 max-w-2xl text-sm text-muted">{note("Chips")}</p>

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
        <p className="mt-3 max-w-2xl text-sm text-muted">{note("Tags")}</p>

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
        <p className="mt-3 max-w-2xl text-sm text-muted">{note("Dropdown, date and time")}</p>

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
        <p className="mt-3 max-w-2xl text-sm text-muted">{note("Checkbox, radio and switch")}</p>

        <h3 id="tabs" className="mt-8 mb-3 text-lg font-bold">
          Tabs with counters
        </h3>
        <TabsDemo />
        <p className="mt-3 max-w-2xl text-sm text-muted">{note("Tabs with counters")}</p>

        <h3 className="mt-8 mb-3 text-lg font-bold">Menu</h3>
        <MenuDemo />
        <p className="mt-4 mb-3 max-w-2xl text-sm text-muted">{note("Menu")}</p>
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
        <p className="mt-3 max-w-2xl text-sm text-muted">{note("Table")}</p>

        <h3 className="mt-8 mb-3 text-lg font-bold">Pagination</h3>
        <Pager
          range="Showing 21 to 40 of 87"
          label="Pages"
          previous={{ href: "#components", label: "Previous" }}
          next={{ href: "#components", label: "Next" }}
          perPage={{ label: "Per page", groupLabel: "Items per page", current: 20, options: [10, 20, 50, 100].map((size) => ({ size, href: "#components" })) }}
        />
        <p className="mt-3 max-w-2xl text-sm text-muted">{note("Pagination")}</p>

        <h3 className="mt-8 mb-3 text-lg font-bold">Toasts</h3>
        <ToastDemo />
        <p className="mt-3 max-w-2xl text-sm text-muted">{note("Toasts")}</p>

        <h3 className="mt-8 mb-3 text-lg font-bold">Notices</h3>
        <div className="flex max-w-2xl flex-col gap-3">
          <Notice tone="ok">Stop saved.</Notice>
          <Notice tone="bad">The stop could not be saved. Try again.</Notice>
          <Notice tone="warn">This bus is out of service.</Notice>
          <Notice tone="info">Distances are approximate.</Notice>
        </div>
        <p className="mt-3 max-w-2xl text-sm text-muted">{note("Notices")}</p>

        <h3 className="mt-8 mb-3 text-lg font-bold">Empty and loading states</h3>
        <div className="grid gap-6 lg:grid-cols-2">
          <EmptyState illustration="/illustrations/papers.webp" title="No subscriptions here" body="Try another tab." />
          <ListSkeleton rows={3} />
        </div>
        <p className="mt-3 max-w-2xl text-sm text-muted">{note("Empty and loading states")}</p>

        <h3 className="mt-8 mb-3 text-lg font-bold">Sticky toolbar</h3>
        <p className="max-w-2xl text-sm text-muted">{note("Sticky toolbar")}</p>

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
        <p className="mt-3 max-w-2xl text-sm text-muted">{note("Column filters")}</p>

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
        <p className="mt-3 max-w-2xl text-sm text-muted">{note("Tooltip")}</p>

        <h3 className="mt-8 mb-3 text-lg font-bold">Side sheet and modal</h3>
        <div className="flex flex-wrap items-start gap-3">
          <SheetDemo />
          <ModalDemo />
        </div>
        <p className="mt-3 max-w-2xl text-sm text-muted">{note("Side sheet and modal")}</p>

        <h3 className="mt-8 mb-3 text-lg font-bold">Card</h3>
        <div className="grid gap-4 sm:grid-cols-2">
          <Card>
            <p className="text-sm font-semibold text-muted">Subscriptions to review</p>
            <p className="mt-1 text-4xl font-extrabold">12</p>
          </Card>
        </div>
        <p className="mt-4 max-w-2xl text-sm text-muted">{note("Card")}</p>
      </Section>

      <Section {...sectionProps("rules")}>
        <ul className="m-0 grid list-none gap-2 p-0 text-sm sm:grid-cols-2">
          {NEVER.map((rule) => (
            <li key={rule} className="rounded-md bg-surface-2 p-4">
              {rule}
            </li>
          ))}
        </ul>
      </Section>
      </div>

      {/* The rail lives in the right margin, outside the content column, so it takes no reading space. */}
      <div className="absolute top-0 left-full hidden h-full pl-10 min-[94rem]:block">
        <SectionRail items={SECTIONS.map(({ id, title }) => ({ id, label: title }))} />
      </div>
    </div>
  );
}

/** A section's id, title and intro, from the shared content. */
function sectionProps(id: SectionId) {
  const { title, intro } = section(id);
  return { id, title, intro };
}

/** A component's note, from the shared content. */
function note(name: string): string {
  return COMPONENT_NOTES.find((n) => n.name === name)?.note ?? "";
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
