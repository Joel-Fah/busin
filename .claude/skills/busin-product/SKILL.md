---
name: busin-product
description: What BusIn is, who uses it, the core flows and the vocabulary. Load before designing or changing any feature, screen, schema or copy so the work matches the product.
---

# BusIn product

BusIn replaces paper-based campus bus management. Students subscribe per semester, show a QR code when boarding, and staff scan it. The data collected over time helps staff decide pickup points and routes.

## Actors

| Actor | App | Does |
|---|---|---|
| Student | Student app | Subscribes for a semester, uploads payment proof, shows QR, sees history and bus position |
| Staff | Ops app | Scans QR codes at boarding, sees the trip manifest |
| Driver | Ops app (driver mode) | Starts and ends a trip, shares live position |
| Admin | Admin portal | Reviews subscriptions, manages people, stops, semesters, buses and trips, reads analytics |
| School | Configuration | Name, timezone, allowed email domains, settings. Every record belongs to one school |

## Core flows

1. **Sign in** with Google. The email domain must match the school's allow-list. New accounts are students. Staff accounts start as pending until an admin approves them.
2. **Subscribe**: pick a semester and a preferred stop, upload proof of payment. Status: pending, approved, rejected (with reason, student may resubmit), expired (at semester end).
3. **Review**: admins approve or reject; pending items target a review within 24 hours.
4. **Board**: the student shows a rotating QR; staff scan it; the scan is valid only with an approved subscription inside the semester dates and an account that is not suspended. Repeat scans on one trip are ignored.
5. **Track**: a driver-mode phone (later a hardware tracker) publishes the bus position; students see it.
6. **Decide**: nightly aggregates feed density maps, pickup suggestions and route proposals.

## Vocabulary

Use these words consistently in code and UI: semester (Fall, Spring, Summer, can span two calendar years), subscription, stop, trip, scan, proof, school. Currency is XAF.

## Source material

The legacy app's help pages describe the intended behavior: `apps/legacy/lib/docs/busin_for_students.md` and `busin_for_admins.md`. They mention single-ride and day passes; only semester subscriptions are implemented, so do not build the others unless asked. Legal text is in `apps/legacy/lib/docs/legal.md`.

## Principles

User first and simple. Fail gracefully with messages that say what happened and how to fix it. Collect only the data needed. English and French are both required for every user-facing string.
