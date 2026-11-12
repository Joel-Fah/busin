# 0016: Showing the student on My bus

Date: 2026-11-11. Status: accepted (owner, 2026-11-11). Amends [ADR 0013](0013-coarse-home-area.md), which allowed the
student app only approximate location.

## Context

On My bus a student sees the bus and their stop, but not themselves, so they cannot judge whether to leave for the stop
now. Approximate location (what My area uses) is blurred by Android to between one and three kilometres, which is too
coarse to place a person next to a stop.

## Decision

1. The student app may ask for precise location (`ACCESS_FINE_LOCATION`, iOS "when in use"), only from a "Show me" button
   on My bus, after a short explanation. Background location stays removed.
2. The position is read only while My bus is on screen and the student has chosen Show me; leaving the tab or the app stops
   it. The choice lasts until the app is closed.
3. The position never leaves the phone: it is not sent to the server, not stored and not logged. It only draws a dot and
   the walk to the student's stop.
4. My area keeps reading once, at low accuracy, and the server keeps rounding it to about 500 m (ADR 0013).
5. If the student grants only approximate location, the dot still shows and the app says it is approximate.

## Consequences

- The Play Store asks for a location declaration (foreground, user-initiated feature); the owner fills it in before release.
- The privacy policy says the app reads the phone's position on My bus when asked, and keeps it on the phone.
