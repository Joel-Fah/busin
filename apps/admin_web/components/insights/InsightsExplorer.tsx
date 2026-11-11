"use client";

import { useActionState, useCallback, useMemo, useState } from "react";
import { RefreshIcon } from "@hugeicons/core-free-icons";

import { refreshLoads, type RefreshState } from "@/app/(admin)/insights/actions";
import { MapView } from "@/components/map/MapView";
import type { MapCircle, MapMarker } from "@/components/map/types";
import { NavDock } from "@/components/nav/NavDock";
import { Button } from "@/components/ui/Button";
import { Chip, type ChipTone } from "@/components/ui/Chip";
import { HelpSheet } from "@/components/ui/HelpSheet";
import { Tabs } from "@/components/ui/Tabs";
import type { LatLng } from "@/lib/geo";
import { format, type Messages } from "@/lib/i18n/messages";
import { circleSize, formatAverage, formatShare, LOAD_PERIODS, type LoadLevel, type LoadPeriod, type StopLoad, type StopLoads } from "@/lib/insights";
import type { MapProviderId } from "@/lib/map/config";

type Props = {
  loads: StopLoads;
  period: LoadPeriod;
  failed: boolean;
  /** When the boardings were last counted, already written for the school's time zone. */
  counted: string | null;
  /** Each stop's last day ("2026-11-10"), already written ("10 Nov"). */
  days: Record<string, string>;
  map: { provider: MapProviderId; styleUrl: string; accessToken: string; center: LatLng; zoom: number };
  t: Messages;
};

const LEVELS: LoadLevel[] = ["quiet", "fair", "busy", "full"];

/** Each level has a tone (chips) and the matching theme colour (the circles). Never colour alone: the level is written too. */
const TONE: Record<LoadLevel, ChipTone> = { quiet: "info", fair: "ok", busy: "warn", full: "bad" };
const COLOR: Record<LoadLevel, string> = { quiet: "var(--info)", fair: "var(--ok)", busy: "var(--warn)", full: "var(--bad)" };

/**
 * The Insights page: the map fills the screen with one circle per stop, larger and warmer the fuller the bus gets
 * there; the bar's dock holds the period, what the numbers are based on, a legend and the stops as tiles, fullest
 * first. A tile glides the map to its stop. Later insights (proximity, suggestions) join as more views.
 */
