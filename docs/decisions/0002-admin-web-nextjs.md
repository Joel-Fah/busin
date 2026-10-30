# 0002: Next.js and TypeScript for the admin portal

Status: accepted, 2026-10-30.

## Context
The admin portal needs large tables, maps and heatmaps, exports, and fast loading. It must be a separate app in the same repository.

## Decision
Next.js 16 (App Router) with TypeScript in strict mode, using the Supabase JavaScript client. Flutter Web was considered; it reuses Dart packages but is weaker for data-dense interfaces and maps.

## Consequences
Models are defined in TypeScript as well as Dart. Keep this small by putting business rules in the database and Edge Functions rather than in either client.
