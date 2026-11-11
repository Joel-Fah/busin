"use client";

import { useMemo, useState, useTransition } from "react";
import Link from "next/link";
import { Add01Icon, ArrowDown01Icon, ArrowLeft01Icon, ArrowUp01Icon, Cancel01Icon, Location01Icon, Route01Icon, School01Icon } from "@hugeicons/core-free-icons";

import { drawRoute, saveCampus, saveRouteOrder } from "@/app/(admin)/stops/route/actions";
import { MapView } from "@/components/map/MapView";
import type { MapMarker, MapRoute } from "@/components/map/types";
import { NavDock } from "@/components/nav/NavDock";
import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { Input } from "@/components/ui/Input";
import type { LatLng } from "@/lib/geo";
import { format, type Messages } from "@/lib/i18n/messages";
import type { MapProviderId } from "@/lib/map/config";
import { directions, formatKm, formatMinutes, move, routeLine, type BusRoute, type RouteStop } from "@/lib/route";

type Props = {
  route: BusRoute;
  stops: RouteStop[];
  failed: boolean;
  map: { provider: MapProviderId; styleUrl: string; accessToken: string; center: LatLng; zoom: number };
  t: Messages;
};

type Notice = { text: string; bad?: boolean };

const ICON_BUTTON =
  "inline-flex shrink-0 cursor-pointer items-center justify-center rounded-sm border-0 bg-transparent text-muted transition-colors duration-(--dur-fast) " +
  "hover:bg-surface-2 hover:text-fg focus-visible:outline-3 focus-visible:outline-focus disabled:cursor-default disabled:opacity-35";

/**
 * The school's bus route (ADR 0017): the campus where it ends, the stops in the order the bus picks students up, and the
 * stop-by-stop directions. The map fills the screen; the panel on the right holds the order (move with the buttons or
 * add and remove stops), the campus (placed on the map) and the directions. Saving the order, then "Draw along roads",
 * stores the road; until then the route is drawn straight between stops and the directions are estimates.
 */
