"use client";

import { useCallback, useMemo, useState } from "react";

import { InsightsHeader } from "@/components/insights/InsightsHeader";
import { MapView } from "@/components/map/MapView";
import type { MapCircle, MapLine, MapMarker } from "@/components/map/types";
import { NavDock } from "@/components/nav/NavDock";
import { Chip, type ChipTone } from "@/components/ui/Chip";
import type { LatLng } from "@/lib/geo";
import { format, type Messages } from "@/lib/i18n/messages";
import { formatShare } from "@/lib/insights";
import type { MapProviderId } from "@/lib/map/config";
import { lineSize, MIN_STUDENTS, roughDistance, type Proximity, type ProximityStop, type Reach } from "@/lib/proximity";

// The dock covers about the bottom 45% of the map; fitting and gliding keep the stops above it.
const DOCK_SHARE = 0.45;

type Props = {
  proximity: Proximity;
  failed: boolean;
  map: { provider: MapProviderId; styleUrl: string; accessToken: string; center: LatLng; zoom: number };
  t: Messages;
};

const REACHES: Reach[] = ["near", "walk", "far", "remote"];

/** Each band has a tone (chips, the bar) and the matching theme colour (the circles). The band is always written too. */
const TONE: Record<Reach, ChipTone> = { near: "ok", walk: "info", far: "warn", remote: "bad" };
const COLOR: Record<Reach, string> = { near: "var(--ok)", walk: "var(--info)", far: "var(--warn)", remote: "var(--bad)" };
const BAR: Record<Reach, string> = { near: "bg-ok", walk: "bg-info", far: "bg-warn", remote: "bg-bad" };

/**
 * The Proximity view of Insights: each stop's circle is coloured by how far its typical subscriber lives (the median),
 * and lines run from each zone where 5 or more of its students live to the stop, thicker for more. The dock lists the
 * stops, farthest first, with the bands. Figures need 5 students with an area behind them; no student is ever placed.
 */
