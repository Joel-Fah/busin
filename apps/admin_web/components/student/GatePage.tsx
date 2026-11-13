import type { ReactNode } from "react";

import { BrandMark } from "@/components/brand/BrandMark";

/**
 * The frame of the pages before the app proper (choose a school, wait for it, tell it who you are): the logo, a large
 * title and the content in the phone-width column. No tab bar: there is nothing else to open yet.
 */
export function GatePage({ lang, title, intro, children }: { lang: string; title: string; intro?: string; children: ReactNode }) {
  return (
    <main lang={lang} className="student-in mx-auto flex min-h-dvh w-full max-w-[640px] flex-col gap-5 px-4 pt-[max(1.5rem,env(safe-area-inset-top))] pb-[max(2rem,env(safe-area-inset-bottom))] sm:px-6">
      <BrandMark className="h-9 w-auto self-start text-brand" label="BusIn" />
      <header className="flex flex-col gap-2 pt-4">
        <h1 className="m-0 text-4xl font-extrabold tracking-tight text-balance">{title}</h1>
        {intro ? <p className="m-0 text-muted">{intro}</p> : null}
      </header>
      {children}
    </main>
  );
}
