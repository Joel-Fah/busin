"use client";

import { Flag02Icon, Gps01Icon, InformationCircleIcon, Location01Icon, UserCircleIcon, WalkingIcon } from "@hugeicons/core-free-icons";
import dynamic from "next/dynamic";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { useEffect, useReducer, useRef, useState } from "react";

import { Button } from "@/components/ui/Button";
import { Contour } from "@/components/ui/Contour";
import { Icon } from "@/components/ui/Icon";
import { Modal } from "@/components/ui/Modal";
import { Notice } from "@/components/ui/Notice";
import { parsePoint, type LatLng } from "@/lib/geo";
import { format } from "@/lib/i18n/format";
import type { StudentCopy } from "@/lib/i18n/student";
import type { MapConfig } from "@/lib/map/config";
import { BusUpdateDetector, STALE_AFTER_MS, estimateEta, walkToStop, type BusUpdate, type Position, type StopPoint } from "@/lib/student/bus";
import { addTrailPoint, keepUpdate, lineFromGeoJson, mergeTrail, type SchoolRoute } from "@/lib/student/bus-map";
import { markTripsSeen } from "@/lib/student/bus-news";
import { browserClient } from "@/lib/supabase/browser";

import { BusLegend } from "./BusLegend";
import { UpdateList, UpdateStrip, UpdatesFold, updateIcon, updateText } from "./BusUpdates";

// The map needs the browser; it loads on demand, with a calm placeholder meanwhile.
const BusMap = dynamic(() => import("./BusMap"), { ssr: false, loading: () => <div className="map map-full map-loading" aria-busy="true" /> });

export type RunningTrip = { id: string; busId: string; bus: string; direction: "inbound" | "outbound" };

type Props = {
  copy: StudentCopy["bus"];
  locale: string;
  map: MapConfig;
  trips: RunningTrip[];
  stops: StopPoint[];
  myStop: StopPoint | null;
  /** The last known position of each running bus, when the page was made. */
  initial: Record<string, Position>;
  /** The school's planned route and campus, or null when neither is set. */
  route: SchoolRoute | null;
  /** Whose updates these are: another student signing in on this browser does not see them. */
  userId: string;
  /** When the page was made: the first render counts "updated ... ago" from it, so the server and the browser agree. */
  renderedAt: number;
};

type Me = { kind: "off" } | { kind: "asking" } | { kind: "on"; at: LatLng | null } | { kind: "problem"; text: string };

/**
 * The updates of each followed trip, newest first, with the detector that keeps track of what its bus did. Kept while
 * the app is open (not only the tab), so going to another tab and back finds them again; a trip's entry goes when it
 * ends, and all of it when another student signs in. Never stored or sent.
 */
const log = { user: "", updates: new Map<string, BusUpdate[]>(), detectors: new Map<string, BusUpdateDetector>() };

function logFor(userId: string) {
  // Only in the browser: on the server this module is shared by every request.
  if (typeof window === "undefined") return { user: userId, updates: new Map<string, BusUpdate[]>(), detectors: new Map<string, BusUpdateDetector>() };
  if (log.user !== userId) {
    log.user = userId;
    log.updates.clear();
    log.detectors.clear();
  }
  return log;
}

/** Room the buttons take at the top of the map. */
const TOP_COVERED = 64;

/**
 * My bus, as in the app: the running buses as choices, the map with the followed bus gliding and followed by the camera,
 * the student's stop, the other stops with their names, the campus, the planned route and the trip's trail, and a card
 * floating over the map's bottom with the arrival at the student's stop and the trip's updates folded in. Positions come
 * through Realtime, only for the followed bus and only while the tab is visible; RLS lets only a subscriber read them.
 */
