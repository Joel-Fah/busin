import { WifiDisconnected01Icon } from "@hugeicons/core-free-icons";
import type { Metadata } from "next";

import { BrandMark } from "@/components/brand/BrandMark";
import { Icon } from "@/components/ui/Icon";
import { studentCatalogues } from "@/lib/i18n/student";

export const metadata: Metadata = { title: "No connection" };

/**
 * What the service worker shows when a page of the app is asked for without a connection and was never saved. Static (no
 * cookie, no session), so it can be kept in the cache; both languages, since the visitor's choice cannot be read here.
 */
export default function OfflinePage() {
  return (
    <main className="mx-auto flex min-h-dvh max-w-[640px] flex-col justify-center gap-8 px-6 py-12">
      <BrandMark className="h-10 w-auto self-start text-brand" label="BusIn" />
      {(["en", "fr"] as const).map((locale) => {
        const s = studentCatalogues[locale].offline;
        return (
          <section key={locale} lang={locale} className="flex flex-col gap-2">
            <h1 className="m-0 flex items-center gap-2 text-2xl font-extrabold tracking-tight">
              <Icon icon={WifiDisconnected01Icon} size={24} />
              {s.title}
            </h1>
            <p className="m-0 text-muted">{s.body}</p>
          </section>
        );
      })}
      <a href="/app" className="inline-flex h-12 w-fit items-center rounded-sm bg-accent px-5 font-semibold text-on-accent no-underline">
        {studentCatalogues.en.offline.retry} / {studentCatalogues.fr.offline.retry}
      </a>
    </main>
  );
}
