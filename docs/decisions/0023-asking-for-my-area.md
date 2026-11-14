# 0023: Asking for My area

Status: accepted, 2026-11-14 (the owner asked for it). Amends [ADR 0013](0013-coarse-home-area.md), point 1.

## Context
ADR 0013 kept My area in the profile and never asked for it. In practice many students never find it, so schools get
too few areas to place stops well.

## Decision
1. **Offered once, right after setup.** When a new student saves their details, the next screen is My area with a
   short welcome ("One more thing: where do you live?") and "Not now". Either answer moves them on to the app.
2. **Offered once to students who already set up.** A student without an area gets one card on the Subscription tab
   ("Add your area", "Not now"), only when the notification offer is not showing. Either answer hides it for good.
3. **Still optional.** Nothing depends on it, "Not now" always works, and the rules of ADR 0013 (approximate, rounded,
   read once, never tracked) are unchanged.
4. **Remembered on the device.** The phone app keeps "offered" per student in its preferences; the web app keeps it
   in the browser. A new device may offer it once more, which is harmless.

## Consequences
- The setup flow has one more, skippable, screen.
- No server change.
