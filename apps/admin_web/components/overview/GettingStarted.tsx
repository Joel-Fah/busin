import { ArrowRight01Icon, CheckmarkCircle02Icon } from "@hugeicons/core-free-icons";
import Link from "next/link";

import { Contour } from "@/components/ui/Contour";
import { Icon } from "@/components/ui/Icon";
import { format, type Messages } from "@/lib/i18n/messages";
import type { SetupStep } from "@/lib/setup";

/**
 * What a school needs before students can ride, while it is still being set up: each step links straight to where it is
 * done, and is ticked once it is. Gone for good once every step is done.
 */
export function GettingStarted({ steps, t }: { steps: SetupStep[]; t: Messages }) {
  const g = t.overview.gettingStarted;
  const done = steps.filter((step) => step.done).length;
  return (
    <section aria-labelledby="getting-started" className="relative rounded-xl bg-surface p-6 shadow-soft sm:col-span-2 xl:col-span-4">
      <Contour radius={36} inset={16} />
      <div className="flex flex-wrap items-baseline justify-between gap-2">
        <h2 id="getting-started" className="text-xl font-bold">
          {g.title}
        </h2>
        <p className="text-sm font-semibold text-muted">{format(g.progress, { done, total: steps.length })}</p>
      </div>
      <p className="mt-1 max-w-2xl text-sm text-muted">{g.intro}</p>
      <ol className="m-0 mt-5 grid list-none gap-2 p-0 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6">
        {steps.map((step, index) => (
          <li key={step.key}>
            <Link
              href={step.href}
              aria-label={`${g.steps[step.key].title}${step.done ? ` (${g.done})` : ""}`}
              className={
                "flex h-full flex-col gap-1 rounded-md p-4 text-fg no-underline transition-colors duration-(--dur-fast) focus-visible:outline-3 focus-visible:outline-focus " +
                (step.done ? "bg-ok-bg" : "bg-surface-2 hover:bg-line")
              }
            >
              <span className="flex items-center justify-between gap-2 text-xs font-semibold text-muted">
                {format(g.step, { n: index + 1 })}
                {step.done ? (
                  <span className="inline-flex items-center gap-1 text-ok">
                    <Icon icon={CheckmarkCircle02Icon} size={16} />
                    {g.done}
                  </span>
                ) : (
                  <Icon icon={ArrowRight01Icon} size={16} />
                )}
              </span>
              <span className="font-bold">{g.steps[step.key].title}</span>
              <span className="text-sm text-muted">{g.steps[step.key].body}</span>
            </Link>
          </li>
        ))}
      </ol>
    </section>
  );
}
