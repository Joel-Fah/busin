"use client";

import { useCallback, useMemo, useState } from "react";

import { InsightsHeader } from "@/components/insights/InsightsHeader";
import { MapView } from "@/components/map/MapView";
import type { MapCircle, MapLine, MapMarker } from "@/components/map/types";
import { NavDock } from "@/components/nav/NavDock";
import { Chip, type ChipTone } from "@/components/ui/Chip";
import type { LatLng } from "@/lib/geo";
import { format, type Messages } from "@/lib/i18n/messages";
import type { MapProviderId } from "@/lib/map/config";
import { roughDistance } from "@/lib/proximity";
import { suggestionPosition, type Suggestion, type SuggestionStop } from "@/lib/suggestions";

type Props = {
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
export function SuggestionsExplorer({ suggestions, stops, failed, map, t }: Props) {
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

  const pick = useCallback((item: Suggestion) => {
    setSelectedId(item.id);
    const at = suggestionPosition(item);
    if (at) {
      setFocus(at);
      setFocusKey((key) => key + 1);
    }
  }, []);

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

          <p className="m-0 text-sm text-muted">{g.limits}</p>

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
        </section>
      </NavDock>
    </>
  );
}
