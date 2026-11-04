import type { ReactNode } from "react";

import { BrandMark } from "@/components/brand/BrandMark";
import { Card } from "@/components/ui/Card";

type Props = {
  lang: string;
  title: string;
  /** Marks the page as a development tool, with a quieter title. */
  children: ReactNode;
};

/** The centred page for signing in and for being turned away: the logo, a title, and what the person can do. */
export function AuthShell({ lang, title, children }: Props) {
  return (
    <main lang={lang} className="grid min-h-dvh place-items-center bg-bg p-6">
      <Card grain className="flex w-full max-w-md flex-col gap-5 p-10">
        <BrandMark className="h-auto w-28 text-brand" label="BusIn" />
        <h1 className="text-3xl font-extrabold tracking-tight">{title}</h1>
        {children}
      </Card>
    </main>
  );
}