export function ProximityExplorer({ proximity, failed, map, t }: Props) {
  const s = t.insights;
  const p = s.proximity;
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [focus, setFocus] = useState<LatLng | null>(null);
  const [focusKey, setFocusKey] = useState(0);

  const distance = useCallback(
    (meters: number) => {
      const rough = roughDistance(meters);
      return format(rough.unit === "m" ? p.aboutM : p.aboutKm, { value: rough.value });
    },
    [p],
  );

  const describe = useCallback(
    (stop: ProximityStop): string =>
      stop.median === null || stop.overOneKm === null
        ? format(p.notEnough, { count: stop.withArea, min: MIN_STUDENTS })
        : `${format(p.median, { distance: distance(stop.median) })} · ${format(p.overOneKm, { share: formatShare(stop.overOneKm) })}`,
    [p, distance],
  );

  const pick = useCallback((stop: ProximityStop) => {
    setSelectedId(stop.id);
    if (stop.position) {
      setFocus(stop.position);
      setFocusKey((key) => key + 1);
    }
  }, []);

  const markers = useMemo<MapMarker[]>(
    () =>
      proximity.stops.flatMap((stop) =>
        stop.position
          ? [{ id: stop.id, position: stop.position, label: `${stop.name}: ${describe(stop)}`, selected: stop.id === selectedId, onSelect: () => pick(stop) }]
          : [],
      ),
    [proximity.stops, selectedId, pick, describe],
  );

  const most = Math.max(MIN_STUDENTS, ...proximity.stops.map((stop) => stop.withArea));
  const circles = useMemo<MapCircle[]>(
    () =>
      proximity.stops.flatMap((stop) =>
        stop.position && stop.reach ? [{ id: stop.id, position: stop.position, size: Math.sqrt(stop.withArea / most), color: COLOR[stop.reach] }] : [],
      ),
    [proximity.stops, most],
  );

  const lines = useMemo<MapLine[]>(
    () => proximity.lines.map((line) => ({ id: line.id, from: line.from, to: line.to, size: lineSize(line.students), color: "var(--accent)" })),
    [proximity.lines],
  );

  const enough = proximity.stops.some((stop) => stop.median !== null);

  return (
    <>
      <div className="fixed inset-0 z-0">
        <MapView
          provider={map.provider}
          styleUrl={map.styleUrl}
          accessToken={map.accessToken}
          center={map.center}
          zoom={map.zoom}
          markers={markers}
          circles={circles}
          lines={lines}
          focus={focus}
          focusKey={focusKey}
          clusterLabel={t.stops.cluster}
          clustering={false}
          coveredBottom={DOCK_SHARE}
          ariaLabel={p.mapLabel}
          unavailableLabel={s.mapUnavailable}
          className="map-full"
        />
      </div>

      <NavDock>
        <section aria-label={s.title} className="flex flex-col gap-3">
          <InsightsHeader view="proximity" help={p.help} t={t} />

          {failed ? (
            <p role="alert" className="rounded-sm bg-bad-bg px-3 py-2 text-sm text-bad">
              {s.loadError}
            </p>
          ) : null}

          {proximity.stops.length === 0 ? (
            <p className="py-4 text-center text-sm text-muted">{s.empty}</p>
          ) : (
            <>
              <div className="flex flex-col gap-1 text-sm text-muted">
                <p className="m-0">
                  {format(p.basis, { withArea: proximity.withArea, subscribers: proximity.subscribers })} {p.straight}
                  {proximity.lines.length > 0 ? ` ${p.lines}` : ""}
                </p>
                {enough ? (
                  <ul aria-label={p.legend} className="m-0 flex list-none flex-wrap items-center gap-2 p-0">
                    {REACHES.map((reach) => (
                      <li key={reach}>
                        <Chip tone={TONE[reach]}>{p.bands[reach]}</Chip>
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p className="m-0 font-semibold text-fg">{format(p.noneYet, { min: MIN_STUDENTS })}</p>
                )}
              </div>

              <ul
                aria-label={p.listLabel}
                className="-mx-4 m-0 flex list-none snap-x snap-mandatory gap-3 overflow-x-auto overflow-y-hidden px-4 pt-1 pb-3 [scroll-padding-inline:1rem]"
              >
                {proximity.stops.map((stop) => {
                  const selected = stop.id === selectedId;
                  return (
                    <li key={stop.id} className="w-64 shrink-0 snap-start">
                      <button
                        type="button"
                        aria-pressed={selected}
                        onClick={() => pick(stop)}
                        className={
                          "flex h-full min-h-[6rem] w-full cursor-pointer flex-col justify-between gap-2 rounded-md border-0 p-3.5 text-left font-sans " +
                          "transition-[background-color,box-shadow] duration-(--dur) ease-soft focus-visible:outline-3 focus-visible:outline-focus " +
                          (selected ? "bg-[color-mix(in_srgb,var(--accent)_20%,var(--surface))] shadow-[inset_0_0_0_2px_var(--accent)]" : "bg-surface-2 hover:bg-line")
                        }
                      >
                        <span className="flex w-full items-center justify-between gap-2">
                          <span className="truncate text-sm font-bold text-fg">{stop.name}</span>
                          {stop.reach ? <Chip tone={TONE[stop.reach]}>{p.reach[stop.reach]}</Chip> : null}
                        </span>
                        <span className="text-xs text-muted">{describe(stop)}</span>
                        {stop.bands ? <Bands bands={stop.bands} total={stop.withArea} labels={p.bands} /> : null}
                        <span className="text-xs text-muted">{format(p.based, { withArea: stop.withArea, subscribers: stop.subscribers })}</span>
                      </button>
                    </li>
                  );
                })}
              </ul>
            </>
          )}
        </section>
      </NavDock>
    </>
  );
}

/** A thin bar split by band, with the counts written out for assistive technology. */
function Bands({ bands, total, labels }: { bands: [number, number, number, number]; total: number; labels: Record<Reach, string> }) {
  return (
    <span className="flex flex-col gap-1">
      <span aria-hidden className="flex h-1.5 w-full overflow-hidden rounded-xs bg-line">
        {REACHES.map((reach, index) => (bands[index] > 0 ? <span key={reach} className={BAR[reach]} style={{ width: `${(bands[index] / total) * 100}%` }} /> : null))}
      </span>
      <span className="sr-only">{REACHES.map((reach, index) => `${labels[reach]}: ${bands[index]}`).join(", ")}</span>
    </span>
  );
}
