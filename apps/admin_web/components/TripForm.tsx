import { format, type Messages } from "@/lib/i18n/messages";
import { DIRECTIONS, type Direction } from "@/lib/trips";
import type { BusOption, DriverOption } from "@/lib/trips-data";

type Props = {
  action: (formData: FormData) => Promise<void>;
  t: Messages;
  buses: BusOption[];
  drivers: DriverOption[];
  /** The school's timezone, shown so the admin knows which clock the start time uses. */
  timeZone: string;
  trip?: { id: string; busId: string; driverId: string | null; direction: Direction; start: string };
};

/** The form used to schedule and to edit a trip. Server rendered; no client code needed. */
export function TripForm({ action, t, buses, drivers, timeZone, trip }: Props) {
  const f = t.trips.form;
  return (
    <form action={action} className="card stack">
      {trip ? <input type="hidden" name="id" value={trip.id} /> : null}

      <div className="field">
        <label htmlFor="bus_id">{f.bus}</label>
        <select id="bus_id" name="bus_id" required defaultValue={trip?.busId ?? ""}>
          <option value="" disabled>
            {f.choose}
          </option>
          {buses.map((bus) => (
            <option key={bus.id} value={bus.id}>
              {bus.plate}
              {bus.inService ? "" : ` (${f.outOfService})`}
            </option>
          ))}
        </select>
        {buses.length === 0 ? <span className="muted">{f.noBuses}</span> : null}
      </div>

      <div className="field">
        <label htmlFor="driver_id">{f.driver}</label>
        <select id="driver_id" name="driver_id" defaultValue={trip?.driverId ?? ""}>
          <option value="">{f.noDriver}</option>
          {drivers.map((driver) => (
            <option key={driver.id} value={driver.id}>
              {driver.name}
            </option>
          ))}
        </select>
        <span className="muted">{f.driverHint}</span>
      </div>

      <div className="field">
        <label htmlFor="direction">{f.direction}</label>
        <select id="direction" name="direction" required defaultValue={trip?.direction ?? "inbound"}>
          {DIRECTIONS.map((direction) => (
            <option key={direction} value={direction}>
              {t.trips.direction[direction]}
            </option>
          ))}
        </select>
      </div>

      <div className="field">
        <label htmlFor="scheduled_start">{f.start}</label>
        <input
          id="scheduled_start"
          name="scheduled_start"
          type="datetime-local"
          required
          defaultValue={trip?.start ?? ""}
          aria-describedby="start-hint"
        />
        <span id="start-hint" className="muted">
          {format(f.startHint, { zone: timeZone })}
        </span>
      </div>

      <div className="row">
        <button type="submit" className="btn btn-primary">
          {trip ? f.save : f.create}
        </button>
      </div>
    </form>
  );
}
