"use client";

import { useMemo, useState, useTransition } from "react";
import { Location01Icon, PencilEdit02Icon, Route01Icon, School01Icon } from "@hugeicons/core-free-icons";

import { saveCampus } from "@/app/(admin)/stops/route/actions";
import { MapView } from "@/components/map/MapView";
import { Button, ButtonLink } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { EmptyState } from "@/components/ui/EmptyState";
import { Input } from "@/components/ui/Input";
import { Notice } from "@/components/ui/Notice";
import { useToast } from "@/components/ui/Toast";
import { coordinateFields, MAX_CAMPUS_NAME_LENGTH, parseCampusFields, parseCampusPoint, type Campus } from "@/lib/campus";
import { formatLatLng, type LatLng } from "@/lib/geo";
import type { Messages } from "@/lib/i18n/messages";
import type { MapProviderId } from "@/lib/map/config";

type Props = {
  campus: Campus | null;
  map: { provider: MapProviderId; styleUrl: string; accessToken: string; center: LatLng; zoom: number };
  copy: Messages["school"]["campus"];
  /** The route editor's messages for what the database refuses (invalid_point, invalid_name, failed). */
  errors: Messages["route"]["errors"];
  mapUnavailable: string;
};

/**
 * The campus on the school profile (ADR 0017): where the bus route ends and where "arrived on campus" alerts fire.
 * Shows the name and coordinates (the map loads only while placing it, so the profile stays light); "Set" or "Change"
 * opens the same map picker and saves through the same action as the route editor.
 */
export function CampusCard({ campus, map, copy, errors, mapUnavailable }: Props) {
  const toast = useToast();
  const [editing, setEditing] = useState(false);
  const [name, setName] = useState(campus?.name ?? "");
  const [fields, setFields] = useState(coordinateFields(campus?.position ?? null));
  // Where the map glides to: only when coordinates are typed, not when the map itself is clicked.
  const [focus, setFocus] = useState<LatLng | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, startTransition] = useTransition();

  const parsed = parseCampusFields({ ...fields, name });
  const point = useMemo(() => parseCampusPoint(fields), [fields]);

  const open = () => {
    setName(campus?.name ?? "");
    setFields(coordinateFields(campus?.position ?? null));
    setFocus(null);
    setError(null);
    setEditing(true);
  };

  const typeCoordinate = (key: "lat" | "lng", value: string) => {
    const next = { ...fields, [key]: value };
    setFields(next);
    const typed = parseCampusPoint(next);
    if (typed) setFocus(typed);
  };

  const save = () => {
    if (!parsed.ok) {
      setError(errors[parsed.error]);
      return;
    }
    const { position, name: cleanName } = parsed.value;
    startTransition(async () => {
      const result = await saveCampus(position.lat, position.lng, cleanName);
      if (result.status === "error") {
        setError(errors[(result.error ?? "failed") as keyof typeof errors] ?? errors.failed);
        return;
      }
      setError(null);
      setEditing(false);
      toast(copy.done, { tone: "ok" });
    });
  };

  const header = (
    <div className="flex flex-wrap items-start justify-between gap-3">
      <div className="min-w-0">
        <h2 className="text-xl font-bold">{copy.title}</h2>
        <p className="mt-1 text-sm text-muted">{copy.hint}</p>
      </div>
      {campus && !editing ? (
        <ButtonLink href="/stops/route" variant="ghost" icon={Route01Icon}>
          {copy.route}
        </ButtonLink>
      ) : null}
    </div>
  );

  if (editing) {
    return (
      <Card className="flex flex-col gap-5">
        {header}
        <section aria-label={copy.title} className="flex flex-col gap-4">
          <Input
            id="campus-name"
            label={copy.name}
            icon={School01Icon}
            value={name}
            maxLength={MAX_CAMPUS_NAME_LENGTH}
            placeholder={copy.namePlaceholder}
            autoComplete="off"
            onChange={(event) => setName(event.target.value)}
          />
          <p className="m-0 text-sm text-muted">{copy.pickHint}</p>
          <MapView
            provider={map.provider}
            styleUrl={map.styleUrl}
            accessToken={map.accessToken}
            center={campus?.position ?? map.center}
            zoom={campus ? 15 : map.zoom}
            focus={focus}
            picker={{ position: point, onChange: (position) => setFields(coordinateFields(position)) }}
            clustering={false}
            ariaLabel={copy.pickLabel}
            unavailableLabel={mapUnavailable}
          />
          <div className="coords">
            <Input
              id="campus-lat"
              label={copy.latitude}
              icon={Location01Icon}
              inputMode="decimal"
              autoComplete="off"
              value={fields.lat}
              onChange={(event) => typeCoordinate("lat", event.target.value)}
            />
            <Input
              id="campus-lng"
              label={copy.longitude}
              icon={Location01Icon}
              inputMode="decimal"
              autoComplete="off"
              value={fields.lng}
              onChange={(event) => typeCoordinate("lng", event.target.value)}
            />
          </div>
          {error ? <Notice tone="bad">{error}</Notice> : null}
          <div className="flex flex-wrap gap-2">
            <Button type="button" disabled={busy} onClick={save}>
              {copy.save}
            </Button>
            <Button type="button" variant="secondary" disabled={busy} onClick={() => setEditing(false)}>
              {copy.cancel}
            </Button>
          </div>
        </section>
      </Card>
    );
  }

  if (!campus) {
    return (
      <Card className="flex flex-col gap-5">
        {header}
        <EmptyState
          title={copy.emptyTitle}
          body={copy.emptyBody}
          action={
            <Button type="button" icon={Location01Icon} onClick={open}>
              {copy.set}
            </Button>
          }
        />
      </Card>
    );
  }

  return (
    <Card className="flex flex-col gap-5">
      {header}
      <dl className="m-0 grid gap-4 sm:grid-cols-2">
        <div>
          <dt className="text-sm text-muted">{copy.name}</dt>
          <dd className="m-0 text-base font-semibold">{campus.name}</dd>
        </div>
        <div>
          <dt className="text-sm text-muted">{copy.coordinates}</dt>
          <dd className="m-0 font-mono text-sm">{formatLatLng(campus.position)}</dd>
        </div>
      </dl>
      <div>
        <Button type="button" variant="secondary" icon={PencilEdit02Icon} onClick={open}>
          {copy.change}
        </Button>
      </div>
    </Card>
  );
}
