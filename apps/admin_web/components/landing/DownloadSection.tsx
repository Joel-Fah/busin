import { Bus01Icon, Download04Icon, Location01Icon, PlayStoreIcon, QrCodeIcon, Tick02Icon, UserGroupIcon } from "@hugeicons/core-free-icons";
import type { ReactNode } from "react";

import { ButtonLink } from "@/components/ui/Button";
import { Contour } from "@/components/ui/Contour";
import { Icon } from "@/components/ui/Icon";
import type { LandingCopy } from "@/lib/i18n/landing";
import type { Downloads } from "@/lib/landing/downloads";

import { DayScreen } from "./day/DayScreens";
import { Laptop, Phone, Tablet } from "./devices/Devices";
import { InterestButton } from "./interest/Interest";
import { Reveal } from "./motion/Reveal";

/** A card with its words on top and its devices rising from the bottom edge, cut off by it. */
function DeviceCard({ title, text, badge, actions, devices }: { title: string; text: string; badge?: string; actions: ReactNode; devices: ReactNode }) {
  return (
    <Reveal className="relative flex flex-col overflow-hidden rounded-xl bg-surface shadow-soft [--thread-color:var(--color-line)]">
      <Contour radius={36} inset={10} />
      <div className="relative flex flex-col gap-4 p-8 sm:p-10">
        <div className="flex flex-wrap items-center gap-3">
          <h3 className="m-0 text-3xl font-extrabold tracking-tight">{title}</h3>
          {badge ? <span className="whitespace-nowrap rounded-xs bg-warn-bg px-2.5 py-1 text-xs font-bold text-warn">{badge}</span> : null}
        </div>
        <p className="m-0 max-w-[30rem] text-pretty text-lg leading-relaxed text-muted">{text}</p>
        <div className="mt-2 flex flex-wrap gap-3">{actions}</div>
      </div>
      <div className="relative mt-auto h-[19rem] overflow-hidden sm:h-[22rem]">{devices}</div>
    </Reveal>
  );
}

/** The driver's view on a tablet: today's trip, its stops, and a big start button. Shapes and icons only. */
function TripScreen() {
  return (
    <div className="flex size-full gap-3 p-4">
      <div className="flex w-[42%] flex-col gap-2.5 rounded-md bg-surface p-3.5 shadow-soft">
        <span className="flex items-center gap-2 text-sm font-extrabold">
          <span className="grid size-7 place-items-center rounded-xs bg-accent text-on-accent">
            <Icon icon={Bus01Icon} size={15} />
          </span>
          Bus 2 · 7:10
        </span>
        {[0.9, 0.7, 0.8, 0.6].map((w, i) => (
          <span key={i} className="flex items-center gap-2">
            <span className={`size-2.5 shrink-0 rounded-full ${i === 0 ? "bg-ok" : "bg-line"}`} />
            <span className="h-2 rounded-xs bg-fg/12" style={{ width: `${w * 100}%` }} />
          </span>
        ))}
        <span className="mt-auto grid h-10 place-items-center rounded-sm bg-ok text-white">
          <Icon icon={Tick02Icon} size={18} />
        </span>
      </div>
      <div className="relative flex-1 overflow-hidden rounded-md bg-surface-2">
        <svg viewBox="0 0 200 160" className="absolute inset-0 size-full" preserveAspectRatio="xMidYMid slice">
          <path d="M-10 60H210M-10 120H210M70 -10V170M150 -10V170" className="stroke-line" strokeWidth="9" fill="none" />
          <path d="M20 140C60 130 70 90 110 80S170 40 185 20" fill="none" className="stroke-accent" strokeWidth="4" strokeLinecap="round" />
          <circle cx="110" cy="80" r="7" className="fill-accent stroke-surface" strokeWidth="3" />
        </svg>
        <span className="absolute bottom-3 left-3 flex items-center gap-1.5 rounded-xs bg-surface px-2 py-1 text-[11px] font-bold shadow-soft">
          <Icon icon={Location01Icon} size={12} />
          12 / 31
        </span>
      </div>
    </div>
  );
}

