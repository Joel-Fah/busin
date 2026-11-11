"use client";

import { useCallback, useMemo, useState, useTransition } from "react";
import { Route01Icon } from "@hugeicons/core-free-icons";

import { previewRoute, type RoutePreview } from "@/app/(admin)/insights/actions";
import { Button } from "@/components/ui/Button";

import { InsightsHeader } from "@/components/insights/InsightsHeader";
import { MapView } from "@/components/map/MapView";
import type { MapCircle, MapLine, MapMarker } from "@/components/map/types";
import { NavDock } from "@/components/nav/NavDock";
import { Chip, type ChipTone } from "@/components/ui/Chip";
import type { LatLng } from "@/lib/geo";
import { format, type Messages } from "@/lib/i18n/messages";
import type { MapProviderId } from "@/lib/map/config";
import { compareRoutes, formatKm, formatMinutes, type Extra, type RouteOverlay } from "@/lib/route";
import { routeOnMap } from "@/components/insights/route-overlay";
import { roughDistance } from "@/lib/proximity";
import { suggestionPosition, type Suggestion, type SuggestionStop } from "@/lib/suggestions";

type Props = {
  /** The school's bus route, drawn under everything (null without one). */
  route?: RouteOverlay | null;
  suggestions: Suggestion[];
  stops: SuggestionStop[];
  failed: boolean;
  map: { provider: MapProviderId; styleUrl: string; accessToken: string; center: LatLng; zoom: number };
  t: Messages;
};

// The dock covers about the bottom 45% of the map; fitting and gliding keep the stops above it.
const DOCK_SHARE = 0.45;

const TONE: Record<Suggestion["kind"], ChipTone> = { new_stop: "accent", close_pair: "warn", unused: "neutral" };

/**
 * The Suggestions view of Insights: short sentences with the number behind them (a new stop near a named place, two
 * stops very close, a stop nobody uses), each also on the map: a large orange ring for a new stop, a line between two
 * close stops, a grey ring on an unused one. Selecting a sentence glides the map there. The page says plainly what a
 * suggestion does not know; nothing changes by itself.
 */
