"use client";

import "maplibre-gl/dist/maplibre-gl.css";

import { LngLatBounds, Map as MapLibreMap, NavigationControl, setWorkerUrl, type ExpressionSpecification, type GeoJSONSource } from "maplibre-gl";
import { useEffect, useRef, useState } from "react";

import type { LatLng } from "@/lib/geo";
import type { StopPoint } from "@/lib/student/bus";
import { Glide, MAP_COLORS, insideView, lineData, pointData, pulseAt, pulseData, stopsData, type FeatureCollection } from "@/lib/student/bus-map";

// The bundler does not emit MapLibre's worker; tools/copy-map-workers.mjs copies it to public/vendor.
setWorkerUrl("/vendor/maplibre/maplibre-gl-worker.mjs");

export type BusMapProps = {
  styleUrl: string;
  darkStyleUrl: string;
  stops: StopPoint[];
  myStopId: string | null;
  /** Where the bus is now, or null while it has not reported. */
  bus: LatLng | null;
  /** Where the student is, while they use Show me (ADR 0016). */
  me: LatLng | null;
  /** The school's planned route along roads, and where this bus has been on its trip (oldest first). */
  route: LatLng[];
  trail: LatLng[];
  campus: LatLng | null;
  campusName: string | null;
  /** Grows each time the student asks to see themselves, or to see the bus again. */
  focusMe: number;
  recenter: number;
  /** Where to look before anything is known. */
  fallback: LatLng;
  /** What floats over the top of the map (the buttons), so the bus is not centred under it. */
  topCovered: number;
  /** What floats over the bottom of the map (the bus card), so the bus is framed above it. */
  coveredBottom: number;
  /** Told whether the bus is in the visible part of the map and followed, so "Show the bus" shows only when it is not. */
  onBusInView: (inView: boolean) => void;
  ariaLabel: string;
  unavailableLabel: string;
};

const FONT = ["Noto Sans Regular"];
const FRAME_MS = 50;
const BUS_PING_MS = 1800;
const STOP_PING_MS = 2600;
const SOURCES = ["route", "trail", "pulse", "stops", "campus", "me", "bus"] as const;

function webglAvailable(): boolean {
  try {
    const canvas = document.createElement("canvas");
    return Boolean(canvas.getContext("webgl2") ?? canvas.getContext("webgl"));
  } catch {
    return false;
  }
}

/** The page is dark when the student forced it, or follows a dark device. */
function pageIsDark(): boolean {
  const forced = document.documentElement.dataset.theme;
  return forced === "dark" || (forced !== "light" && window.matchMedia("(prefers-color-scheme: dark)").matches);
}

function usePageDark(): boolean {
  const [dark, setDark] = useState(pageIsDark);
  useEffect(() => {
    const update = () => setDark(pageIsDark());
    const media = window.matchMedia("(prefers-color-scheme: dark)");
    media.addEventListener("change", update);
    const watcher = new MutationObserver(update);
    watcher.observe(document.documentElement, { attributes: true, attributeFilter: ["data-theme"] });
    return () => {
      media.removeEventListener("change", update);
      watcher.disconnect();
    };
  }, []);
  return dark;
}

const reducedMotion = () => window.matchMedia("(prefers-reduced-motion: reduce)").matches;

/** The rings' look at a point of their ping. The whole expression each time, as the phone does. */
function pulsePaint(busPhase: number, stopPhase: number, reduced: boolean): { radius: ExpressionSpecification; opacity: ExpressionSpecification | number } {
  const bus = pulseAt(busPhase, 9, 14, 0.35);
  const stop = pulseAt(stopPhase, 8, 12, 0.4);
  return {
    radius: ["match", ["get", "kind"], "bus", bus.radius, stop.radius],
    opacity: reduced ? 0 : ["match", ["get", "kind"], "bus", bus.opacity, stop.opacity],
  };
}

/**
 * My bus's map, as in the student app: the planned route and the trip's trail as lines, a grey dot for each stop with
 * its name (orange and pinging for the student's own), the campus, the bus as a blue dot pinging and gliding between
 * positions, and the student in green with Show me. The camera follows the bus until the student moves the map; the
 * page's "Show the bus" follows it again. It only draws: what to draw is the page's decision.
 */
