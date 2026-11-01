import { isSemesterName, type SemesterName } from "@/lib/semesters";
import { createClient } from "@/lib/supabase/server";

export type SemesterRow = { id: string; name: SemesterName; year: number; startDate: string; endDate: string };

// A school has a few semesters a year. The cap keeps the page light if that ever changes.
const MAX_SEMESTERS = 100;

/** Semesters of the admin's school, newest first. Row Level Security limits the rows to that school. */
export async function loadSemesters(): Promise<{ semesters: SemesterRow[]; failed: boolean }> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("semesters")
    .select("id, name, year, start_date, end_date")
    .order("start_date", { ascending: false })
    .limit(MAX_SEMESTERS);

  if (error || !data) return { semesters: [], failed: true };
  return {
    semesters: data.flatMap((row) =>
      isSemesterName(row.name)
        ? [{ id: row.id, name: row.name, year: row.year, startDate: row.start_date, endDate: row.end_date }]
        : [],
    ),
    failed: false,
  };
}
