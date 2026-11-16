import { Suspense } from "react";

import { BrandIntro } from "@/components/brand/BrandIntro";
import { FloatingNav, type NavKey } from "@/components/nav/FloatingNav";
import { RoughFilter } from "@/components/ui/RoughFilter";
import { platformContext } from "@/lib/auth";
import { getMessages } from "@/lib/i18n/server";

// Depends on who is signed in, so it renders at request time behind a Suspense boundary.
export const instant = false;

export default function PlatformLayout({ children }: { children: React.ReactNode }) {
  return (
    <Suspense fallback={<div aria-busy="true" />}>
      <PlatformShell>{children}</PlatformShell>
    </Suspense>
  );
}

const KEYS: NavKey[] = ["platform"];

/**
 * The platform console's shell (ADR 0027): the same look as the school portal, its own tabs. Someone who is not a
 * platform admin gets the page's "not found" with no navigation, so the console does not show that it exists; each page
 * checks again (requirePlatformAdmin).
 */
async function PlatformShell({ children }: { children: React.ReactNode }) {
  const platform = await platformContext();
  const { locale, t } = await getMessages();
  const main = (
    <main className="mx-auto flex w-full max-w-7xl min-w-0 flex-col gap-6 px-[clamp(1rem,4vw,2.5rem)] pt-8 pb-44">{children}</main>
  );
  if (!platform) return <div lang={locale}>{main}</div>;

  return (
    <div lang={locale}>
      <BrandIntro />
      <RoughFilter />
      {main}
      <FloatingNav
        keys={KEYS}
        labels={t.nav}
        groups={[{ label: t.platform.groupConsole, keys: KEYS }]}
        profile={{ name: platform.fullName || platform.email, avatarUrl: platform.avatarUrl, href: "/platform/account" }}
        text={{ ...t.nav, home: t.platform.home }}
        homeHref="/platform"
      />
    </div>
  );
}
