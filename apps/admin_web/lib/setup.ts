/** One step of setting a school up, and whether it is done. */
export type SetupStep = { key: "semester" | "billing" | "stops" | "buses" | "staff" | "trip"; href: string; done: boolean };

/**
 * What a school needs before students can ride, in the order it makes sense to do it: a semester to subscribe to, billing
 * (students cannot ask before it is set, ADR 0022), stops to choose, a bus, staff to drive and scan, and a first trip.
 * Null once all is done, so the overview stops showing it.
 */
export function setupSteps(counts: { semesters: number; stops: number; buses: number; staff: number; trips: number }, billingSet: boolean): SetupStep[] | null {
  const steps: SetupStep[] = [
    { key: "semester", href: "/semesters/new", done: counts.semesters > 0 },
    { key: "billing", href: "/billing", done: billingSet },
    { key: "stops", href: "/stops?add", done: counts.stops > 0 },
    { key: "buses", href: "/buses/new?next=%2F", done: counts.buses > 0 },
    { key: "staff", href: "/people/invite", done: counts.staff > 0 },
    { key: "trip", href: "/trips/new", done: counts.trips > 0 },
  ];
  return steps.every((step) => step.done) ? null : steps;
}
