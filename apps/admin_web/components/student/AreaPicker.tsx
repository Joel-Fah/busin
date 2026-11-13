"use client";

import { Home01Icon, Location01Icon, Search01Icon } from "@hugeicons/core-free-icons";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";

import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { Input } from "@/components/ui/Input";
import { Modal } from "@/components/ui/Modal";
import { Notice } from "@/components/ui/Notice";
import { useToast } from "@/components/ui/Toast";
import { format } from "@/lib/i18n/format";
import type { StudentCopy } from "@/lib/i18n/student";
import { roundCoordinate } from "@/lib/student/area";
import { browserClient } from "@/lib/supabase/browser";

type Place = { kind: string; label: string; lat: number; lng: number };
type Chosen = { lat: number; lng: number; label: string; source: "device" | "search" };

/**
 * My area (ADR 0013), as in the app: search a neighbourhood or street, or, at home, one reading of the browser's
 * location, rounded here before it is sent. A browser cannot ask for an approximate position only, so the rounding is
 * done before saving. The student names it and saves; they can remove it.
 */
export function AreaPicker({ copy, current }: { copy: StudentCopy["area"]; current: string | null }) {
  const router = useRouter();
  const toast = useToast();
  const [query, setQuery] = useState("");
  const [places, setPlaces] = useState<Place[] | null>(null);
  const [chosen, setChosen] = useState<Chosen | null>(null);
  const [name, setName] = useState("");
  const [asking, setAsking] = useState(false);
  const [problem, setProblem] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    const q = query.trim();
    if (q.length < 2) return;
    const timer = window.setTimeout(async () => {
      const { data, error } = await browserClient().rpc("search_places", { p_query: q, p_limit: 8 });
      if (error) {
        setProblem(error.code === "PT429" ? copy.tooMany : copy.error);
        return;
      }
      setProblem(null);
      setPlaces(data ?? []);
    }, 400);
    return () => window.clearTimeout(timer);
  }, [query, copy.tooMany, copy.error]);

  const choose = (place: Chosen) => {
    setChosen(place);
    setName(place.label);
  };

  const readLocation = () => {
    setAsking(false);
    setProblem(null);
    navigator.geolocation.getCurrentPosition(
      (p) => choose({ lat: roundCoordinate(p.coords.latitude), lng: roundCoordinate(p.coords.longitude), label: copy.defaultName, source: "device" }),
      (error) => setProblem(error.code === error.PERMISSION_DENIED ? copy.denied : copy.failed),
      { enableHighAccuracy: false, timeout: 20_000, maximumAge: 600_000 },
    );
  };

  const save = async () => {
    if (!chosen) return;
    setBusy(true);
    const { error } = await browserClient().rpc("set_my_area", { p_lat: chosen.lat, p_lng: chosen.lng, p_label: name.trim() || copy.defaultName, p_source: chosen.source });
    setBusy(false);
    if (error) {
      setProblem(error.message.includes("too_far") ? copy.tooFar : copy.error);
      return;
    }
    toast(copy.saved, { tone: "ok" });
    setChosen(null);
    setQuery("");
    setPlaces(null);
    router.refresh();
  };

  const remove = async () => {
    setBusy(true);
    const { error } = await browserClient().rpc("clear_my_area");
    setBusy(false);
    if (error) {
      setProblem(copy.error);
      return;
    }
    toast(copy.removed, { tone: "ok" });
    router.refresh();
  };

  return (
    <div className="flex flex-col gap-4">
      {current ? (
        <section className="flex items-center gap-4 rounded-lg bg-surface p-5 shadow-soft">
          <span className="grid size-11 shrink-0 place-items-center rounded-sm bg-seed text-white">
            <Icon icon={Home01Icon} size={20} />
          </span>
          <div className="min-w-0 flex-1">
            <p className="m-0 font-bold">{format(copy.current, { label: current })}</p>
            <p className="m-0 text-sm text-muted">{copy.rounded}</p>
          </div>
        </section>
      ) : null}

      {problem ? <Notice tone="warn">{problem}</Notice> : null}

      {chosen ? (
        <section className="flex flex-col gap-4 rounded-lg bg-surface p-5 shadow-soft">
          <Input id="area-name" label={copy.nameLabel} placeholder={copy.nameHint} icon={Home01Icon} value={name} onChange={(event) => setName(event.target.value)} maxLength={60} />
          <p className="m-0 text-sm text-muted">{copy.rounded}</p>
          <div className="flex flex-wrap gap-2">
            <Button onClick={save} disabled={busy}>
              {copy.save}
            </Button>
            <Button variant="ghost" onClick={() => setChosen(null)}>
              {copy.cancel}
            </Button>
          </div>
        </section>
      ) : (
        <>
          <section className="flex flex-col gap-3 rounded-lg bg-surface p-5 shadow-soft">
            <Input id="area-search" type="search" label={copy.search} icon={Search01Icon} value={query} onChange={(event) => setQuery(event.target.value)} autoComplete="off" />
            {places !== null && query.trim().length >= 2 ? (
              places.length === 0 ? (
                <p className="m-0 text-sm text-muted">{copy.searchEmpty}</p>
              ) : (
                <ul className="m-0 flex list-none flex-col gap-1 p-0">
                  {places.map((place) => (
                    <li key={`${place.label}-${place.lat}-${place.lng}`}>
                      <button
                        type="button"
                        onClick={() => choose({ lat: place.lat, lng: place.lng, label: place.label, source: "search" })}
                        className="flex w-full cursor-pointer items-center gap-3 rounded-sm border-0 bg-transparent px-3 py-3 text-left font-sans text-fg hover:bg-surface-2 focus-visible:outline-3 focus-visible:outline-focus"
                      >
                        <Icon icon={Location01Icon} size={18} className="text-muted" />
                        <span className="min-w-0">
                          <span className="block font-semibold">{place.label}</span>
                          <span className="block text-xs text-muted">{copy.kinds[place.kind as keyof typeof copy.kinds] ?? place.kind}</span>
                        </span>
                      </button>
                    </li>
                  ))}
                </ul>
              )
            ) : null}
            <p className="m-0 text-xs text-muted">{copy.osm}</p>
          </section>
          <section className="flex flex-col gap-3 rounded-lg bg-surface p-5 shadow-soft">
            <p className="m-0 font-bold">{copy.atHome}</p>
            <Button variant="secondary" icon={Location01Icon} onClick={() => setAsking(true)}>
              {copy.useLocation}
            </Button>
          </section>
        </>
      )}

      {current && !chosen ? (
        <Button variant="danger" onClick={remove} disabled={busy}>
          {copy.remove}
        </Button>
      ) : null}

      <Modal
        open={asking}
        onClose={() => setAsking(false)}
        title={copy.explainTitle}
        description={copy.explainBody}
        actions={
          <div className="flex flex-wrap justify-end gap-2">
            <Button variant="ghost" onClick={() => setAsking(false)}>
              {copy.cancel}
            </Button>
            <Button onClick={readLocation}>{copy.continue}</Button>
          </div>
        }
      />
    </div>
  );
}
