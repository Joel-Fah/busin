import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { Suspense } from "react";
import { Archive01Icon, ArchiveRestoreIcon, ArrowRight01Icon, Cancel01Icon, Note01Icon, StopCircleIcon } from "@hugeicons/core-free-icons";

import { ButtonLink } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { BackLink } from "@/components/ui/BackLink";
import { Chip } from "@/components/ui/Chip";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { FlashToast } from "@/components/FlashToast";
import { Notice } from "@/components/ui/Notice";
import { Button } from "@/components/ui/Button";
import { Textarea } from "@/components/ui/Textarea";

import { TripForm } from "@/components/TripForm";
import { requireAdmin } from "@/lib/auth";
import { format, type Locale, type Messages } from "@/lib/i18n/messages";
import { getMessages } from "@/lib/i18n/server";
import { isUuid } from "@/lib/ids";
import { MAX_REASON_LENGTH, formatMinutes, isDirection, isTripDone, isTripFormErrorKey, isTripStatus, overdueById, tripStatusTone, type Overdue } from "@/lib/trips";
import { loadTripOptions } from "@/lib/trips-data";
import { createClient } from "@/lib/supabase/server";
import { utcToZonedLocal } from "@/lib/zoned";

import { cancelTrip, endTrip, setTripArchived, updateTrip } from "../actions";

