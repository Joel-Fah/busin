"use client";

import { Location01Icon, Navigation03Icon } from "@hugeicons/core-free-icons";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useRef, useState } from "react";

import { MapView } from "@/components/map/MapView";
import type { MapMarker } from "@/components/map/types";
import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { Modal } from "@/components/ui/Modal";
import { Notice } from "@/components/ui/Notice";
import { parsePoint, type LatLng } from "@/lib/geo";
import { format } from "@/lib/i18n/format";
import type { StudentCopy } from "@/lib/i18n/student";
import type { MapConfig } from "@/lib/map/config";
import { BusUpdateDetector, STALE_AFTER_MS, estimateEta, walkToStop, type BusUpdate, type Position, type StopPoint } from "@/lib/student/bus";
import { browserClient } from "@/lib/supabase/browser";
import { Contour } from "@/components/ui/Contour";

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
};

type Me = { kind: "off" } | { kind: "asking" } | { kind: "on"; at: LatLng | null } | { kind: "problem"; text: string };

/**
 * My bus, as in the app: the running buses as choices, a live map with the followed bus, the student's stop and the
 * other stops, the estimated arrival at their stop, one short update at a time, and Show me (ADR 0016). Positions come
 * through Realtime, only for the followed bus and only while the tab is visible; RLS lets only a subscriber read them.
 */
