"use client";

import type { ReactNode } from "react";

import { HelpSheet } from "@/components/ui/HelpSheet";
import { Tabs } from "@/components/ui/Tabs";
import type { Messages } from "@/lib/i18n/messages";
import type { InsightView } from "@/lib/insights";

type Props = {
  view: InsightView;
  /** Help for the view on show. */
  help: { title: string; intro: string; scenarios: Record<string, { title: string; body: string }> };
  t: Messages;
  /** The view's own controls, after the view tabs. */
  children?: ReactNode;
};

/** The headline of every Insights view: the title, the view's help, the views as tabs, then the view's own controls. */
export function InsightsHeader({ view, help, t, children }: Props) {
  const s = t.insights;
  return (
    <div className="flex flex-wrap items-center gap-2">
      <h1 className="text-2xl font-extrabold tracking-tight sm:text-3xl">{s.title}</h1>
      <HelpSheet
        label={t.help.open}
        title={help.title}
        intro={help.intro}
        scenarios={Object.values(help.scenarios)}
        scenariosLabel={t.help.scenarios}
        closeLabel={t.help.close}
      />
      <div className="ml-auto flex flex-wrap items-center gap-2">
        <Tabs
          label={s.views.label}
          items={[
            { id: "load", label: s.views.load, href: "/insights" },
            { id: "proximity", label: s.views.proximity, href: "/insights?view=proximity" },
          ]}
          active={view}
        />
        {children}
      </div>
    </div>
  );
}