export function InsightsExplorer({ loads, period, failed, counted, days, map, t }: Props) {
  const s = t.insights;
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [focus, setFocus] = useState<LatLng | null>(null);
  const [focusKey, setFocusKey] = useState(0);
  const [refresh, refreshAction, refreshing] = useActionState(async (): Promise<RefreshState> => refreshLoads(), { status: "idle" });

  const byBoardings = loads.basis === "boardings";
  const totalBoardings = loads.stops.reduce((sum, stop) => sum + stop.boardings, 0);

  const pick = useCallback((stop: StopLoad) => {
    setSelectedId(stop.id);
    if (stop.position) {
      setFocus(stop.position);
      setFocusKey((key) => key + 1);
    }
  }, []);

  const describe = useCallback(
    (stop: StopLoad): string => {
      const share = stop.load === null ? "" : format(s.stop.share, { share: formatShare(stop.load) });
      if (!byBoardings) return [format(s.stop.students, { count: stop.students }), share].filter(Boolean).join(" · ");
      if (stop.departures === 0) return s.stop.none;
      return [format(s.stop.perDeparture, { count: formatAverage(stop.perDeparture) }), share].join(" · ");
    },
    [byBoardings, s],
  );

  const markers = useMemo<MapMarker[]>(
    () =>
      loads.stops.flatMap((stop) =>
        stop.position
          ? [
              {
                id: stop.id,
                position: stop.position,
                label: `${stop.name}: ${stop.level ? `${s.level[stop.level]}, ` : ""}${describe(stop)}`,
                muted: !stop.active,
                selected: stop.id === selectedId,
                onSelect: () => pick(stop),
              },
            ]
          : [],
      ),
    [loads.stops, selectedId, pick, describe, s.level],
  );

  const circles = useMemo<MapCircle[]>(
    () =>
      loads.stops.flatMap((stop) =>
        stop.position && stop.level ? [{ id: stop.id, position: stop.position, size: circleSize(stop.load), color: COLOR[stop.level] }] : [],
      ),
    [loads.stops],
  );

  const periodLabels: Record<LoadPeriod, string> = { 28: s.period.p28, 56: s.period.p56, 112: s.period.p112 };

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
          focus={focus}
          focusKey={focusKey}
          clusterLabel={t.stops.cluster}
          clustering={false}
          ariaLabel={s.mapLabel}
          unavailableLabel={s.mapUnavailable}
          className="map-full"
        />
      </div>

      <NavDock>
        <section aria-label={s.title} className="flex flex-col gap-3">
          <div className="flex flex-wrap items-center gap-2">
            <h1 className="text-2xl font-extrabold tracking-tight sm:text-3xl">{s.title}</h1>
            <HelpSheet
              label={t.help.open}
              title={s.help.title}
              intro={s.help.intro}
              scenarios={Object.values(s.help.scenarios)}
              scenariosLabel={t.help.scenarios}
              closeLabel={t.help.close}
            />
            <div className="ml-auto flex flex-wrap items-center gap-2">
              <Tabs label={s.views.label} items={[{ id: "load", label: s.views.load, href: "/insights" }]} active="load" />
              <Tabs
                label={s.period.label}
                items={LOAD_PERIODS.map((days) => ({ id: String(days), label: periodLabels[days], href: `/insights?days=${days}` }))}
                active={String(period)}
              />
              {byBoardings ? (
                <form action={refreshAction}>
                  <Button type="submit" variant="secondary" icon={RefreshIcon} disabled={refreshing} data-tip={s.refresh.hint}>
                    {s.refresh.button}
                  </Button>
                </form>
              ) : null}
            </div>
          </div>

          {refresh.status !== "idle" ? (
            <p role={refresh.status === "done" ? "status" : "alert"} className={`rounded-sm px-3 py-2 text-sm ${refresh.status === "done" ? "bg-ok-bg font-semibold text-ok" : "bg-bad-bg text-bad"}`}>
              {refresh.status === "done" ? s.refresh.done : refresh.status === "too_soon" ? s.refresh.too_soon : s.refresh.failed}
            </p>
          ) : null}

          {failed ? (
            <p role="alert" className="rounded-sm bg-bad-bg px-3 py-2 text-sm text-bad">
              {s.loadError}
            </p>
          ) : null}

          {loads.stops.length === 0 ? (
            <p className="py-4 text-center text-sm text-muted">{s.empty}</p>
          ) : (
            <>
              <div className="flex flex-col gap-1 text-sm text-muted">
                <p className="m-0">
                  {byBoardings
                    ? `${format(s.basis.boardings, { boardings: totalBoardings })}${counted ? ` ${format(s.basis.counted, { when: counted })}` : ""}`
                    : loads.seats > 0
                      ? format(s.basis.subscribers, { seats: loads.seats })
                      : s.basis.noSeats}
                </p>
                <ul aria-label={s.legend} className="m-0 flex list-none flex-wrap items-center gap-2 p-0">
                  {LEVELS.map((level) => (
                    <li key={level}>
                      <Chip tone={TONE[level]}>{s.levels[level]}</Chip>
                    </li>
                  ))}
                </ul>
              </div>

              <ul
                aria-label={s.listLabel}
                className="-mx-4 m-0 flex list-none snap-x snap-mandatory gap-3 overflow-x-auto overflow-y-hidden px-4 pt-1 pb-3 [scroll-padding-inline:1rem]"
              >
                {loads.stops.map((stop) => {
                  const selected = stop.id === selectedId;
                  return (
                    <li key={stop.id} className="w-60 shrink-0 snap-start">
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
                          {stop.level ? <Chip tone={TONE[stop.level]}>{s.level[stop.level]}</Chip> : null}
                        </span>
                        <span className="text-xs text-muted">{describe(stop)}</span>
                        {byBoardings && stop.departures > 0 ? (
                          <span className="text-xs text-muted">
                            {format(s.stop.peak, { count: stop.peak, share: formatShare(stop.peakLoad) })}
                            {" · "}
                            {format(s.stop.departures, { count: stop.departures })}
                            {stop.lastDay && days[stop.lastDay] ? ` · ${format(s.stop.lastDay, { day: days[stop.lastDay] })}` : ""}
                          </span>
                        ) : null}
                        {stop.active ? null : <span className="text-xs font-semibold text-muted">{s.stop.inactive}</span>}
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
