/** Set in this browser once My area has been offered (after setup, or by the card): it is not offered again (ADR 0023). */
export const AREA_OFFERED = "busin-area-offer";

export function areaOffered(): boolean {
  try {
    return window.localStorage.getItem(AREA_OFFERED) === "done";
  } catch {
    return false;
  }
}

export function markAreaOffered() {
  try {
    window.localStorage.setItem(AREA_OFFERED, "done");
  } catch {
    // Private mode: it may be offered again next time.
  }
}