export function BusTracker({ copy, locale, map, trips, stops, myStop, initial, route, userId, renderedAt }: Props) {
  const router = useRouter();
  const [chosen, setChosen] = useState<string | null>(trips[0]?.id ?? null);
  const trip = trips.find((t) => t.id === chosen) ?? trips[0] ?? null;
  const [positions, setPositions] = useState<Record<string, Position>>(initial);
  const [, logChanged] = useReducer((n: number) => n + 1, 0);
  const [now, setNow] = useState(renderedAt);
  const [liveFailed, setLiveFailed] = useState(false);
  const [me, setMe] = useState<Me>({ kind: "off" });
  const [focusMe, setFocusMe] = useState(0);
  const [recenter, setRecenter] = useState(0);
  const [busInView, setBusInView] = useState(true);
  const [legend, setLegend] = useState(false);
  // Where the followed trip's bus has been, kept with its trip so following another starts afresh.
  const [trailOf, setTrailOf] = useState<{ tripId: string | null; points: LatLng[] }>({ tripId: null, points: [] });
  const [cardHeight, setCardHeight] = useState(160);
  const [ended, setEnded] = useState<BusUpdate | null>(null);
  const card = useRef<HTMLElement>(null);
  const followed = useRef<RunningTrip | null>(null);

  const tripId = trip?.id ?? null;
  const busId = trip?.busId ?? null;
  const position = busId ? positions[busId] ?? null : null;
  const trail = trailOf.tripId === tripId ? trailOf.points : [];
  const store = logFor(userId);

  // These trips are seen: no dot on the tab for them.
  const tripIds = trips.map((t) => t.id).join(",");
  useEffect(() => {
    if (tripIds) markTripsSeen(tripIds.split(","));
  }, [tripIds]);

  // Adds what the followed bus did to its trip's updates.
  const said = (id: string, update: BusUpdate | null) => {
    if (!update) return;
    store.updates.set(id, keepUpdate(store.updates.get(id) ?? [], update));
    logChanged();
  };
  const detectorFor = (id: string) => {
    let detector = store.detectors.get(id);
    if (!detector) {
      detector = new BusUpdateDetector(stops, myStop);
      store.detectors.set(id, detector);
    }
    return detector;
  };

  // A trip followed before has stopped running: said, and its updates go. The first known position starts the new one.
  useEffect(() => {
    const before = followed.current;
    if (before && before.id !== tripId && !trips.some((t) => t.id === before.id)) {
      store.updates.delete(before.id);
      store.detectors.delete(before.id);
      setEnded({ kind: "tripEnded", at: Date.now(), seq: -Date.now(), stopName: before.bus });
    }
    followed.current = trip;
    if (trip && busId && positions[busId]) said(trip.id, detectorFor(trip.id).onPosition(positions[busId], Date.now()));
    // Positions are read once here on purpose: later ones arrive through the channel below.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tripId]);

  // Where this bus has been on its trip: what the server kept, then each position as it arrives.
  useEffect(() => {
    if (!tripId) return;
    let stopped = false;
    void (async () => {
      const { data, error } = await browserClient().rpc("trip_trail", { p_trip_id: tripId });
      if (stopped || error) return;
      const kept = lineFromGeoJson(data);
      setTrailOf((t) => ({ tripId, points: mergeTrail(kept, t.tripId === tripId ? t.points : []) }));
    })();
    return () => {
      stopped = true;
    };
  }, [tripId]);

  // Live positions of the followed bus, while the tab is visible.
  useEffect(() => {
    if (!busId || !tripId) return;
    const supabase = browserClient();
    let channel: ReturnType<typeof supabase.channel> | null = null;
    let stopped = false;
    const open = async () => {
      if (channel) return;
      const { data } = await supabase.auth.getSession();
      if (stopped || channel || !data.session) return;
      await supabase.realtime.setAuth(data.session.access_token);
      if (stopped || channel) return;
      channel = supabase
        .channel(`live:${busId}`)
        .on("postgres_changes", { event: "*", schema: "public", table: "live_positions", filter: `bus_id=eq.${busId}` }, (payload) => {
          const row = payload.new as { trip_id?: string | null; location?: unknown; speed_mps?: number | null; recorded_at?: string } | null;
          const at = row ? parsePoint(row.location) : null;
          if (!row || !at || !row.recorded_at) return;
          const next: Position = { tripId: row.trip_id ?? null, position: at, speedMps: row.speed_mps ?? null, recordedAt: Date.parse(row.recorded_at) };
          setPositions((all) => ({ ...all, [busId]: next }));
          if (next.tripId === null || next.tripId === tripId) setTrailOf((t) => ({ tripId, points: addTrailPoint(t.tripId === tripId ? t.points : [], at) }));
          said(tripId, detectorFor(tripId).onPosition(next, Date.now()));
        })
        .subscribe((status) => setLiveFailed(status === "CHANNEL_ERROR" || status === "TIMED_OUT"));
    };
    const close = () => {
      if (channel) void supabase.removeChannel(channel);
      channel = null;
    };
    const onVisible = () => {
      if (document.visibilityState === "visible") {
        void open();
        router.refresh();
      } else close();
    };
    if (document.visibilityState === "visible") void open();
    document.addEventListener("visibilitychange", onVisible);
    return () => {
      stopped = true;
      document.removeEventListener("visibilitychange", onVisible);
      close();
    };
    // said and detectorFor only touch the shared log.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [busId, tripId, router]);

  // The clock for "updated ... ago" and "no signal"; the list of running trips is read again every minute.
  useEffect(() => {
    const tick = window.setInterval(() => {
      const at = Date.now();
      setNow(at);
      const id = followed.current?.id;
      if (id) said(id, detectorFor(id).onTick(at));
    }, 10_000);
    const reload = window.setInterval(() => {
      if (document.visibilityState === "visible") router.refresh();
    }, 60_000);
    return () => {
      window.clearInterval(tick);
      window.clearInterval(reload);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [router]);

  // Show me: the precise position, only after the student agreed, only while the tab is visible, never sent.
  useEffect(() => {
    if (me.kind !== "on") return;
    let watch: number | null = null;
    const start = () => {
      if (watch !== null) return;
      watch = navigator.geolocation.watchPosition(
        (p) => setMe({ kind: "on", at: { lat: p.coords.latitude, lng: p.coords.longitude } }),
        (error) => setMe({ kind: "problem", text: error.code === error.PERMISSION_DENIED ? copy.me.denied : copy.me.unavailable }),
        { enableHighAccuracy: true, maximumAge: 10_000, timeout: 20_000 },
      );
    };
    const stop = () => {
      if (watch !== null) navigator.geolocation.clearWatch(watch);
      watch = null;
    };
    const onVisible = () => (document.visibilityState === "visible" ? start() : stop());
    start();
    document.addEventListener("visibilitychange", onVisible);
    return () => {
      document.removeEventListener("visibilitychange", onVisible);
      stop();
    };
  }, [me.kind, copy.me.denied, copy.me.unavailable]);

  // The card's height, so the map frames the bus above it.
  useEffect(() => {
    const element = card.current;
    if (!element) return;
    const watcher = new ResizeObserver(() => setCardHeight(element.offsetHeight));
    watcher.observe(element);
    return () => watcher.disconnect();
  }, [tripId]);

  if (!trip) return null;

  const direction = copy.directions[trip.direction];
  const updates = [...(ended ? [ended] : []), ...(store.updates.get(trip.id) ?? [])].sort((a, b) => b.at - a.at);
  const newest = updates[0] ?? null;
  const newestText = newest ? updateText(copy, newest, trip.bus, direction, now) : null;
  const age = position ? Math.max(0, now - position.recordedAt) : null;
  const stale = age !== null && age >= STALE_AFTER_MS;
  // An estimate only from a fresh position: a stale one would promise something the bus may not be doing.
  const eta = position && myStop && !stale ? estimateEta(position.position, myStop.position, position.speedMps) : null;
  const number = new Intl.NumberFormat(locale, { maximumFractionDigits: 1, minimumFractionDigits: 1 });
  const meAt = me.kind === "on" ? me.at : null;
  const walk = meAt && myStop ? walkToStop(meAt, myStop.position) : null;
  const kmh = position?.speedMps != null ? Math.round(position.speedMps * 3.6) : null;
  const updated = age === null ? null : age < 90_000 ? format(copy.updatedSeconds, { seconds: Math.max(1, Math.round(age / 1000)) }) : format(copy.updatedMinutes, { minutes: Math.round(age / 60_000) });
  // One status line: the direction, how fresh the position is and the speed; or the warning if it has gone quiet.
  const status = stale ? format(copy.stale, { minutes: Math.round(age! / 60_000) }) : [direction, updated, kmh ? format(copy.speed, { kmh }) : null].filter(Boolean).join(" · ");

  return (
    <div className="flex flex-col gap-3">
      {trips.length > 1 ? (
        <div role="radiogroup" aria-label={copy.running} className="flex flex-wrap gap-2">
          {trips.map((t) => (
            <button
              key={t.id}
              type="button"
              role="radio"
              aria-checked={t.id === trip.id}
              onClick={() => setChosen(t.id)}
              className={
                "inline-flex h-11 cursor-pointer items-center gap-2 rounded-sm border-0 px-4 font-sans text-sm font-semibold focus-visible:outline-3 focus-visible:outline-focus " +
                (t.id === trip.id ? "bg-seed text-white" : "bg-surface text-fg shadow-soft")
              }
            >
              {t.bus} <span className="font-normal opacity-80">{copy.directions[t.direction]}</span>
            </button>
          ))}
        </div>
      ) : null}

      <div className="relative h-[calc(100dvh-15rem)] min-h-[32rem] overflow-hidden rounded-lg shadow-soft">
        <BusMap
          styleUrl={map.styleUrl}
          darkStyleUrl={map.darkStyleUrl}
          stops={stops}
          myStopId={myStop?.id ?? null}
          bus={position?.position ?? null}
          me={meAt}
          route={route?.line ?? []}
          trail={trail}
          campus={route?.campus ?? null}
          campusName={route?.campusName ?? null}
          focusMe={focusMe}
          recenter={recenter}
          fallback={map.fallbackCenter}
          topCovered={TOP_COVERED}
          coveredBottom={cardHeight + 12}
          onBusInView={setBusInView}
          ariaLabel={copy.map}
          unavailableLabel={copy.mapUnavailable}
        />

        {/* What floats over the top of the map: a status line while waiting or failing, the latest update, the buttons. */}
        <div className="pointer-events-none absolute inset-x-3 top-3 z-10 flex flex-col gap-2 [&>*]:pointer-events-auto">
          {!position ? <Notice tone="info">{copy.waiting}</Notice> : null}
          {liveFailed ? <Notice tone="bad">{copy.liveFailed}</Notice> : null}
          {me.kind === "problem" ? <Notice tone="warn">{me.text}</Notice> : null}
          <UpdateStrip update={newest} text={newestText} dismiss={copy.dismiss} />
          <div className="flex flex-wrap items-center justify-end gap-2 self-end">
            <button
              type="button"
              onClick={() => setLegend(true)}
              aria-label={copy.legend.open}
              title={copy.legend.open}
              className="grid size-12 cursor-pointer place-items-center rounded-full border-0 bg-surface-2 text-fg shadow-soft focus-visible:outline-3 focus-visible:outline-focus"
            >
              <Icon icon={InformationCircleIcon} size={22} />
            </button>
            {meAt ? (
              <Button variant="secondary" icon={UserCircleIcon} onClick={() => setFocusMe((n) => n + 1)}>
                {copy.find}
              </Button>
            ) : null}
            <Button variant="secondary" icon={Gps01Icon} onClick={() => setMe(me.kind === "on" ? { kind: "off" } : { kind: "asking" })}>
              {me.kind === "on" ? copy.me.hide : copy.me.show}
            </Button>
            {position && !busInView ? (
              <Button variant="secondary" icon={Location01Icon} onClick={() => setRecenter((n) => n + 1)}>
                {copy.recenter}
              </Button>
            ) : null}
          </div>
        </div>

        {/* The bus card, floating over the bottom of the map. */}
        <section ref={card} className="absolute inset-x-3 bottom-3 z-10 mx-auto flex max-w-[520px] flex-col gap-2 rounded-lg bg-surface px-5 pt-4 pb-3 shadow-float" data-testid="bus-status">
          <Contour radius={28} inset={10} />
          <div className="relative flex items-center gap-3">
            <Image src="/illustrations/bus.webp" alt="" width={44} height={44} className="size-11 object-contain" />
            <div className="min-w-0 flex-1">
              <p className="m-0 truncate text-base font-bold">{trip.bus}</p>
              <p className={`m-0 line-clamp-2 text-xs ${stale ? "text-warn" : "text-muted"}`}>{status}</p>
            </div>
            {eta && myStop ? (
              <div className="text-right" aria-label={`${copy.etaLabel}: ${eta.minutes === 0 ? copy.etaArriving : format(copy.etaMinutes, { minutes: eta.minutes })}. ${format(copy.etaCaption, { km: number.format(eta.kilometres), stop: myStop.name })}`}>
                <p aria-hidden className="m-0 text-2xl font-extrabold tracking-tight text-accent">
                  {eta.minutes === 0 ? copy.etaArriving : format(copy.etaMinutes, { minutes: eta.minutes })}
                </p>
                <p aria-hidden className="m-0 text-xs text-muted">
                  {format(copy.distanceKm, { km: number.format(eta.kilometres) })}
                </p>
              </div>
            ) : null}
          </div>
          {walk ? (
            <p className="relative m-0 flex items-center gap-2 text-xs font-semibold">
              <span className="text-info">
                <Icon icon={WalkingIcon} size={18} />
              </span>
              {walk.metres >= 1000 ? format(copy.me.walkKm, { distance: number.format(walk.metres / 1000), minutes: walk.minutes }) : format(copy.me.walkM, { distance: Math.round(walk.metres / 10) * 10, minutes: walk.minutes })}
            </p>
          ) : null}
          {myStop && !eta ? (
            <p className="relative m-0 flex items-center gap-2 text-xs font-semibold">
              <span className="text-accent">
                <Icon icon={Flag02Icon} size={18} />
              </span>
              {copy.yourStop}: {myStop.name}
            </p>
          ) : null}
          <div className="relative">
            <UpdatesFold
              count={updates.length}
              latest={newest && newestText ? { text: newestText, icon: updateIcon(newest.kind) } : null}
              title={copy.updatesTitle}
              toggle={format(copy.updatesToggle, { count: updates.length })}
            >
              <UpdateList updates={updates} copy={copy} bus={trip.bus} direction={direction} now={now} locale={locale} />
            </UpdatesFold>
          </div>
        </section>
      </div>

      <BusLegend open={legend} onClose={() => setLegend(false)} copy={copy.legend} />
      <Modal
        open={me.kind === "asking"}
        onClose={() => setMe({ kind: "off" })}
        title={copy.me.whyTitle}
        description={copy.me.whyBody}
        actions={
          <div className="flex flex-wrap justify-end gap-2">
            <Button variant="ghost" onClick={() => setMe({ kind: "off" })}>
              {copy.me.notNow}
            </Button>
            <Button onClick={() => setMe({ kind: "on", at: null })}>{copy.me.continue}</Button>
          </div>
        }
      />
    </div>
  );
}
