import Image from "next/image";
import { Suspense } from "react";

import { LanguageSwitch } from "@/components/LanguageSwitch";
import { NavLinks, type NavItem } from "@/components/NavLinks";
import { SignOutButton } from "@/components/SignOutButton";
import { requireAdmin } from "@/lib/auth";
import { getMessages } from "@/lib/i18n/server";

// Everything in the shell depends on who is signed in, so it renders at request time
// behind a Suspense boundary. The fallback is the only part prerendered. Visitors who are not
// signed in are redirected, so Next's "instant navigation" check cannot apply here.
export const instant = false;

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <Suspense fallback={<div className="shell" aria-busy="true" />}>
      <AdminShell>{children}</AdminShell>
    </Suspense>
  );
}

async function AdminShell({ children }: { children: React.ReactNode }) {
  const admin = await requireAdmin();
  const { locale, t } = await getMessages();

  const items: NavItem[] = [{ href: "/", label: t.nav.overview }];

  return (
    <div className="shell" lang={locale}>
      <aside className="sidebar">
        <Image src="/brand/white.svg" alt={t.appName} width={205} height={126} className="logo" priority />
        <nav className="nav" aria-label={t.nav.primary}>
          <NavLinks items={items} />
        </nav>
        <div className="sidebar-footer">
          <span>{admin.email}</span>
          <LanguageSwitch locale={locale} t={t} />
          <SignOutButton label={t.nav.signOut} />
        </div>
      </aside>
      <main className="main">{children}</main>
    </div>
  );
}
