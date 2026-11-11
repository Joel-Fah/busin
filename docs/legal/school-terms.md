# Terms for schools (draft, for owner review)

The text schools accept on their profile page lives in
[apps/admin_web/lib/legal/school-terms.ts](../../apps/admin_web/lib/legal/school-terms.ts), in English and French. Its
version is `SCHOOL_TERMS_VERSION` in [apps/admin_web/lib/school.ts](../../apps/admin_web/lib/school.ts).

Status: draft written by Claude, not reviewed. Before schools are asked to accept for real, the owner (and a lawyer if
needed) reviews it.

What it covers, in short:
- what using BusIn means for the school;
- the school's and students' data stay the school's, are never sold or mixed with another school's, and phones are
  never tracked;
- **name and logo**: accepting allows BusIn to show the school's name, city and logo publicly (for example the wall of
  schools on the BusIn site, and the student app) while "Show our school publicly" is on, and the school can turn it
  off at any time; the school confirms it has the right to use the logo it uploads;
- administrators: access only for people who need it, actions are the school's responsibility and are audited;
- changes: a meaningful change means a new version, which every school is asked to accept again.

How it is enforced: `public.schools.public_listing` can only be on once `terms_accepted_at` is set (a table check and
`admin_update_school_profile`), and `public.public_schools()` (the only thing a visitor can read) returns listed schools
with their public fields only.
