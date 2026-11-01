import { MAX_CAPACITY, MAX_PLATE_LENGTH } from "@/lib/buses";
import type { Messages } from "@/lib/i18n/messages";

type Props = {
  action: (formData: FormData) => Promise<void>;
  t: Messages;
  bus?: { id: string; plate: string; capacity: number; inService: boolean };
};

/** The form used to add and to edit a bus. Server rendered; no client code needed. */
export function BusForm({ action, t, bus }: Props) {
  const f = t.buses.form;
  return (
    <form action={action} className="card stack">
      {bus ? <input type="hidden" name="id" value={bus.id} /> : null}

      <div className="field">
        <label htmlFor="plate">{f.plate}</label>
        <input
          id="plate"
          name="plate"
          type="text"
          required
          maxLength={MAX_PLATE_LENGTH}
          defaultValue={bus?.plate ?? ""}
          aria-describedby="plate-hint"
          autoComplete="off"
        />
        <span id="plate-hint" className="muted">
          {f.plateHint}
        </span>
      </div>

      <div className="field">
        <label htmlFor="capacity">{f.capacity}</label>
        <input
          id="capacity"
          name="capacity"
          type="number"
          inputMode="numeric"
          required
          min={1}
          max={MAX_CAPACITY}
          step={1}
          defaultValue={bus?.capacity ?? ""}
        />
      </div>

      <div className="field">
        <label className="check" htmlFor="in_service">
          <input id="in_service" name="in_service" type="checkbox" defaultChecked={bus?.inService ?? true} />
          <span>{f.inService}</span>
        </label>
        <span className="muted">{f.inServiceHint}</span>
      </div>

      <div className="row">
        <button type="submit" className="btn btn-primary">
          {bus ? f.save : f.create}
        </button>
      </div>
    </form>
  );
}
