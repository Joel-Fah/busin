"use client";

import { useActionState, useCallback, useMemo, useState } from "react";
import {
  Add01Icon,
  ArrowRight01Icon,
  Cancel01Icon,
  FlagTriangleRightIcon,
  Edit02Icon,
  Gps01Icon,
  Location01Icon,
  Search01Icon,
} from "@hugeicons/core-free-icons";

import { saveStop, type SaveStopState } from "@/app/(admin)/stops/actions";
import { MapView } from "@/components/map/MapView";
import type { MapMarker } from "@/components/map/types";
import { NavDock } from "@/components/nav/NavDock";
import { Button } from "@/components/ui/Button";
import { Switch } from "@/components/ui/Choice";
import { Chip } from "@/components/ui/Chip";
import { HelpSheet } from "@/components/ui/HelpSheet";
import { Icon } from "@/components/ui/Icon";
import { Input } from "@/components/ui/Input";
import { SideSheet } from "@/components/ui/SideSheet";
import { distanceMeters, formatDistance, isValidLatLng, type LatLng } from "@/lib/geo";
import { format, type Messages } from "@/lib/i18n/messages";
import type { MapProviderId } from "@/lib/map/config";
import { MAX_STOP_NAME_LENGTH, parseCoordinate } from "@/lib/stops";
import type { StopRow } from "@/lib/stops-data";

type Props = {
  stops: StopRow[];
  failed: boolean;
  map: { provider: MapProviderId; styleUrl: string; accessToken: string; center: LatLng; zoom: number };
  /** Open the sheet on arrival: to add a stop, or to edit the one with this id. */
  initialSheet: "new" | { edit: string } | null;
  t: Messages;
};

type Sheet = { mode: "new" } | { mode: "edit"; id: string };
type Draft = { name: string; lat: string; lng: string; active: boolean };
type Notice = { text: string; bad?: boolean };

const BLANK: Draft = { name: "", lat: "", lng: "", active: true };

const toDraft = (stop: StopRow): Draft => ({
  name: stop.name,
  lat: stop.position ? stop.position.lat.toFixed(6) : "",
  lng: stop.position ? stop.position.lng.toFixed(6) : "",
  active: stop.active,
});

function draftPosition(draft: Draft): LatLng | null {
  const lat = parseCoordinate(draft.lat);
  const lng = parseCoordinate(draft.lng);
  return lat !== null && lng !== null && isValidLatLng(lat, lng) ? { lat, lng } : null;
}

const ICON_BUTTON =
  "inline-flex shrink-0 cursor-pointer items-center justify-center rounded-sm border-0 bg-transparent text-muted transition-colors duration-(--dur-fast) " +
  "hover:bg-surface-2 hover:text-fg focus-visible:outline-3 focus-visible:outline-focus disabled:cursor-wait disabled:opacity-60";

/**
 * The Stops page: the map fills the screen, the stops sit in the navigation bar's dock as tiles that
 * scroll sideways, and a floating sheet adds or edits one beside the map. "View all stops" splits the
 * screen, three parts map to one part list, for a longer list with search. Zoomed out, stops that would
 * overlap become numbered bubbles. The visitor can show where they are, which adds a distance to each
 * stop; the position stays in the browser. Everything happens on this one page, so it costs one map load.
 */
