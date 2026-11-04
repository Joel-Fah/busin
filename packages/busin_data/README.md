# busin_data

Supabase implementations of the [busin_core](../busin_core/) repository interfaces. The only package that talks to the backend.

- Every query names its columns (see `lib/src/columns.dart`; no `select *`) and every list is paginated.
- Failures reach apps as `RepositoryException`s (`NotAllowed`, `NotFound`, `Conflict`, `Invalid`, `Offline`, `Unexpected`); no app sees a backend SDK error. Messages carry codes, never row contents.
- It depends on the pure Dart `supabase` client, which `supabase_flutter` wraps. An app starts `supabase_flutter` (sessions, deep links), then builds `SupabaseRepositories(Supabase.instance.client)` and exposes each repository as a provider so tests replace it with a fake.
- Nothing here does what only an administrator does; people, stops, semesters, buses and trips are managed in the admin portal.

Tests run with `fvm dart test`; they use a recording fake for the network, so they need no backend.
