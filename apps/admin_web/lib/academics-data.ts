import { createClient } from "@/lib/supabase/server";

export type FacultyRow = { id: string; name: string; code: string | null; departments: DepartmentRow[] };
export type DepartmentRow = { id: string; name: string; code: string | null };
export type ProgramRow = { id: string; name: string };

// A school has a handful of faculties and a few dozen departments. The caps keep the page light if that changes.
const MAX_ROWS = 500;

/** Faculties with their departments, and the degree levels, of the admin's school (Row Level Security limits the rows). */
export async function loadAcademics(): Promise<{ faculties: FacultyRow[]; programs: ProgramRow[]; failed: boolean }> {
  const supabase = await createClient();
  const [faculties, departments, programs] = await Promise.all([
    supabase.from("faculties").select("id, name, code").order("name").limit(MAX_ROWS),
    supabase.from("departments").select("id, faculty_id, name, code").order("name").limit(MAX_ROWS),
    supabase.from("programs").select("id, name").order("sort_order").order("name").limit(MAX_ROWS),
  ]);
  if (faculties.error || departments.error || programs.error || !faculties.data || !departments.data || !programs.data) {
    return { faculties: [], programs: [], failed: true };
  }
  return {
    faculties: faculties.data.map((f) => ({
      id: f.id,
      name: f.name,
      code: f.code,
      departments: departments.data.filter((d) => d.faculty_id === f.id).map((d) => ({ id: d.id, name: d.name, code: d.code })),
    })),
    programs: programs.data,
    failed: false,
  };
}
