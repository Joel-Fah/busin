import type { ReactNode } from "react";

/**
 * The column every student page sits in: phone width on a phone, a centred 640 px column on anything larger (the
 * student app's breakpoints), with room at the bottom for the tab bar.
 */
export function StudentPage({ title, subtitle, children, lang }: { title: string; subtitle?: string; children: ReactNode; lang: string }) {
  return (
    <main lang={lang} className="student-in mx-auto flex min-h-dvh w-full max-w-[640px] flex-col gap-5 px-4 pt-[max(1.5rem,env(safe-area-inset-top))] pb-36 sm:px-6">
      <header className="flex flex-col gap-1 pt-2">
        <h1 className="m-0 text-4xl font-extrabold tracking-tight">{title}</h1>
        {subtitle ? <p className="m-0 text-muted">{subtitle}</p> : null}
      </header>
      {children}
    </main>
  );
}
