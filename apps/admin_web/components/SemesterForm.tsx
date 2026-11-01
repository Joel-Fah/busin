import type { Messages } from "@/lib/i18n/messages";
import { MAX_YEAR, MIN_YEAR, SEMESTER_NAMES, type SemesterName } from "@/lib/semesters";

type Props = {
  action: (formData: FormData) => Promise<void>;
  t: Messages;
  semester?: { id: string; name: SemesterName; year: number; startDate: string; endDate: string };
  /** Suggested year for a new semester. */
  defaultYear: number;
};

/** The form used to add and to edit a semester. Server rendered; no client code needed. */
export function SemesterForm({ action, t, semester, defaultYear }: Props) {
  const f = t.semesters.form;
  return (
    <form action={action} className="card stack">
      {semester ? <input type="hidden" name="id" value={semester.id} /> : null}

      <div className="field">
        <label htmlFor="name">{f.name}</label>
        <select id="name" name="name" required defaultValue={semester?.name ?? "fall"}>
          {SEMESTER_NAMES.map((name) => (
            <option key={name} value={name}>
              {t.semester[name]}
            </option>
          ))}
        </select>
      </div>

      <div className="field">
        <label htmlFor="year">{f.year}</label>
        <input
          id="year"
          name="year"
          type="number"
          inputMode="numeric"
          required
          min={MIN_YEAR}
          max={MAX_YEAR}
          step={1}
          defaultValue={semester?.year ?? defaultYear}
        />
      </div>

      <div className="field">
        <label htmlFor="start_date">{f.startDate}</label>
        <input id="start_date" name="start_date" type="date" required defaultValue={semester?.startDate ?? ""} />
      </div>

      <div className="field">
        <label htmlFor="end_date">{f.endDate}</label>
        <input
          id="end_date"
          name="end_date"
          type="date"
          required
          defaultValue={semester?.endDate ?? ""}
          aria-describedby="dates-hint"
        />
        <span id="dates-hint" className="muted">
          {f.datesHint}
        </span>
      </div>

      <div className="row">
        <button type="submit" className="btn btn-primary">
          {semester ? f.save : f.create}
        </button>
      </div>
    </form>
  );
}
