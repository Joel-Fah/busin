import { Bus01Icon, Tag01Icon, UserMultiple02Icon } from "@hugeicons/core-free-icons";

import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Switch } from "@/components/ui/Choice";
import { Input } from "@/components/ui/Input";
import { MAX_CAPACITY, MAX_NAME_LENGTH, MAX_PLATE_LENGTH } from "@/lib/buses";
import type { Messages } from "@/lib/i18n/messages";

type Props = {
  action: (formData: FormData) => Promise<void>;
  t: Messages;
  bus?: { id: string; plate: string; name: string | null; capacity: number; inService: boolean };
  /** The page to go back to after adding (a detour from the trip form). */
  next?: string | null;
};

/** The form used to add and to edit a bus. Server rendered; no client code needed. */
export function BusForm({ action, t, bus, next }: Props) {
  const f = t.buses.form;
  return (
    <Card className="max-w-2xl">
      <form action={action} className="flex flex-col gap-6">
        {bus ? <input type="hidden" name="id" value={bus.id} /> : null}
        {next ? <input type="hidden" name="next" value={next} /> : null}

        <Input
          id="plate"
          name="plate"
          label={f.plate}
          icon={Bus01Icon}
          required
          maxLength={MAX_PLATE_LENGTH}
          defaultValue={bus?.plate ?? ""}
          hint={f.plateHint}
          autoComplete="off"
        />

        <Input
          id="name"
          name="name"
          label={f.name}
          icon={Tag01Icon}
          maxLength={MAX_NAME_LENGTH}
          defaultValue={bus?.name ?? ""}
          hint={f.nameHint}
          placeholder={f.namePlaceholder}
          autoComplete="off"
        />

        <Input
          id="capacity"
          name="capacity"
          label={f.capacity}
          icon={UserMultiple02Icon}
          type="number"
          inputMode="numeric"
          required
          min={1}
          max={MAX_CAPACITY}
          step={1}
          defaultValue={bus?.capacity ?? ""}
        />

        <Switch name="in_service" label={f.inService} hint={f.inServiceHint} defaultChecked={bus?.inService ?? true} />

        <div>
          <Button type="submit">{bus ? f.save : f.create}</Button>
        </div>
      </form>
    </Card>
  );
}