export function SuggestionsExplorer({ route, suggestions, stops, failed, map, t }: Props) {
  const s = t.insights;
  const g = s.suggestions;
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [focus, setFocus] = useState<LatLng | null>(null);
  const [focusKey, setFocusKey] = useState(0);

  const distance = useCallback(
    (meters: number) => {
      const rough = roughDistance(meters);
      return format(rough.unit === "m" ? s.proximity.aboutM : s.proximity.aboutKm, { value: rough.value });
    },
    [s.proximity],
  );

  const sentence = useCallback(
    (item: Suggestion): string => {
      switch (item.kind) {
        case "new_stop":
          return format(g.newStop, { place: item.place, count: item.students, distance: distance(item.metres) });
        case "close_pair":
          return format(g.closePair, { a: item.a.name, b: item.b.name, distance: distance(item.metres), count: item.students });
        case "unused":
          return format(g.unused, { stop: item.stop.name, weeks: item.weeks, count: item.students });
      }
    },
    [g, distance],
  );

  // A suggested route: the school's route with one suggested stop (or every one) put in where it detours least, drawn
  // over today's route; along the roads when the road service answers, estimated from straight lines otherwise.
  const [compare, setCompare] = useState<{ key: string; extras: Extra[]; students: number; road: RoutePreview | null } | null>(null);
  const [drawing, startDrawing] = useTransition();
  const showRoute = useCallback(
    (key: string, extras: Extra[], students: number) => {
      if (!route || extras.length === 0) return;
      setCompare({ key, extras, students, road: null });
      startDrawing(async () => {
        const road = await previewRoute(
          route.stopIds,
          extras.map((e) => ({ lat: e.position.lat, lng: e.position.lng, name: e.name, after: e.after })),
        );
        setCompare((c) => (c && c.key === key ? { ...c, road } : c));
      });
    },
    [route],
  );
  const placeable = useMemo(
    () => suggestions.flatMap((s) => (s.kind === "new_stop" && s.insertAfter !== null ? [s] : [])),
    [suggestions],
  );

  const pick = useCallback(
    (item: Suggestion) => {
      setSelectedId(item.id);
      const at = suggestionPosition(item);
      if (at) {
        setFocus(at);
        setFocusKey((key) => key + 1);
      }
      if (item.kind === "new_stop" && item.insertAfter !== null) {
        showRoute(item.id, [{ name: item.place, position: item.position, after: item.insertAfter }], item.students);
      } else {
        setCompare(null);
      }
    },
    [showRoute],
  );

  // The figures of the comparison: road against road when both exist, otherwise estimate against estimate.
  const comparison = useMemo(
    () => (compare && route ? compareRoutes(route, compare.extras, compare.road?.status === "ok" ? compare.road : null) : null),
    [compare, route],
  );

  const markers = useMemo<MapMarker[]>(
    () => stops.flatMap((stop) => (stop.position ? [{ id: stop.id, position: stop.position, label: stop.name }] : [])),
    [stops],
  );
  const circles = useMemo<MapCircle[]>(
    () =>
      suggestions.flatMap((item): MapCircle[] => {
        if (item.kind === "new_stop") return [{ id: item.id, position: item.position, size: 1, color: "var(--accent)" }];
        if (item.kind === "unused" && item.stop.position) return [{ id: item.id, position: item.stop.position, size: 0.4, color: "var(--muted)" }];
        return [];
      }),
    [suggestions],
  );
  const lines = useMemo<MapLine[]>(
    () =>
      suggestions.flatMap((item): MapLine[] =>
        item.kind === "close_pair" && item.a.position && item.b.position ? [{ id: item.id, from: item.a.position, to: item.b.position, size: 0.6, color: "var(--warn)" }] : [],
      ),
    [suggestions],
  );

  const onRoute = useMemo(() => routeOnMap(route, t.route.campusBadge), [route, t.route.campusBadge]);
  return (
    <>
      <div className="fixed inset-0 z-0">
        <MapView
          provider={map.provider}
          styleUrl={map.styleUrl}
          accessToken={map.accessToken}
          center={map.center}
          zoom={map.zoom}
          markers={onRoute.campus.length > 0 ? [...markers, ...onRoute.campus] : markers}
          routes={
            comparison && route
              ? [
                  { id: "today", coordinates: route.line, emphasis: "secondary" },
                  { id: "suggested", coordinates: comparison.line, emphasis: "primary" },
                ]
              : onRoute.routes
          }
          circles={circles}
          lines={lines}
          focus={focus}
          focusKey={focusKey}
          focusZoom={compare ? 12.5 : undefined}
          clusterLabel={t.stops.cluster}
          clustering={false}
          coveredBottom={DOCK_SHARE}
          ariaLabel={g.mapLabel}
          unavailableLabel={s.mapUnavailable}
          className="map-full"
        />
      </div>

      <NavDock>
        <section aria-label={s.title} className="flex flex-col gap-3">
          <InsightsHeader view="suggestions" help={g.help} t={t} />

          {failed ? (
            <p role="alert" className="rounded-sm bg-bad-bg px-3 py-2 text-sm text-bad">
              {s.loadError}
            </p>
          ) : null}

          <div className="flex flex-wrap items-start justify-between gap-2">
            <p className="m-0 max-w-3xl text-sm text-muted">{route ? g.limits : `${g.limits} ${g.noRoute}`}</p>
            {route && placeable.length > 1 ? (
              <Button
                type="button"
                variant="secondary"
                icon={Route01Icon}
                onClick={() => {
                  setSelectedId(null);
                  showRoute(
                    "all",
                    placeable.map((s) => ({ name: s.place, position: s.position, after: s.insertAfter! })),
                    placeable.reduce((sum, s) => sum + s.students, 0),
                  );
                }}
              >
                {g.compareAll}
              </Button>
            ) : null}
          </div>

          {suggestions.length === 0 ? (
            <p className="py-2 text-sm font-semibold text-fg">{g.empty}</p>
          ) : (
            <ul
              aria-label={g.listLabel}
              className="-mx-4 m-0 flex list-none snap-x snap-mandatory gap-3 overflow-x-auto overflow-y-hidden px-4 pt-1 pb-3 [scroll-padding-inline:1rem]"
            >
              {suggestions.map((item) => {
                const selected = item.id === selectedId;
                return (
                  <li key={item.id} className="w-72 shrink-0 snap-start">
                    <button
                      type="button"
                      aria-pressed={selected}
                      onClick={() => pick(item)}
                      className={
                        "flex h-full min-h-[6rem] w-full cursor-pointer flex-col items-start gap-2 rounded-md border-0 p-3.5 text-left font-sans " +
                        "transition-[background-color,box-shadow] duration-(--dur) ease-soft focus-visible:outline-3 focus-visible:outline-focus " +
                        (selected ? "bg-[color-mix(in_srgb,var(--accent)_20%,var(--surface))] shadow-[inset_0_0_0_2px_var(--accent)]" : "bg-surface-2 hover:bg-line")
                      }
                    >
                      <Chip tone={TONE[item.kind]}>{g.kinds[item.kind]}</Chip>
                      <span className="text-sm font-semibold text-fg">{sentence(item)}</span>
                    </button>
                  </li>
                );
              })}
            </ul>
          )}

          {comparison ? (
            <section aria-label={g.compareTitle} aria-busy={drawing} className="flex flex-col gap-3 rounded-md bg-surface-2 p-4">
              <div className="flex flex-wrap items-center gap-2">
                <h2 className="m-0 text-base font-bold">{compare?.key === "all" ? g.compareAllTitle : g.compareTitle}</h2>
                <Chip tone="ok">{format(g.gain, { count: compare?.students ?? 0 })}</Chip>
                <Chip tone={comparison.deltaD > 0 ? "warn" : "ok"}>
                  {Math.abs(comparison.deltaD) < 50 ? g.sameLength : format(comparison.deltaD > 0 ? g.longer : g.shorter, { distance: formatKm(Math.abs(comparison.deltaD)) })}
                </Chip>
                {Math.abs(comparison.deltaT) >= 30 ? (
                  <Chip tone={comparison.deltaT > 0 ? "warn" : "ok"}>{format(comparison.deltaT > 0 ? g.slower : g.faster, { time: formatMinutes(Math.abs(comparison.deltaT)) })}</Chip>
                ) : null}
                <button type="button" onClick={() => setCompare(null)} className="ml-auto cursor-pointer rounded-sm border-0 bg-transparent px-2 py-1 font-sans text-sm font-semibold text-muted hover:text-fg focus-visible:outline-3 focus-visible:outline-focus">
                  {g.compareClose}
                </button>
              </div>
              <p className="m-0 text-xs text-muted">
                {g.compareLegend} {drawing ? g.drawing : comparison.byRoad ? g.byRoad : g.estimated}
              </p>
              <details>
                <summary className="cursor-pointer text-sm font-semibold">
                  {format(g.directions, { distance: formatKm(comparison.total.d), time: formatMinutes(comparison.total.t) })}
                </summary>
                <ol aria-label={g.compareTitle} className="m-0 mt-2 flex max-h-48 list-none flex-col gap-1.5 overflow-y-auto p-0 pr-2">
                  {comparison.steps.map((step, i) => (
                    <li key={`${step.from}-${i}`} className="text-sm">
                      {i === 0 ? <span className="block">{format(t.route.leave, { from: step.from })}</span> : null}
                      <span className="text-muted">{format(t.route.leg, { distance: formatKm(step.distanceM), time: formatMinutes(step.durationS), to: step.to })}</span>
                    </li>
                  ))}
                </ol>
              </details>
            </section>
          ) : null}
        </section>
      </NavDock>
    </>
  );
}
