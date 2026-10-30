# Phase 3: student app

Goal: a lightweight student app with no staff or admin code.

## Scope
- Google sign-in through Supabase.
- Subscribe with a private proof upload and stop choice; status tracking.
- Rotating QR code; screenshot protection kept on the QR screen.
- Scan history (paginated).
- Live bus position for the student's bus.
- Push notifications through FCM on a minimal Firebase project.
- English and French, light and dark.

## Exit criteria
- Unit tests green (models, repositories, QR derivation).
- Owner device test passes: sign in, subscribe, see approval, show QR, see history.

## Depends on
Phase 2. Firebase project for FCM (owner).