/** The school office's view on a laptop: a side menu, four numbers and the week's boardings. Shapes and icons only. */
function OfficeScreen() {
  const bars = [52, 70, 64, 88, 76, 40, 22];
  return (
    <div className="flex size-full">
      <div className="flex w-[18%] flex-col gap-2 bg-surface p-3">
        <span className="mb-2 h-3 w-10 rounded-xs bg-accent" />
        {[1, 0.7, 0.8, 0.6, 0.75].map((w, i) => (
          <span key={i} className={`h-2 rounded-xs ${i === 0 ? "bg-fg/40" : "bg-fg/12"}`} style={{ width: `${w * 100}%` }} />
        ))}
      </div>
      <div className="flex flex-1 flex-col gap-3 p-4">
        <div className="grid grid-cols-4 gap-2.5">
          {[
            { icon: UserGroupIcon, n: "312" },
            { icon: QrCodeIcon, n: "286" },
            { icon: Bus01Icon, n: "2" },
            { icon: Tick02Icon, n: "18" },
          ].map(({ icon, n }) => (
            <span key={n} className="flex flex-col gap-1 rounded-sm bg-surface p-2.5 shadow-soft">
              <Icon icon={icon} size={13} className="text-muted" />
              <span className="text-base font-extrabold tabular-nums">{n}</span>
            </span>
          ))}
        </div>
        <div className="flex flex-1 items-end gap-2.5 rounded-sm bg-surface p-3 shadow-soft">
          {bars.map((h, i) => (
            <span key={i} className={`flex-1 rounded-t-[4px] ${i === 3 ? "bg-accent" : "bg-teal-700/45 dark:bg-teal-500/40"}`} style={{ height: `${h}%` }} />
          ))}
        </div>
      </div>
    </div>
  );
}

/**
 * Get BusIn: the student app (Android and iPhone, one Get notified until a store link is set) and the tools for the
 * school team, each card with its devices. Where the team's tools come from is deliberately not said.
 */
export function DownloadSection({ copy, day, links }: { copy: LandingCopy["download"]; day: LandingCopy["day"]; links: Downloads }) {
  const s = copy.students;
  const any = links.play || links.apk || links.ios;
  return (
    <div className="mt-14 grid gap-5 lg:grid-cols-2">
      <DeviceCard
        title={s.title}
        text={s.text}
        badge={any ? undefined : s.soon}
        actions={
          <>
            {links.play ? (
              <ButtonLink href={links.play} icon={PlayStoreIcon}>
                {s.play}
              </ButtonLink>
            ) : null}
            {links.apk ? (
              <ButtonLink href={links.apk} icon={Download04Icon} variant={links.play ? "secondary" : "primary"}>
                {s.apk}
              </ButtonLink>
            ) : null}
            {links.ios ? (
              <ButtonLink href={links.ios} icon={Download04Icon} variant={links.play || links.apk ? "secondary" : "primary"}>
                {s.ios}
              </ButtonLink>
            ) : null}
            {any ? null : <InterestButton kind="notify">{s.notify}</InterestButton>}
          </>
        }
        devices={
          <div className="absolute inset-x-0 top-6 flex justify-center">
            <Phone kind="android" time="7:05" className="w-[14rem] -rotate-3 sm:w-[15rem]">
              <DayScreen index={1} copy={day} />
            </Phone>
            <Phone kind="iphone" time="7:22" className="relative z-10 -ml-9 mt-12 hidden w-[15rem] rotate-3 sm:block">
              <DayScreen index={2} copy={day} />
            </Phone>
          </div>
        }
      />
      <DeviceCard
        title={copy.team.title}
        text={copy.team.text}
        actions={
          <InterestButton kind="school" variant="secondary">
            {copy.team.cta}
          </InterestButton>
        }
        devices={
          <div className="absolute inset-x-0 top-8 flex justify-center">
            <Laptop className="w-[34rem] translate-x-[14%] sm:w-[38rem]">
              <OfficeScreen />
            </Laptop>
            <div className="absolute left-[3%] top-28 sm:left-[5%] sm:top-32">
              <Tablet className="w-[16rem] -rotate-2 sm:w-[19rem]">
                <TripScreen />
              </Tablet>
            </div>
          </div>
        }
      />
    </div>
  );
}
