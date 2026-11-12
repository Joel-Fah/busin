# busin_core

Pure Dart domain layer shared by the BusIn mobile apps. No Flutter and no backend SDK; backend access lives in [busin_data](../busin_data/).

## Contents

| File | What |
|---|---|
| `lib/src/enums.dart` | Roles, statuses, trip and scan enums. Parsing is strict: unknown values throw instead of defaulting |
| `lib/src/geo_point.dart` | A latitude and longitude, read from the API's GeoJSON or WKT and written as GeoJSON |
| `lib/src/models/` | Models that mirror the Supabase tables: school, profile, semester, stop, bus, trip, subscription, scan, live position, scan outcome |
| `lib/src/qr_code.dart` | The rotating boarding code generator. Format: [docs/guides/qr-code-format.md](../../docs/guides/qr-code-format.md) |

## Rules

- Models are immutable and compared by value (`ValueObject`).
- Models only read what the server sends. Role, status and school are never part of anything a client writes (`Profile.editableJson`, `NewSubscription.toJson`).
- Anything that depends on the clock takes the time as a parameter, so tests control it.

## Commands

```bash
fvm dart pub get      # at the repo root
fvm dart analyze      # strict analysis
fvm dart test         # 28 unit tests
```
