import { StopLocationField } from "@/components/StopLocationField";
import type { LatLng } from "@/lib/geo";
import type { Messages } from "@/lib/i18n/messages";
import type { MapConfig } from "@/lib/map/config";
import { MAX_STOP_NAME_LENGTH } from "@/lib/stops";

type Props = {
  action: (formData: FormData) => Promise<void>;
  t: Messages;
  config: MapConfig;
  /** Where the map opens when the stop has no position yet. */
  center: LatLng;
  zoom: number;
  stop?: { id: string; name: string; active: boolean; position: LatLng | null };
};

/** The form used to add and to edit a stop. Server rendered; only the position field is interactive. */
export function StopForm({ action, t, config, center, zoom, stop }: Props) {
  const f = t.stops.form;
  return (
    <form action={action} className="card stack">
      {stop ? <input type="hidden" name="id" value={stop.id} /> : null}

      <div className="field">
        <label htmlFor="name">{f.name}</label>
        <input
          id="name"
          name="name"
          type="text"
          required
          maxLength={MAX_STOP_NAME_LENGTH}
          defaultValue={stop?.name ?? ""}
          aria-describedby="name-hint"
          autoComplete="off"
        />
        <span id="name-hint" className="muted">
          {f.nameHint}
        </span>
      </div>

      <StopLocationField
        initial={stop?.position ?? null}
        provider={config.provider}
        styleUrl={config.styleUrl}
        center={center}
        zoom={zoom}
        labels={{
          latitude: f.latitude,
          longitude: f.longitude,
          pickerLabel: f.pickerLabel,
          locationHint: f.locationHint,
          mapUnavailable: t.stops.mapUnavailable,
        }}
      />

      <div className="field">
        <label className="check" htmlFor="active">
          <input id="active" name="active" type="checkbox" defaultChecked={stop?.active ?? true} />
          <span>{f.active}</span>
        </label>
        <span className="muted">{f.activeHint}</span>
      </div>

      <div className="row">
        <button type="submit" className="btn btn-primary">
          {stop ? f.save : f.create}
        </button>
      </div>
    </form>
  );
}