export function RouteEditor({ route, stops, failed, map, t }: Props) {
  const r = t.route;
  const byId = useMemo(() => new Map(stops.map((s) => [s.id, s])), [stops]);
  const savedOrder = useMemo(() => route.stops.filter((s) => byId.has(s.id)).map((s) => s.id), [route.stops, byId]);
  const [order, setOrder] = useState<string[]>(savedOrder);
  const [campusName, setCampusName] = useState(route.campus?.name ?? "");
  const [campusPoint, setCampusPoint] = useState<LatLng | null>(route.campus?.position ?? null);
  const [placing, setPlacing] = useState(false);
  const [notice, setNotice] = useState<Notice | null>(null);
  const [busy, startTransition] = useTransition();

  const changed = order.join(",") !== savedOrder.join(",");
  const campusChanged =
    campusName.trim() !== (route.campus?.name ?? "") ||
    campusPoint?.lat !== route.campus?.position.lat ||
    campusPoint?.lng !== route.campus?.position.lng;
  const ordered = useMemo(() => order.flatMap((id) => (byId.has(id) ? [byId.get(id)!] : [])), [order, byId]);
  const others = useMemo(() => stops.filter((s) => !order.includes(s.id)), [stops, order]);

  // What the map and the directions show: the saved road while nothing changed, else straight lines and estimates.
  const dirty = changed || campusChanged;
  const shown = useMemo<BusRoute>(
    () =>
      dirty
        ? { ...route, stops: ordered, campus: campusPoint ? { name: campusName || r.campus, position: campusPoint } : null, road: null, legs: [], current: false, distanceM: null, durationS: null }
        : route,
    [dirty, route, ordered, campusPoint, campusName, r.campus],
  );
  const steps = directions(shown);
  const total = steps.reduce((acc, s) => ({ d: acc.d + s.distanceM, t: acc.t + s.durationS }), { d: 0, t: 0 });

  const markers = useMemo<MapMarker[]>(() => {
    const list: MapMarker[] = ordered.map((s, i) => ({ id: s.id, position: s.position, label: `${i + 1}. ${s.name}`, badge: String(i + 1) }));
    for (const s of others) list.push({ id: s.id, position: s.position, label: format(r.notOnRoute, { name: s.name }), muted: true });
    if (campusPoint) list.push({ id: "campus", position: campusPoint, label: campusName || r.campus, variant: "campus", badge: r.campusBadge });
    return list;
  }, [ordered, others, campusPoint, campusName, r]);
  const routes = useMemo<MapRoute[]>(() => [{ id: "route", coordinates: routeLine(shown), emphasis: "primary" }], [shown]);

  const run = (job: () => Promise<{ status: string; error?: string }>, ok: string) =>
    startTransition(async () => {
      const result = await job();
      setNotice(result.status === "error" ? { text: r.errors[(result.error ?? "failed") as keyof typeof r.errors] ?? r.errors.failed, bad: true } : { text: ok });
    });

  return (
    <>
      <div className="fixed top-0 bottom-0 left-0 z-0 right-0 lg:right-[min(28rem,34vw)]">
        <MapView
          provider={map.provider}
          styleUrl={map.styleUrl}
          accessToken={map.accessToken}
          center={map.center}
          zoom={map.zoom}
          markers={markers}
          routes={routes}
          clustering={false}
          coveredBottom={0.3}
          picker={placing ? { position: campusPoint, onChange: setCampusPoint } : undefined}
          clusterLabel={t.stops.cluster}
          ariaLabel={r.mapLabel}
          unavailableLabel={t.stops.mapUnavailable}
          className="map-full"
        />
      </div>

      <aside
        aria-label={r.panel}
        className="fixed top-4 right-4 bottom-[calc(var(--nav-height,0px)+2rem)] z-20 flex w-[min(26rem,calc(100vw-2rem))] flex-col gap-5 overflow-y-auto rounded-xl bg-surface p-5 shadow-float max-lg:top-auto max-lg:max-h-[45vh]"
      >
        <section aria-labelledby="route-campus" className="flex flex-col gap-3">
          <h2 id="route-campus" className="m-0 flex items-center gap-2 text-base font-bold">
            <Icon icon={School01Icon} size={18} />
            {r.campusTitle}
          </h2>
          <p className="m-0 text-xs text-muted">{r.campusHint}</p>
          <Input id="campus-name" label={r.campusName} icon={School01Icon} value={campusName} maxLength={80} onChange={(e) => setCampusName(e.target.value)} />
          <div className="flex flex-wrap gap-2">
            <Button type="button" variant="secondary" icon={Location01Icon} aria-pressed={placing} onClick={() => setPlacing((p) => !p)}>
              {placing ? r.placeDone : campusPoint ? r.placeMove : r.place}
            </Button>
            <Button
              type="button"
              disabled={busy || !campusPoint || !campusName.trim() || !campusChanged}
              onClick={() => campusPoint && run(() => saveCampus(campusPoint.lat, campusPoint.lng, campusName), r.done.campus)}
            >
              {r.saveCampus}
            </Button>
          </div>
        </section>

        <section aria-labelledby="route-order" className="flex flex-col gap-2">
          <h2 id="route-order" className="m-0 flex items-center gap-2 text-base font-bold">
            <Icon icon={Route01Icon} size={18} />
            {r.orderTitle}
          </h2>
          <p className="m-0 text-xs text-muted">{r.orderHint}</p>
          {ordered.length === 0 ? <p className="m-0 rounded-md bg-surface-2 p-3 text-sm text-muted">{r.orderEmpty}</p> : null}
          <ol aria-label={r.orderTitle} className="m-0 flex list-none flex-col gap-1 p-0">
            {ordered.map((s, i) => (
              <li key={s.id} className="flex items-center gap-2 rounded-md bg-surface-2 py-1.5 pr-1.5 pl-3">
                <span className="grid size-6 shrink-0 place-items-center rounded-full bg-accent text-xs font-extrabold text-on-accent">{i + 1}</span>
                <span className="min-w-0 flex-1 truncate text-sm font-semibold">{s.name}</span>
                <button type="button" className={`${ICON_BUTTON} size-8`} aria-label={format(r.up, { name: s.name })} data-tip={format(r.up, { name: s.name })} disabled={i === 0} onClick={() => setOrder((o) => move(o, i, i - 1))}>
                  <Icon icon={ArrowUp01Icon} size={16} />
                </button>
                <button
                  type="button"
                  className={`${ICON_BUTTON} size-8`}
                  aria-label={format(r.down, { name: s.name })}
                  data-tip={format(r.down, { name: s.name })}
                  disabled={i === ordered.length - 1}
                  onClick={() => setOrder((o) => move(o, i, i + 1))}
                >
                  <Icon icon={ArrowDown01Icon} size={16} />
                </button>
                <button type="button" className={`${ICON_BUTTON} size-8`} aria-label={format(r.remove, { name: s.name })} data-tip={format(r.remove, { name: s.name })} onClick={() => setOrder((o) => o.filter((x) => x !== s.id))}>
                  <Icon icon={Cancel01Icon} size={16} />
                </button>
              </li>
            ))}
          </ol>
          {others.length > 0 ? (
            <details className="rounded-md bg-surface-2 px-3 py-2">
              <summary className="cursor-pointer text-sm font-semibold">{format(r.addTitle, { count: others.length })}</summary>
              <ul className="m-0 mt-2 flex list-none flex-col gap-1 p-0">
                {others.map((s) => (
                  <li key={s.id} className="flex items-center justify-between gap-2">
                    <span className="truncate text-sm">{s.name}</span>
                    <button type="button" className={`${ICON_BUTTON} size-8`} aria-label={format(r.add, { name: s.name })} data-tip={format(r.add, { name: s.name })} onClick={() => setOrder((o) => [...o, s.id])}>
                      <Icon icon={Add01Icon} size={16} />
                    </button>
                  </li>
                ))}
              </ul>
            </details>
          ) : null}
          <div className="flex flex-wrap gap-2 pt-1">
            <Button type="button" disabled={busy || !changed || order.length === 0} onClick={() => run(() => saveRouteOrder(order), r.done.order)}>
              {r.saveOrder}
            </Button>
            <Button type="button" variant="secondary" icon={Route01Icon} disabled={busy || changed || campusChanged || order.length === 0 || !route.campus} onClick={() => run(drawRoute, r.done.drawn)}>
              {r.draw}
            </Button>
          </div>
        </section>

        {notice ? (
          <p role={notice.bad ? "alert" : "status"} className={`m-0 rounded-sm px-3 py-2 text-sm ${notice.bad ? "bg-bad-bg text-bad" : "bg-ok-bg font-semibold text-ok"}`}>
            {notice.text}
          </p>
        ) : null}
        {failed ? (
          <p role="alert" className="m-0 rounded-sm bg-bad-bg px-3 py-2 text-sm text-bad">
            {r.loadError}
          </p>
        ) : null}

        {steps.length > 0 ? (
          <section aria-labelledby="route-directions" className="flex flex-col gap-2">
            <h2 id="route-directions" className="m-0 text-base font-bold">
              {r.directionsTitle}
            </h2>
            <p className="m-0 text-sm text-fg">
              {format(r.total, { distance: formatKm(total.d), time: formatMinutes(total.t) })}
              <span className="block text-xs text-muted">{shown.current ? r.byRoad : r.estimated}</span>
            </p>
            <ol aria-label={r.directionsTitle} className="m-0 flex list-none flex-col p-0">
              {steps.map((step, i) => (
                <li key={`${step.from}-${i}`} className="relative flex gap-3 pb-3 pl-1">
                  <span aria-hidden className="mt-1.5 size-2.5 shrink-0 rounded-full bg-info" />
                  <span className="text-sm">
                    {i === 0 ? format(r.leave, { from: step.from }) : null}
                    <span className="block text-muted">{format(r.leg, { distance: formatKm(step.distanceM), time: formatMinutes(step.durationS), to: step.to })}</span>
                  </span>
                </li>
              ))}
            </ol>
          </section>
        ) : null}
      </aside>

      <NavDock
        label={r.title}
        labels={t.nav}
        header={
          <div className="flex flex-wrap items-center gap-3">
            <Link href="/stops" className={`${ICON_BUTTON} size-10`} aria-label={r.back} data-tip={r.back}>
              <Icon icon={ArrowLeft01Icon} size={20} />
            </Link>
            <h1 className="m-0 text-2xl font-extrabold tracking-tight sm:text-3xl">{r.title}</h1>
            <p className="m-0 text-sm text-muted">{route.campus ? format(r.summary, { count: ordered.length, campus: route.campus.name }) : r.noCampus}</p>
          </div>
        }
      />
    </>
  );
}
