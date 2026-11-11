import type { MapMarker } from "./types";

/**
 * The page element for a marker, shared by every provider so they look and behave the same. A marker
 * with `href` is a link, one with `onSelect` is a button, anything else is plain. A selected marker is
 * drawn larger with a pinging wave; the visitor's own position is a blue dot with the same wave, in blue.
 */
export function createMarkerElement(item: MapMarker): HTMLElement {
  const element = document.createElement(item.href ? "a" : item.onSelect ? "button" : "div");
  element.className = [
    "map-marker",
    item.muted ? "map-marker-muted" : "",
    item.selected ? "map-marker-selected" : "",
    item.variant === "me" ? "map-marker-me" : "",
    item.variant === "campus" ? "map-marker-campus" : "",
    item.badge ? "map-marker-badge" : "",
  ]
    .filter(Boolean)
    .join(" ");
  if (item.badge) element.textContent = item.badge;
  element.setAttribute("aria-label", item.label);
  element.dataset.tip = item.label;
  if (item.href && element instanceof HTMLAnchorElement) element.href = item.href;
  if (item.onSelect && element instanceof HTMLButtonElement) {
    element.type = "button";
    if (item.selected) element.setAttribute("aria-pressed", "true");
    // A click on a marker selects it; it must not also count as a click on the map behind it.
    element.addEventListener("click", (event) => {
      event.stopPropagation();
      item.onSelect?.();
    });
  }
  return element;
}

/** The numbered bubble that stands for several markers that would overlap at this zoom. */
export function createClusterElement(count: number, label: string, onOpen: () => void): HTMLElement {
  const element = document.createElement("button");
  element.type = "button";
  element.className = "map-cluster";
  // Nine and under show the number; beyond that, 9+. The label keeps the exact count.
  element.textContent = count > 9 ? "9+" : String(count);
  element.setAttribute("aria-label", label.replace("{count}", String(count)));
  element.dataset.tip = element.getAttribute("aria-label") ?? "";
  element.addEventListener("click", (event) => {
    event.stopPropagation();
    onOpen();
  });
  return element;
}
