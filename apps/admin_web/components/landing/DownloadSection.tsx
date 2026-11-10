import { AndroidIcon, AppleIcon, Download04Icon, PlayStoreIcon, UserGroupIcon } from "@hugeicons/core-free-icons";
import type { IconSvgElement } from "@hugeicons/react";
import Image from "next/image";
import type { ReactNode } from "react";

import { ButtonLink } from "@/components/ui/Button";
import { Contour } from "@/components/ui/Contour";
import { Icon } from "@/components/ui/Icon";
import type { LandingCopy } from "@/lib/i18n/landing";
import type { Downloads } from "@/lib/landing/downloads";

import { InterestButton } from "./interest/Interest";
import { Reveal } from "./motion/Reveal";

function Platform({ icon, title, text, soon, children }: { icon: IconSvgElement; title: string; text: string; soon?: string; children: ReactNode }) {
  return (
    <Reveal className="relative flex flex-col gap-5 rounded-xl bg-surface p-8 shadow-soft [--thread-color:var(--color-line)]">
      <Contour radius={36} inset={10} />
      <div className="relative flex items-center gap-4">
        <span className="grid size-14 place-items-center rounded-md bg-surface-2">
          <Icon icon={icon} size={28} />
        </span>
        <div className="flex flex-col">
          <h3 className="m-0 text-2xl font-extrabold tracking-tight">{title}</h3>
          <p className="m-0 text-muted">{text}</p>
        </div>
        {soon ? <span className="ml-auto self-start whitespace-nowrap rounded-xs bg-warn-bg px-2.5 py-1 text-xs font-bold text-warn">{soon}</span> : null}
      </div>
      <div className="relative mt-auto flex flex-wrap gap-3">{children}</div>
    </Reveal>
  );
}

/**
 * Get BusIn: the student app for Android and iPhone, each with its store or file link when one is set, or "Get notified"
 * (the interest form) until then; and a word on where the staff app comes from.
 */
export function DownloadSection({ copy, links }: { copy: LandingCopy["download"]; links: Downloads }) {
  const android = links.play || links.apk;
  return (
    <div className="mt-14 grid gap-5 lg:grid-cols-[1fr_1fr_0.9fr]">
      <Platform icon={AndroidIcon} title={copy.android.title} text={copy.android.text} soon={android ? undefined : copy.android.soon}>
        {links.play ? (
          <ButtonLink href={links.play} icon={PlayStoreIcon}>
            {copy.android.play}
          </ButtonLink>
        ) : null}
        {links.apk ? (
          <ButtonLink href={links.apk} icon={Download04Icon} variant={links.play ? "secondary" : "primary"}>
            {copy.android.apk}
          </ButtonLink>
        ) : null}
        {android ? null : <InterestButton kind="notify_android">{copy.android.notify}</InterestButton>}
      </Platform>
      <Platform icon={AppleIcon} title={copy.ios.title} text={copy.ios.text} soon={links.ios ? undefined : copy.ios.soon}>
        {links.ios ? (
          <ButtonLink href={links.ios} icon={Download04Icon}>
            {copy.ios.store}
          </ButtonLink>
        ) : (
          <InterestButton kind="notify_ios">{copy.ios.notify}</InterestButton>
        )}
      </Platform>
      <Reveal className="texture-grain relative flex flex-col gap-4 overflow-hidden rounded-xl bg-seed p-8 text-white [--thread-color:rgb(255_255_255/0.2)] dark:bg-teal-900">
        <Contour radius={36} inset={10} />
        <Image
          src="/illustrations/staff.webp"
          alt=""
          width={120}
          height={120}
          className="relative h-24 w-auto self-start drop-shadow-[0_10px_12px_rgb(0_0_0/0.25)]"
        />
        <h3 className="relative m-0 flex items-center gap-2 text-xl font-extrabold tracking-tight">
          <Icon icon={UserGroupIcon} size={20} />
          {copy.staff.title}
        </h3>
        <p className="relative m-0 leading-relaxed text-white/75">{copy.staff.text}</p>
      </Reveal>
    </div>
  );
}