export const metadata: Metadata = { title: "Trip" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type Params = Promise<{ id: string }>;
type SearchParams = Promise<{ done?: string | string[]; error?: string | string[] }>;

export default function TripPage({ params, searchParams }: { params: Params; searchParams: SearchParams }) {
  return (
    <Suspense fallback={<ListSkeleton rows={2} />}>
      <TripDetail params={params} searchParams={searchParams} />
    </Suspense>
  );
}

/** Why the trip is overdue, as a phrase for the notice. */
function overdueWhy(overdue: Overdue, t: Messages, locale: Locale, timeZone: string): string {
  const o = t.trips.overdue;
  if (overdue.reason === "earlier_day") {
    const day = new Intl.DateTimeFormat(locale, { weekday: "long", day: "numeric", month: "long", timeZone }).format(new Date(overdue.startedAt));
    return format(o.earlier_day, { day });
  }
  return format(overdue.reason === "silent" ? o.silent : o.long, { duration: formatMinutes(overdue.minutes) });
}

function single(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

async function TripDetail({ params, searchParams }: { params: Params; searchParams: SearchParams }) {
  const admin = await requireAdmin();
  const { locale, t } = await getMessages();
  const { id } = await params;
  if (!isUuid(id)) notFound();

  const supabase = await createClient();
  const { data: trip } = await supabase
    .from("trips")
    .select("id, bus_id, driver_id, assistant_id, direction, status, scheduled_start, archived_at, origin, created_by")
    .eq("id", id)
    .maybeSingle();
  if (!trip || !isDirection(trip.direction) || !isTripStatus(trip.status)) notFound();

  const running = trip.status === "active";
  const [{ buses, drivers, failed }, overdueRows] = await Promise.all([
    loadTripOptions(trip.bus_id),
    running ? supabase.rpc("admin_overdue_trips") : Promise.resolve({ data: [] }),
  ]);
  const overdue = overdueById(overdueRows.data ?? [], new Date()).get(trip.id);
  // Who started it, when it was started in the field from the ops app rather than scheduled here.
  const starter =
    trip.origin === "field" && trip.created_by
      ? (await supabase.from("profiles").select("full_name, email").eq("id", trip.created_by).maybeSingle()).data
      : null;

  const query = await searchParams;
  const doneParam = single(query.done);
  const errorParam = single(query.error);
  const done = isTripDone(doneParam) ? doneParam : null;
  const errorKey = isTripFormErrorKey(errorParam) ? errorParam : null;
  const editable = trip.status === "scheduled";
  const archived = trip.archived_at !== null;
  const m = t.trips.manage;

  return (
    <>
      <BackLink href="/trips">{t.trips.form.back}</BackLink>
      <header>
        <h1 className="text-4xl font-extrabold tracking-tight sm:text-5xl">{t.trips.direction[trip.direction]}</h1>
        <p className="mt-2 flex flex-wrap items-center gap-2">
          <Chip tone={tripStatusTone(trip.status)}>{t.trips.status[trip.status]}</Chip>
          {archived ? <Chip tone="neutral">{t.trips.archivedChip}</Chip> : null}
          {trip.origin === "field" ? <Chip tone="accent">{t.trips.fieldChip}</Chip> : null}
          {overdue ? <Chip tone="warn">{t.trips.overdue.chip}</Chip> : null}
        </p>
      </header>

      {overdue ? <Notice tone="warn">{format(t.trips.overdue.notice, { why: overdueWhy(overdue, t, locale, admin.schoolTimezone) })}</Notice> : null}

      {trip.origin === "field" ? <Notice tone="info">{format(t.trips.fieldNotice, { name: starter?.full_name || starter?.email || "-" })}</Notice> : null}

      {done ? <FlashToast message={t.trips.done[done]} /> : null}
      {errorKey ? <Notice tone="bad">{t.trips.errors[errorKey]}</Notice> : null}

      {failed ? (
        <Notice tone="bad">{t.trips.loadError}</Notice>
      ) : editable ? (
        <TripForm
          action={updateTrip}
          t={t}
          locale={locale}
          buses={buses}
          drivers={drivers}
          timeZone={admin.schoolTimezone}
          trip={{
            id: trip.id,
            busId: trip.bus_id,
            driverId: trip.driver_id,
            assistantId: trip.assistant_id,
            direction: trip.direction,
            start: utcToZonedLocal(trip.scheduled_start, admin.schoolTimezone),
          }}
        />
      ) : (
        <Card className="flex max-w-2xl flex-col items-start gap-4">
          <p>{t.trips.locked}</p>
          <ButtonLink href={`/scans?trip=${trip.id}`} variant="secondary" icon={ArrowRight01Icon}>
            {t.trips.viewBoardings}
          </ButtonLink>
        </Card>
      )}

      {editable ? (
        <Card className="flex max-w-2xl flex-col gap-4">
          <h2 className="text-xl font-bold">{m.cancelHeading}</h2>
          <details>
            <summary className="inline-flex cursor-pointer list-none items-center gap-2 rounded-sm px-4 py-2.5 text-sm font-semibold text-bad transition-colors duration-(--dur-fast) hover:bg-bad-bg focus-visible:outline-3 focus-visible:outline-focus [&::-webkit-details-marker]:hidden">
              {m.cancelOpen}
            </summary>
            <form action={cancelTrip} className="mt-4 flex flex-col gap-4">
              <input type="hidden" name="id" value={trip.id} />
              <p className="text-sm text-muted">{m.cancelHint}</p>
              <Textarea id="reason" name="reason" label={m.reason} icon={Note01Icon} hint={m.reasonHint} maxLength={MAX_REASON_LENGTH} rows={3} />
              <div>
                <Button type="submit" variant="danger" icon={Cancel01Icon}>
                  {m.cancelConfirm}
                </Button>
              </div>
            </form>
          </details>
        </Card>
      ) : running ? (
        <Card className="flex max-w-2xl flex-col gap-4">
          <h2 className="text-xl font-bold">{m.endHeading}</h2>
          <details open={overdue !== undefined}>
            <summary className="inline-flex cursor-pointer list-none items-center gap-2 rounded-sm px-4 py-2.5 text-sm font-semibold text-bad transition-colors duration-(--dur-fast) hover:bg-bad-bg focus-visible:outline-3 focus-visible:outline-focus [&::-webkit-details-marker]:hidden">
              {m.endOpen}
            </summary>
            <form action={endTrip} className="mt-4 flex flex-col gap-4">
              <input type="hidden" name="id" value={trip.id} />
              <p className="text-sm text-muted">{m.endHint}</p>
              <div>
                <Button type="submit" variant="danger" icon={StopCircleIcon}>
                  {m.endConfirm}
                </Button>
              </div>
            </form>
          </details>
        </Card>
      ) : trip.status === "cancelled" || trip.status === "completed" ? (
        <Card className="flex max-w-2xl flex-col items-start gap-4">
          <h2 className="text-xl font-bold">{m.archiveHeading}</h2>
          <form action={setTripArchived} className="flex flex-col items-start gap-4">
            <input type="hidden" name="id" value={trip.id} />
            <input type="hidden" name="archive" value={archived ? "false" : "true"} />
            <p className="text-sm text-muted">{archived ? m.archivedHint : m.archiveHint}</p>
            <Button type="submit" variant="secondary" icon={archived ? ArchiveRestoreIcon : Archive01Icon}>
              {archived ? m.restore : m.archive}
            </Button>
          </form>
        </Card>
      ) : null}
    </>
  );
}