export function StopsExplorer({ stops, failed, map, initialSheet, t }: Props) {
  const s = t.stops;
  const f = s.form;

  const startSheet: Sheet | null =
    initialSheet === "new" ? { mode: "new" } : initialSheet && stops.some((stop) => stop.id === initialSheet.edit) ? { mode: "edit", id: initialSheet.edit } : null;
  const startStop = startSheet?.mode === "edit" ? stops.find((stop) => stop.id === startSheet.id) : undefined;

  const [sheet, setSheet] = useState<Sheet | null>(startSheet);
  const [draft, setDraft] = useState<Draft>(startStop ? toDraft(startStop) : BLANK);
  const [selectedId, setSelectedId] = useState<string | null>(startStop?.id ?? null);
  const [focus, setFocus] = useState<LatLng | null>(startStop?.position ?? null);
  const [focusKey, setFocusKey] = useState(0);
  const [notice, setNotice] = useState<Notice | null>(null);
  const [me, setMe] = useState<LatLng | null>(null);
  const [locating, setLocating] = useState(false);
  const [split, setSplit] = useState(false);
  const [query, setQuery] = useState("");

  const [result, formAction, pending] = useActionState(
    async (previous: SaveStopState, formData: FormData): Promise<SaveStopState> => {
      const outcome = await saveStop(previous, formData);
      if (outcome.status === "saved") {
        setSheet(null);
        setSelectedId(outcome.id);
        setNotice({ text: outcome.created ? s.done.created : s.done.saved });
      }
      return outcome;
    },
    { status: "idle" },
  );

  const editing = sheet?.mode === "edit" ? sheet.id : null;
  const pinned = sheet ? draftPosition(draft) : null;
  // The tiles step aside while a sheet or the full list needs the room.
  const tilesOpen = sheet === null && !split;

  const distances = useMemo(() => {
    const result = new Map<string, number>();
    if (me) for (const stop of stops) if (stop.position) result.set(stop.id, distanceMeters(me, stop.position));
    return result;
  }, [me, stops]);

  // Nearest first once the visitor's position is known; otherwise by name, as loaded.
  const ordered = useMemo(
    () => (me ? [...stops].sort((a, b) => (distances.get(a.id) ?? Infinity) - (distances.get(b.id) ?? Infinity)) : stops),
    [me, stops, distances],
  );
  const shown = useMemo(() => {
    const needle = query.trim().toLowerCase();
    return needle ? ordered.filter((stop) => stop.name.toLowerCase().includes(needle)) : ordered;
  }, [ordered, query]);

  // Glide to a position, every time it is asked for, even if the map is already centred there or was panned away.
  const flyTo = useCallback((position: LatLng) => {
    setFocus(position);
    setFocusKey((key) => key + 1);
  }, []);

  function openNew() {
    setDraft(BLANK);
    setSheet({ mode: "new" });
    setNotice(null);
  }

  function openEdit(stop: StopRow) {
    setDraft(toDraft(stop));
    setSheet({ mode: "edit", id: stop.id });
    setSelectedId(stop.id);
    if (stop.position) flyTo(stop.position);
    setNotice(null);
  }

  const pick = useCallback(
    (stop: StopRow) => {
      setSelectedId(stop.id);
      if (stop.position) flyTo(stop.position);
    },
    [flyTo],
  );

  // Asked for on purpose, with a button: the browser then asks for permission. The position is only kept in
  // this page. Pressing it again always brings the map back to where the visitor is now: it glides to the
  // last known position at once, then to the fresh one when the browser answers.
  function locate() {
    if (!navigator.geolocation) {
      setNotice({ text: s.location.unsupported, bad: true });
      return;
    }
    if (me) flyTo(me);
    setLocating(true);
    if (!me) setNotice({ text: s.location.finding });
    navigator.geolocation.getCurrentPosition(
      (position) => {
        const here = { lat: position.coords.latitude, lng: position.coords.longitude };
        setMe(here);
        flyTo(here);
        setLocating(false);
        setNotice(null);
      },
      () => {
        setLocating(false);
        setNotice({ text: s.location.failed, bad: true });
      },
      // Once the visitor is known, ask for a fresh reading instead of a remembered one.
      { enableHighAccuracy: false, timeout: 10_000, maximumAge: me ? 0 : 60_000 },
    );
  }

  // While the sheet is open the stop being edited is shown as the draggable pin, not as a second marker.
  const markers = useMemo<MapMarker[]>(() => {
    const list: MapMarker[] = stops.flatMap((stop) =>
      stop.position && stop.id !== editing
        ? [
            {
              id: stop.id,
              position: stop.position,
              label: stop.name,
              muted: !stop.active,
              selected: stop.id === selectedId,
              onSelect: sheet ? undefined : () => pick(stop),
            },
          ]
        : [],
    );
    if (me) list.push({ id: "me", position: me, label: s.location.you, variant: "me" });
    return list;
  }, [stops, editing, selectedId, sheet, me, s.location.you, pick]);

  const distanceOf = (stop: StopRow) => {
    const meters = distances.get(stop.id);
    return meters === undefined ? "" : formatDistance(meters);
  };

  return (
    <>
      <div
        className={
          "fixed z-0 overflow-hidden transition-[top,right,bottom,left,border-radius,box-shadow] duration-(--dur-slow) ease-soft motion-reduce:transition-none " +
          (split ? "shadow-float" : "shadow-none")
        }
        // Full screen, or a rounded card that shrinks from every side to make room for the list.
        style={
          split
            ? { top: "1rem", left: "1rem", bottom: "calc(var(--nav-height, 0px) + 2rem)", right: "calc(max(25%, 22rem) + 0.5rem)", borderRadius: "var(--r-xl)" }
            : { top: 0, left: 0, bottom: 0, right: 0, borderRadius: 0 }
        }
      >
        <MapView
          provider={map.provider}
          styleUrl={map.styleUrl}
          accessToken={map.accessToken}
          center={map.center}
          zoom={map.zoom}
          markers={markers}
          focus={focus}
          focusKey={focusKey}
          clusterLabel={s.cluster}
          picker={
            sheet
              ? { position: pinned, onChange: (position) => setDraft((d) => ({ ...d, lat: position.lat.toFixed(6), lng: position.lng.toFixed(6) })) }
              : undefined
          }
          ariaLabel={s.mapLabel}
          unavailableLabel={s.mapUnavailable}
          className="map-full"
        />
      </div>

      {split ? (
        <aside
          aria-label={s.panel.title}
          className="fixed top-4 right-4 bottom-[calc(var(--nav-height,0px)+2rem)] z-20 flex w-[calc(max(25vw,22rem)-2rem)] animate-[panel-in_var(--dur-slow)_var(--ease-soft)] flex-col gap-4 px-1 max-md:left-4 max-md:w-auto"
        >
          <div className="flex items-start justify-between gap-3">
            <div>
              <h2 className="text-xl font-extrabold tracking-tight">{s.panel.title}</h2>
              <p className="text-sm text-muted">
                {format(s.dockCount, { count: stops.length })}
                {me ? ` · ${s.panel.nearest}` : ""}
              </p>
              {me ? <p className="text-xs text-muted">{s.location.approx}</p> : null}
            </div>
            <button type="button" aria-label={s.panel.close} data-tip={s.panel.close} onClick={() => setSplit(false)} className={`${ICON_BUTTON} size-10`}>
              <Icon icon={Cancel01Icon} size={20} />
            </button>
          </div>

          <Input
            id="stops-search"
            type="search"
            label={s.panel.search}
            icon={Search01Icon}
            placeholder={s.panel.searchPlaceholder}
            autoComplete="off"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />

          {me ? null : (
            <button
              type="button"
              onClick={locate}
              disabled={locating}
              className="flex cursor-pointer items-center gap-3 rounded-md border-0 bg-surface-2 px-4 py-3 text-left font-sans text-sm font-semibold text-fg transition-colors duration-(--dur-fast) hover:bg-line disabled:cursor-wait"
            >
              <Icon icon={Gps01Icon} size={20} />
              <span className="flex flex-col">
                {s.location.show}
                <span className="text-xs font-normal text-muted">{s.location.privacy}</span>
              </span>
            </button>
          )}

          {shown.length === 0 ? (
            <p className="py-6 text-center text-sm text-muted">{stops.length === 0 ? s.empty : s.panel.noMatch}</p>
          ) : (
            <ul aria-label={s.panel.title} className="m-0 -mr-2 flex min-h-0 flex-1 list-none flex-col gap-1 overflow-y-auto p-0 pr-2">
              {shown.map((stop) => {
                const selected = stop.id === selectedId;
                const distance = distanceOf(stop);
                return (
                  <li key={stop.id} className="flex items-center gap-1">
                    <button
                      type="button"
                      aria-pressed={selected}
                      onClick={() => pick(stop)}
                      className={
                        "flex min-w-0 flex-1 cursor-pointer flex-col items-start gap-1.5 rounded-sm border-0 px-3.5 py-3 text-left font-sans " +
                        "transition-colors duration-(--dur-fast) focus-visible:outline-3 focus-visible:outline-focus " +
                        (selected ? "bg-[color-mix(in_srgb,var(--accent)_20%,var(--surface))]" : "bg-transparent hover:bg-surface-2")
                      }
                    >
                      <span className="flex w-full items-center justify-between gap-2">
                        <span className="truncate text-sm font-bold text-fg">{stop.name}</span>
                        <Chip tone={stop.active ? "ok" : "neutral"}>{stop.active ? s.status.active : s.status.inactive}</Chip>
                      </span>
                      {distance ? (
                        <span className="text-xs text-muted">
                          {distance} {s.location.away}
                        </span>
                      ) : null}
                    </button>
                    <button type="button" aria-label={format(s.editStop, { name: stop.name })} data-tip={format(s.editStop, { name: stop.name })} onClick={() => openEdit(stop)} className={`${ICON_BUTTON} size-9`}>
                      <Icon icon={Edit02Icon} size={18} />
                    </button>
                  </li>
                );
              })}
            </ul>
          )}
        </aside>
      ) : null}

      <NavDock>
        <section aria-label={s.title} className="flex flex-col gap-3">
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-extrabold tracking-tight sm:text-3xl">{s.title}</h1>
            <HelpSheet
              label={t.help.open}
              title={s.help.title}
              intro={s.help.intro}
              scenarios={Object.values(s.help.scenarios)}
              scenariosLabel={t.help.scenarios}
              closeLabel={t.help.close}
            />
            <div className="ml-auto flex items-center gap-2">
              <button
                type="button"
                aria-label={s.location.show}
                data-tip={`${s.location.show}. ${s.location.privacy}`}
                aria-pressed={me !== null}
                aria-busy={locating}
                disabled={locating}
                onClick={locate}
                className={`${ICON_BUTTON} size-11 ${me ? "bg-surface-2 text-info" : ""}`}
              >
                <Icon icon={Gps01Icon} size={22} />
              </button>
              <Button icon={Add01Icon} onClick={openNew}>
                {s.add}
              </Button>
            </div>
          </div>

          {notice ? (
            <p role={notice.bad ? "alert" : "status"} className={`rounded-sm px-3 py-2 text-sm ${notice.bad ? "bg-bad-bg text-bad" : "bg-ok-bg font-semibold text-ok"}`}>
              {notice.text}
            </p>
          ) : null}

          {failed ? (
            <p role="alert" className="rounded-sm bg-bad-bg px-3 py-2 text-sm text-bad">
              {s.loadError}
            </p>
          ) : stops.length === 0 ? (
            <p className="py-4 text-center text-sm text-muted">{s.empty}</p>
          ) : (
            <div
              inert={!tilesOpen}
              className={
                "grid transition-[grid-template-rows,opacity,visibility] duration-500 ease-soft motion-reduce:transition-none " +
                (tilesOpen ? "visible grid-rows-[1fr] opacity-100" : "invisible grid-rows-[0fr] opacity-0")
              }
            >
              <div className="overflow-hidden">
                <ul
                  aria-label={s.dockTitle}
                  className="-mx-4 m-0 flex list-none snap-x snap-mandatory gap-3 overflow-x-auto overflow-y-hidden px-4 pt-1 pb-3 [scroll-padding-inline:1rem]"
                >
                  {ordered.map((stop) => {
                    const selected = stop.id === selectedId;
                    const distance = distanceOf(stop);
                    return (
                      <li key={stop.id} className="w-52 shrink-0 snap-start">
                        {/* Two rows: the name and its edit icon, then the status and the distance. */}
                        <div
                          className={
                            "grid h-full min-h-[5.5rem] grid-cols-[minmax(0,1fr)_auto] rounded-md transition-[background-color,box-shadow] duration-(--dur) ease-soft " +
                            (selected ? "bg-[color-mix(in_srgb,var(--accent)_20%,var(--surface))] shadow-[inset_0_0_0_2px_var(--accent)]" : "bg-surface-2 hover:bg-line")
                          }
                        >
                          <button
                            type="button"
                            aria-pressed={selected}
                            data-tip={stop.name}
                            onClick={() => pick(stop)}
                            className="col-start-1 row-span-2 row-start-1 flex min-w-0 cursor-pointer flex-col justify-between gap-3 rounded-md border-0 bg-transparent p-3.5 text-left font-sans focus-visible:outline-3 focus-visible:outline-focus"
                          >
                            <span className="truncate pr-1 text-sm font-bold text-fg">{stop.name}</span>
                            <span className="flex items-center gap-2">
                              <Chip tone={stop.active ? "ok" : "neutral"}>{stop.active ? s.status.active : s.status.inactive}</Chip>
                              {distance ? (
                                <span className="text-xs font-semibold text-muted" data-tip={s.location.approx}>
                                  {distance}
                                  <span className="sr-only"> {s.location.away}</span>
                                </span>
                              ) : null}
                            </span>
                          </button>
                          <button
                            type="button"
                            aria-label={format(s.editStop, { name: stop.name })}
                            data-tip={format(s.editStop, { name: stop.name })}
                            onClick={() => openEdit(stop)}
                            className={`${ICON_BUTTON} col-start-2 row-start-1 m-1.5 size-9 hover:bg-surface`}
                          >
                            <Icon icon={Edit02Icon} size={18} />
                          </button>
                        </div>
                      </li>
                    );
                  })}

                  <li className="w-52 shrink-0 snap-start">
                    <button
                      type="button"
                      onClick={() => setSplit(true)}
                      className="grid h-full min-h-[5.5rem] w-full cursor-pointer grid-cols-[minmax(0,1fr)_auto] items-start gap-x-2 gap-y-2 rounded-md border-2 border-dashed border-line bg-transparent p-3.5 text-left font-sans transition-colors duration-(--dur) ease-soft hover:bg-surface-2 focus-visible:outline-3 focus-visible:outline-focus"
                    >
                      <span className="truncate text-sm font-bold text-fg">{s.viewAll}</span>
                      <span className="inline-flex size-6 items-center justify-center text-muted">
                        <Icon icon={ArrowRight01Icon} size={20} />
                      </span>
                      <span className="col-span-2 self-end text-xs text-muted">{format(s.viewAllCount, { count: stops.length })}</span>
                    </button>
                  </li>
                </ul>
              </div>
            </div>
          )}
        </section>
      </NavDock>

      <SideSheet
        open={sheet !== null}
        onClose={() => setSheet(null)}
        title={sheet?.mode === "edit" ? s.sheet.editTitle : s.sheet.addTitle}
        closeLabel={t.help.close}
        modal={false}
      >
        <form action={formAction} key={sheet ? `${sheet.mode}-${editing ?? "new"}` : "closed"} className="flex flex-col gap-5">
          {editing ? <input type="hidden" name="id" value={editing} /> : null}
          <p className="text-sm text-muted">{s.sheet.placing}</p>

          <Input
            id="stop-name"
            name="name"
            label={f.name}
            icon={FlagTriangleRightIcon}
            required
            maxLength={MAX_STOP_NAME_LENGTH}
            autoComplete="off"
            hint={f.nameHint}
            value={draft.name}
            onChange={(event) => setDraft((d) => ({ ...d, name: event.target.value }))}
          />

          <div className="grid gap-3 sm:grid-cols-2">
            <Input
              id="stop-lat"
              name="lat"
              label={f.latitude}
              icon={Location01Icon}
              inputMode="decimal"
              autoComplete="off"
              value={draft.lat}
              onChange={(event) => setDraft((d) => ({ ...d, lat: event.target.value }))}
            />
            <Input
              id="stop-lng"
              name="lng"
              label={f.longitude}
              icon={Location01Icon}
              inputMode="decimal"
              autoComplete="off"
              value={draft.lng}
              onChange={(event) => setDraft((d) => ({ ...d, lng: event.target.value }))}
            />
          </div>

          <Switch
            name="active"
            label={f.active}
            hint={f.activeHint}
            checked={draft.active}
            onChange={(event) => setDraft((d) => ({ ...d, active: event.target.checked }))}
          />

          {result.status === "error" ? (
            <p role="alert" className="rounded-sm bg-bad-bg px-3.5 py-2.5 text-sm text-bad">
              {s.errors[result.error]}
            </p>
          ) : null}

          <Button type="submit" disabled={pending}>
            {editing ? f.save : f.create}
          </Button>
        </form>
      </SideSheet>
    </>
  );
}
