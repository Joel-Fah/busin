import { Bus01Icon, Navigation03Icon, UserIcon } from "@hugeicons/core-free-icons";

import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { DateTimePicker } from "@/components/ui/DateTimePicker";
import { Select } from "@/components/ui/Select";
import { format, type Locale, type Messages } from "@/lib/i18n/messages";
import { DIRECTIONS, type Direction } from "@/lib/trips";
import type { BusOption, DriverOption } from "@/lib/trips-data";

type Props = {
  action: (formData: FormData) => Promise<void>;
  t: Messages;
  locale: Locale;
  buses: BusOption[];
  drivers: DriverOption[];
  /** The school's timezone, shown so the admin knows which clock the start time is on. */
  timeZone: string;
  trip?: { id: string; busId: string; driverId: string | null; assistantId: string | null; direction: Direction; start: string };
};

/** The form used to schedule and to edit a trip. */
export function TripForm({ action, t, locale, buses, drivers, timeZone, trip }: Props) {
  const f = t.trips.form;
  return (
    <Card className="max-w-2xl">
      <form action={action} className="flex flex-col gap-6">
        {trip ? <input type="hidden" name="id" value={trip.id} /> : null}

        <Select
          id="bus_id"
          name="bus_id"
          label={f.bus}
          icon={Bus01Icon}
          placeholder={f.choose}
          defaultValue={trip?.busId ?? ""}
          hint={buses.length === 0 ? f.noBuses : undefined}
          options={buses.map((bus) => ({ value: bus.id, label: `${bus.label}${bus.inService ? "" : ` (${f.outOfService})`}` }))}
        />

        <Select
          id="driver_id"
          name="driver_id"
          label={f.driver}
          icon={UserIcon}
          hint={f.driverHint}
          defaultValue={trip?.driverId ?? ""}
          options={[{ value: "", label: f.noDriver }, ...drivers.map((driver) => ({ value: driver.id, label: driver.name }))]}
        />

        <Select
          id="assistant_id"
          name="assistant_id"
          label={f.assistant}
          icon={UserIcon}
          hint={f.assistantHint}
          defaultValue={trip?.assistantId ?? ""}
          options={[{ value: "", label: f.noAssistant }, ...drivers.map((person) => ({ value: person.id, label: person.name }))]}
        />

        <Select
          id="direction"
          name="direction"
          label={f.direction}
          icon={Navigation03Icon}
          defaultValue={trip?.direction ?? "inbound"}
          options={DIRECTIONS.map((direction) => ({ value: direction, label: t.trips.direction[direction] }))}
        />

        <DateTimePicker
          id="scheduled_start"
          name="scheduled_start"
          label={f.start}
          hint={format(f.startHint, { zone: timeZone })}
          locale={locale}
          step={5}
          defaultValue={trip?.start ?? ""}
          text={{ date: t.pickers.date, time: t.pickers.time, dateLabel: t.pickers.dateLabel, timeLabel: t.pickers.timeLabel }}
        />

        <div>
          <Button type="submit">{trip ? f.save : f.create}</Button>
        </div>
      </form>
    </Card>
  );
}