export default function BusMap(props: BusMapProps) {
  const [supported] = useState(webglAvailable);
  const dark = usePageDark();
  const container = useRef<HTMLDivElement>(null);
  const map = useRef<MapLibreMap | null>(null);
  const ready = useRef(false);
  const latest = useRef(props);
  const busGlide = useRef<Glide | null>(null);
  const meGlide = useRef<Glide | null>(null);
  const lastBusReport = useRef<number | null>(null);
  const following = useRef(true);
  const fitted = useRef(false);
  const style = dark ? props.darkStyleUrl : props.styleUrl;

  useEffect(() => {
    latest.current = props;
  });

  const myStopPosition = () => {
    const { stops, myStopId } = latest.current;
    return stops.find((s) => s.id === myStopId)?.position ?? null;
  };

  const set = (id: (typeof SOURCES)[number], data: FeatureCollection) => {
    const source = map.current?.getSource(id) as GeoJSONSource | undefined;
    source?.setData(data as GeoJSON.FeatureCollection);
  };

  const checkBusInView = () => {
    const m = map.current;
    const bus = latest.current.bus;
    if (!m || !ready.current || !bus) {
      latest.current.onBusInView(false);
      return;
    }
    const point = m.project([bus.lng, bus.lat]);
    const canvas = m.getContainer();
    const inside = insideView(point, { width: canvas.clientWidth, height: canvas.clientHeight }, latest.current.coveredBottom);
    latest.current.onBusInView(inside && following.current);
  };

  /** Frames the bus, the student and their stop; one alone is shown up close. */
  const fit = () => {
    const m = map.current;
    const { bus, me } = latest.current;
    if (!m || !ready.current || (!bus && !me)) return;
    if (bus) fitted.current = true;
    const points = [bus, me, myStopPosition()].filter((p): p is LatLng => p !== null);
    if (points.length === 1) {
      m.easeTo({ center: [points[0].lng, points[0].lat], zoom: 15, duration: reducedMotion() ? 0 : 600 });
      return;
    }
    const bounds = new LngLatBounds();
    for (const p of points) bounds.extend([p.lng, p.lat]);
    m.fitBounds(bounds, { padding: { left: 64, right: 64, top: latest.current.topCovered + 56, bottom: 64 + latest.current.coveredBottom }, maxZoom: 16, duration: reducedMotion() ? 0 : 600 });
  };

  /** While following: the camera moves along with the bus's glide, keeping it in the middle of what the student sees. */
  const keepBusInView = () => {
    const m = map.current;
    const glide = busGlide.current;
    if (!following.current || !m || !ready.current || !glide) return;
    m.easeTo({
      center: [glide.to.lng, glide.to.lat],
      offset: [0, (latest.current.topCovered - latest.current.coveredBottom) / 2],
      duration: reducedMotion() ? 0 : glide.durationMs > 0 ? glide.durationMs : 600,
      easing: (t) => t,
    });
  };

  /** Everything that does not move by itself, from the latest props. */
  const drawStill = () => {
    if (!ready.current) return;
    const p = latest.current;
    const now = Date.now();
    set("stops", stopsData(p.stops, p.myStopId));
    set("route", lineData(p.route));
    set("trail", lineData(p.trail));
    set("campus", pointData(p.campus, { name: p.campusName ?? "" }));
    set("me", pointData(meGlide.current?.positionAt(now) ?? null));
    set("bus", pointData(busGlide.current?.positionAt(now) ?? null));
    set("pulse", pulseData(busGlide.current?.positionAt(now) ?? null, myStopPosition()));
  };

  // The sources and layers, bottom to top: the route, the trail, the rings, the stops, the campus, the student, the bus,
  // then the names. Added for each base map (a new one drops them).
  const addLayers = (m: MapLibreMap, isDark: boolean) => {
    const empty = { type: "FeatureCollection", features: [] } as GeoJSON.FeatureCollection;
    for (const id of SOURCES) if (!m.getSource(id)) m.addSource(id, { type: "geojson", data: empty });
    const halo = isDark ? "#0B1F24" : "#FFFFFF";
    const ink = isDark ? "#E6EEF0" : "#1F2A2E";
    const ring = pulsePaint(0, 0, reducedMotion());
    m.addLayer({ id: "route-line", type: "line", source: "route", layout: { "line-join": "round", "line-cap": "round" }, paint: { "line-color": MAP_COLORS.route, "line-opacity": isDark ? 0.75 : 0.5, "line-width": 4 } });
    m.addLayer({ id: "trail-line", type: "line", source: "trail", layout: { "line-join": "round", "line-cap": "round" }, paint: { "line-color": MAP_COLORS.trail, "line-opacity": 0.4, "line-width": 3, "line-dasharray": [1, 1.6] } });
    m.addLayer({
      id: "pulse-ring",
      type: "circle",
      source: "pulse",
      paint: {
        "circle-color": ["match", ["get", "kind"], "bus", MAP_COLORS.bus, MAP_COLORS.myStop],
        "circle-radius": ring.radius,
        "circle-opacity": ring.opacity,
        "circle-stroke-width": 0,
      },
    });
    m.addLayer({
      id: "stops-dot",
      type: "circle",
      source: "stops",
      paint: {
        "circle-color": ["case", ["get", "mine"], MAP_COLORS.myStop, MAP_COLORS.stop],
        "circle-radius": ["case", ["get", "mine"], 8, 5.5],
        "circle-stroke-color": "#FFFFFF",
        "circle-stroke-width": 2,
      },
    });
    m.addLayer({ id: "campus-dot", type: "circle", source: "campus", paint: { "circle-color": MAP_COLORS.campus, "circle-radius": 9, "circle-stroke-color": "#FFFFFF", "circle-stroke-width": 3 } });
    m.addLayer({ id: "me-dot", type: "circle", source: "me", paint: { "circle-color": MAP_COLORS.me, "circle-radius": 7.5, "circle-stroke-color": "#FFFFFF", "circle-stroke-width": 3 } });
    m.addLayer({ id: "bus-dot", type: "circle", source: "bus", paint: { "circle-color": MAP_COLORS.bus, "circle-radius": 9, "circle-stroke-color": "#FFFFFF", "circle-stroke-width": 3 } });
    // Names under the dots. The student's own stop wins a crowded spot; other names give way rather than overlap.
    m.addLayer({
      id: "stops-name",
      type: "symbol",
      source: "stops",
      layout: {
        "text-field": ["get", "name"],
        "text-font": FONT,
        "text-size": ["case", ["get", "mine"], 13, 11.5],
        "text-anchor": "top",
        "text-offset": [0, 0.9],
        "text-max-width": 9,
        "symbol-sort-key": ["case", ["get", "mine"], 0, 1],
      },
      paint: { "text-color": ["case", ["get", "mine"], isDark ? "#FFB55C" : "#B8650A", ink], "text-halo-color": halo, "text-halo-width": 1.4 },
    });
    m.addLayer({
      id: "campus-name",
      type: "symbol",
      source: "campus",
      layout: { "text-field": ["get", "name"], "text-font": FONT, "text-size": 12.5, "text-anchor": "top", "text-offset": [0, 1.1], "text-max-width": 9 },
      paint: { "text-color": isDark ? "#7FD3E0" : MAP_COLORS.campus, "text-halo-color": halo, "text-halo-width": 1.4 },
    });
  };

  // The map, made once. A finger or the wheel on it means the student is looking around: stop following the bus.
  useEffect(() => {
    if (!supported || !container.current) return;
    const start = latest.current.bus ?? myStopPosition() ?? latest.current.stops[0]?.position ?? latest.current.fallback;
    const created = new MapLibreMap({
      container: container.current,
      style: pageIsDark() ? latest.current.darkStyleUrl : latest.current.styleUrl,
      center: [start.lng, start.lat],
      zoom: 13,
      attributionControl: { compact: true },
      dragRotate: false,
      pitchWithRotate: false,
    });
    created.touchZoomRotate.disableRotation();
    created.keyboard.disableRotation();
    created.addControl(new NavigationControl({ showCompass: false }), "bottom-right");
    map.current = created;
    // The credits start folded behind their (i), as on the phone; they open on a tap. MapLibre unfolds them once the
    // tiles' credits arrive, so they are folded the first time that happens.
    const foldCredits = () => {
      const credits = created.getContainer().querySelector(".maplibregl-ctrl-attrib");
      if (!credits?.classList.contains("maplibregl-compact-show")) return;
      credits.classList.remove("maplibregl-compact-show");
      created.off("styledata", foldCredits);
      created.off("sourcedata", foldCredits);
    };
    created.on("styledata", foldCredits);
    created.on("sourcedata", foldCredits);
    created.on("style.load", () => {
      ready.current = false;
      addLayers(created, pageIsDark());
      ready.current = true;
      drawStill();
      if (latest.current.bus && !fitted.current) fit();
      checkBusInView();
    });
    created.on("moveend", checkBusInView);
    const element = container.current;
    const lookAround = () => {
      if (!following.current) return;
      following.current = false;
      checkBusInView();
    };
    element.addEventListener("pointerdown", lookAround);
    element.addEventListener("wheel", lookAround, { passive: true });
    const watcher = new ResizeObserver(() => created.resize());
    watcher.observe(element);
    return () => {
      element.removeEventListener("pointerdown", lookAround);
      element.removeEventListener("wheel", lookAround);
      watcher.disconnect();
      ready.current = false;
      created.remove();
      map.current = null;
    };
    // Made once; later changes reach it through the effects below.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [supported]);

  // Light or dark with the page: a new base map, on which the layers are drawn again.
  const shownStyle = useRef<string | null>(null);
  useEffect(() => {
    const m = map.current;
    if (!m) return;
    if (shownStyle.current === null) {
      shownStyle.current = style;
      return;
    }
    if (shownStyle.current === style) return;
    shownStyle.current = style;
    ready.current = false;
    m.setStyle(style);
  }, [style]);

  // The still parts: stops, route, trail, campus.
  const trailEnd = props.trail[props.trail.length - 1];
  useEffect(() => {
    drawStill();
    // drawStill reads the latest props.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [props.stops, props.myStopId, props.route, props.trail.length, trailEnd?.lat, trailEnd?.lng, props.campus?.lat, props.campus?.lng, props.campusName]);

  // The bus moved: glide to it, the camera along with it while following. Its first position frames the view.
  const busLat = props.bus?.lat;
  const busLng = props.bus?.lng;
  useEffect(() => {
    const now = Date.now();
    const bus = latest.current.bus;
    if (!bus) {
      busGlide.current = null;
      lastBusReport.current = null;
    } else if (!busGlide.current) {
      busGlide.current = Glide.at(bus, now);
      lastBusReport.current = now;
    } else {
      busGlide.current = busGlide.current.towards(bus, now, lastBusReport.current === null ? 0 : now - lastBusReport.current, reducedMotion());
      lastBusReport.current = now;
    }
    if (!ready.current) return;
    if (!busGlide.current?.movingAt(now)) {
      set("bus", pointData(busGlide.current?.positionAt(now) ?? null));
      set("pulse", pulseData(busGlide.current?.positionAt(now) ?? null, myStopPosition()));
    }
    if (bus && !fitted.current) fit();
    else keepBusInView();
    checkBusInView();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [busLat, busLng]);

  // The student moved (Show me). Seeing themselves the first time frames them too.
  const meLat = props.me?.lat;
  const meLng = props.me?.lng;
  const sawMe = useRef(false);
  useEffect(() => {
    const now = Date.now();
    const me = latest.current.me;
    if (!me) meGlide.current = null;
    else if (!meGlide.current) meGlide.current = Glide.at(me, now);
    else meGlide.current = meGlide.current.towards(me, now, 1000, reducedMotion());
    if (ready.current && !meGlide.current?.movingAt(now)) set("me", pointData(meGlide.current?.positionAt(now) ?? null));
    if (me && !sawMe.current && ready.current) fit();
    sawMe.current = me !== null;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [meLat, meLng]);

  // "Find me": to the student; the camera stops following the bus.
  useEffect(() => {
    const me = latest.current.me;
    if (props.focusMe === 0 || !me || !map.current) return;
    following.current = false;
    latest.current.onBusInView(false);
    map.current.flyTo({ center: [me.lng, me.lat], zoom: 16, duration: reducedMotion() ? 0 : 900 });
  }, [props.focusMe]);

  // "Show the bus": follow it again.
  useEffect(() => {
    if (props.recenter === 0) return;
    following.current = true;
    fit();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [props.recenter]);

  // About 20 frames a second: the rings grow, and the bus and the student glide. The browser pauses it in a hidden tab.
  useEffect(() => {
    if (!supported) return;
    let frame = 0;
    let last = 0;
    const started = performance.now();
    const tick = (at: number) => {
      frame = requestAnimationFrame(tick);
      if (!ready.current || at - last < FRAME_MS) return;
      last = at;
      const m = map.current;
      if (!m) return;
      const now = Date.now();
      const reduced = reducedMotion();
      const bus = busGlide.current?.positionAt(now) ?? null;
      if (busGlide.current?.movingAt(now)) set("bus", pointData(bus));
      if (meGlide.current?.movingAt(now)) set("me", pointData(meGlide.current.positionAt(now)));
      const stop = myStopPosition();
      if (bus || stop) {
        set("pulse", pulseData(bus, stop));
        if (!reduced && m.getLayer("pulse-ring")) {
          const elapsed = at - started;
          const ring = pulsePaint(elapsed / BUS_PING_MS, elapsed / STOP_PING_MS, false);
          m.setPaintProperty("pulse-ring", "circle-radius", ring.radius);
          m.setPaintProperty("pulse-ring", "circle-opacity", ring.opacity);
        }
      }
    };
    frame = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(frame);
  }, [supported]);

  if (!supported) {
    return (
      <div className="map map-fallback map-full" role="status">
        {props.unavailableLabel}
      </div>
    );
  }
  // The map's own controls (zoom, credits) sit just above the bus card, which floats over the bottom.
  return (
    <div
      ref={container}
      className="map map-full bus-map"
      style={{ "--bus-covered": `${props.coveredBottom}px` } as React.CSSProperties}
      role="region"
      aria-label={props.ariaLabel}
      data-testid="bus-map"
    />
  );
}
