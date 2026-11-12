import { Calendar02Icon, Calendar03Icon } from "@hugeicons/core-free-icons";

import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { DatePicker } from "@/components/ui/DatePicker";
import { Input } from "@/components/ui/Input";
import { Select } from "@/components/ui/Select";
import type { Locale, Messages } from "@/lib/i18n/messages";
import { MAX_YEAR, MIN_YEAR, SEMESTER_NAMES, type SemesterName } from "@/lib/semesters";

type Props = {
  action: (formData: FormData) => Promise<void>;
  t: Messages;
  locale: Locale;
  semester?: { id: string; name: SemesterName; year: number; startDate: string; endDate: string };
  /** Suggested year for a new semester. */
  defaultYear: number;
  /** The school's day today (YYYY-MM-DD): a semester cannot end before it. */
  today: string;
};

/** The form used to add and to edit a semester. */
export function SemesterForm({ action, t, locale, semester, defaultYear, today }: Props) {
  const f = t.semesters.form;
  return (
    <Card className="max-w-2xl">
      <form action={action} className="flex flex-col gap-6">
        {semester ? <input type="hidden" name="id" value={semester.id} /> : null}

        <Select
          id="name"
          name="name"
          label={f.name}
          icon={Calendar02Icon}
          defaultValue={semester?.name ?? "fall"}
          options={SEMESTER_NAMES.map((name) => ({ value: name, label: t.semester[name] }))}
        />

        <Input
          id="year"
          name="year"
          label={f.year}
          icon={Calendar03Icon}
          type="number"
          inputMode="numeric"
          required
          min={MIN_YEAR}
          max={MAX_YEAR}
          step={1}
          defaultValue={semester?.year ?? defaultYear}
        />

        <div className="grid gap-6 sm:grid-cols-2">
          <DatePicker id="start_date" name="start_date" label={f.startDate} locale={locale} text={t.pickers.date} defaultValue={semester?.startDate ?? ""} />
          <DatePicker id="end_date" name="end_date" label={f.endDate} locale={locale} text={t.pickers.date} min={today} defaultValue={semester?.endDate ?? ""} />
        </div>
        <p className="-mt-3 text-sm text-muted">{f.datesHint}</p>

        <div>
          <Button type="submit">{semester ? f.save : f.create}</Button>
        </div>
      </form>
    </Card>
  );
}
