import { Add01Icon, Calendar02Icon, FlagTriangleRightIcon } from "@hugeicons/core-free-icons";

import { ButtonLink } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import type { Messages } from "@/lib/i18n/messages";
import type { InsightView } from "@/lib/insights";

import { InsightsHeader } from "./InsightsHeader";

const ILLUSTRATION: Record<InsightView, string> = {
  load: "/illustrations/bus.webp",
  proximity: "/illustrations/bus-stop.webp",
  graph: "/illustrations/papers.webp",
  suggestions: "/illustrations/waiting.webp",
};

/**
 * An Insights view with nothing to show yet: the title, the views and the view's help stay, and instead of a map and
 * cards full of zeros the page says what the view needs before it fills in, with the next step to take.
 */
export function InsightsEmpty({ view, t }: { view: InsightView; t: Messages }) {
  const s = t.insights;
  const help = view === "load" ? s.help : view === "proximity" ? s.proximity.help : view === "graph" ? s.graph.help : s.suggestions.help;
  const copy = s.nothingYet[view];
  return (
    <section className="flex flex-col gap-6">
      <InsightsHeader view={view} help={help} t={t} />
      <EmptyState
        illustration={ILLUSTRATION[view]}
        title={copy.title}
        body={copy.body}
        action={
          <div className="flex flex-wrap justify-center gap-2">
            {view === "proximity" || view === "suggestions" ? (
              <ButtonLink href="/stops" variant="secondary" icon={FlagTriangleRightIcon}>
                {s.nothingYet.stops}
              </ButtonLink>
            ) : (
              <>
                <ButtonLink href="/semesters/new" variant="secondary" icon={Calendar02Icon}>
                  {s.nothingYet.semester}
                </ButtonLink>
                <ButtonLink href="/trips/new" icon={Add01Icon}>
                  {s.nothingYet.trip}
                </ButtonLink>
              </>
            )}
          </div>
        }
      />
    </section>
  );
}
