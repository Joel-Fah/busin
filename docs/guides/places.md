# Places for My area

The place search in the student app's My area ([ADR 0013](../decisions/0013-coarse-home-area.md)) searches a copy of
the named places around each school's stops, taken from OpenStreetMap. Each school needs one import, then another
whenever its stops move to a new part of town.

## Import for a school

The school must have its stops first: the import covers the area around them, widened by about 30 km.

```bash
npm run places:import -- <school id> --dry   # only count what would come in
npm run places:import -- <school id>         # replace the school's places
```

Locally this uses the running local backend. Against a hosted project, set `SUPABASE_URL` and
`SUPABASE_SERVICE_ROLE_KEY` in your shell first (never in a file in the repository). Changing hosted data is the
owner's decision.

The script asks the public Overpass service once and tries a few public servers in turn when one is busy. They are
shared and free: run the import when needed, never on a schedule. For Yaounde it brings in about 9,000 places
(neighbourhoods, villages, street stretches, schools, hospitals, markets and churches) in under a minute.

## Licence

The data is (c) OpenStreetMap contributors, under the Open Database License. The app shows the credit under the search
results. The `places` table is internal (students only ever get search results) and is never published as a database.