export function BusTracker({ copy, locale, map, trips, stops, myStop, initial }: Props) {
  const router = useRouter();
  const [chosen, setChosen] = useState<string | null>(trips[0]?.id ?? null);
  const trip = trips.find((t) => t.id === chosen) ?? trips[0] ?? null;
  const [positions, setPositions] = useState<Record<string, Position>>(initial);
  const [update, setUpdate] = useState<BusUpdate | null>(null);
  const [now, setNow] = useState(() => Date.now());
  const [liveFailed, setLiveFailed] = useState(false);
  const [me, setMe] = useState<Me>({ kind: "off" });
  const [focusKey, setFocusKey] = useState(0);
  const detector = useRef<BusUpdateDetector | null>(null);
  const followed = useRef<RunningTrip | null>(null);

  const position = trip ? positions[trip.busId] ?? null : null;

  // A new detector for each followed trip; the trip ending is said before the next one is followed.
  useEffect(() => {
    if (followed.current && followed.current.id !== trip?.id && !trips.some((t) => t.id === followed.current!.id) && detector.current) {
      setUpdate(detector.current.onTripEnded(Date.now()));
    }
    followed.current = trip;
    detector.current = trip ? new BusUpdateDetector(stops, myStop) : null;
    const first = trip ? positions[trip.busId] : undefined;
    if (first && detector.current) setUpdate(detector.current.onPosition(first, Date.now()));
    // Positions are read once here on purpose: later ones arrive through the channel below.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [trip?.id]);

  // Live positions of the followed bus, while the tab is visible.
  useEffect(() => {
    if (!trip) return;
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
        .channel(`live:${trip.busId}`)
        .on("postgres_changes", { event: "*", schema: "public", table: "live_positions", filter: `bus_id=eq.${trip.busId}` }, (payload) => {
          const row = payload.new as { trip_id?: string | null; location?: unknown; speed_mps?: number | null; recorded_at?: string } | null;
          const at = row ? parsePoint(row.location) : null;
          if (!row || !at || !row.recorded_at) return;
          const next: Position = { tripId: row.trip_id ?? null, position: at, speedMps: row.speed_mps ?? null, recordedAt: Date.parse(row.recorded_at) };
          setPositions((all) => ({ ...all, [trip.busId]: next }));
          const said = detector.current?.onPosition(next, Date.now());
          if (said) setUpdate(said);
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
  }, [trip, router]);

  // The clock for "updated ... ago" and "no signal"; the list of running trips is read again every minute.
  useEffect(() => {
    const tick = window.setInterval(() => {
      const at = Date.now();
      setNow(at);
      const said = detector.current?.onTick(at);
      if (said) setUpdate(said);
    }, 10_000);
    const reload = window.setInterval(() => {
      if (document.visibilityState === "visible") router.refresh();
    }, 60_000);
    return () => {
      window.clearInterval(tick);
      window.clearInterval(reload);
    };
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

  const markers = useMemo<MapMarker[]>(() => {
    const list: MapMarker[] = stops.map((stop) => ({ id: `stop-${stop.id}`, position: stop.position, label: stop.name, muted: stop.id !== myStop?.id, selected: stop.id === myStop?.id }));
    if (myStop && !stops.some((s) => s.id === myStop.id)) list.push({ id: `stop-${myStop.id}`, position: myStop.position, label: `${copy.yourStop}: ${myStop.name}`, selected: true });
    if (trip && position) list.push({ id: `bus-${trip.busId}`, position: position.position, label: trip.bus, variant: "bus" });
    if (me.kind === "on" && me.at) list.push({ id: "me", position: me.at, label: copy.me.you, variant: "me" });
    return list;
  }, [stops, myStop, trip, position, me, copy.yourStop, copy.me.you]);

  if (!trip) return null;

  const age = position ? now - position.recordedAt : null;
  const stale = age !== null && age >= STALE_AFTER_MS;
  const eta = position && myStop ? estimateEta(position.position, myStop.position, position.speedMps) : null;
  const number = new Intl.NumberFormat(locale, { maximumFractionDigits: 1 });
  const updateText = update
    ? format(copy.updates[update.kind], {
        bus: trip.bus,
        direction: copy.directions[trip.direction],
        stop: update.stopName ?? "",
        minutes: update.minutes ?? Math.max(1, Math.round((now - (update.since ?? now)) / 60_000)),
      })
    : null;
  const walk = me.kind === "on" && me.at && myStop ? walkToStop(me.at, myStop.position) : null;

  return (
    <div className="flex flex-col gap-4">
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

      <div className="relative h-[52dvh] min-h-80 overflow-hidden rounded-lg shadow-soft">
        <MapView
          provider={map.provider}
          styleUrl={map.styleUrl}
          center={position?.position ?? myStop?.position ?? map.fallbackCenter}
          zoom={map.fallbackZoom}
          markers={markers}
          focus={position?.position ?? null}
          focusKey={focusKey}
          clustering={false}
          ariaLabel={copy.map}
          unavailableLabel={copy.mapUnavailable}
          className="map-full"
        />
        {position ? (
          <div className="absolute right-3 bottom-3">
            <Button variant="secondary" icon={Navigation03Icon} onClick={() => setFocusKey((k) => k + 1)}>
              {copy.recenter}
            </Button>
          </div>
        ) : null}
      </div>

      {liveFailed ? <Notice tone="warn">{copy.liveFailed}</Notice> : null}

      <section className="flex flex-col gap-3 relative rounded-lg bg-surface p-5 shadow-soft" aria-live="polite" data-testid="bus-status">
        <Contour radius={28} inset={10} />
        <p className="m-0 text-sm font-semibold text-muted">
          {trip.bus} · {copy.directions[trip.direction]}
        </p>
        {!position ? (
          <p className="m-0">{copy.waiting}</p>
        ) : stale ? (
          <Notice tone="warn">{format(copy.stale, { minutes: Math.round(age! / 60_000) })}</Notice>
        ) : (
          <>
            {eta && myStop ? (
              <div>
                <p className="m-0 text-sm text-muted">{copy.etaLabel}</p>
                <p className="m-0 text-4xl font-extrabold tracking-tight">{eta.minutes === 0 ? copy.etaArriving : format(copy.etaMinutes, { minutes: eta.minutes })}</p>
                <p className="m-0 text-sm text-muted">{format(copy.etaCaption, { km: number.format(eta.kilometres), stop: myStop.name })}</p>
              </div>
            ) : null}
            <p className="m-0 text-xs text-muted">
              {age !== null && age < 60_000 ? format(copy.updatedSeconds, { seconds: Math.max(1, Math.round(age / 1000)) }) : format(copy.updatedMinutes, { minutes: Math.round((age ?? 0) / 60_000) })}
              {position.speedMps !== null ? ` · ${format(copy.speed, { kmh: Math.round(position.speedMps * 3.6) })}` : ""}
            </p>
          </>
        )}
      </section>

      <section className="flex flex-col gap-2 relative rounded-lg bg-surface p-5 shadow-soft" aria-labelledby="updates-title">
        <Contour radius={28} inset={10} />
        <h2 id="updates-title" className="m-0 text-base font-bold">
          {copy.updatesTitle}
        </h2>
        <p className="m-0" data-testid="bus-update">
          {updateText ?? <span className="text-muted">{copy.updatesEmpty}</span>}
        </p>
      </section>

      {myStop ? (
        <section className="flex flex-col gap-3 relative rounded-lg bg-surface p-5 shadow-soft">
          <Contour radius={28} inset={10} />
          {me.kind === "problem" ? <Notice tone="warn">{me.text}</Notice> : null}
          {walk ? (
            <p className="m-0 flex items-center gap-2 text-sm">
              <Icon icon={Location01Icon} size={18} />
              {walk.metres >= 1000 ? format(copy.me.walkKm, { distance: number.format(walk.metres / 1000), minutes: walk.minutes }) : format(copy.me.walkM, { distance: Math.round(walk.metres / 10) * 10, minutes: walk.minutes })}
            </p>
          ) : null}
          <Button variant="secondary" icon={Location01Icon} onClick={() => setMe(me.kind === "on" ? { kind: "off" } : { kind: "asking" })}>
            {me.kind === "on" ? copy.me.hide : copy.me.show}
          </Button>
        </section>
      ) : null}

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
