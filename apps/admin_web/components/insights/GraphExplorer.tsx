"use client";

import { useCallback, useEffect, useMemo, useRef, useState, type PointerEvent as ReactPointerEvent, type WheelEvent as ReactWheelEvent } from "react";
import { Add01Icon, MinusSignIcon, RefreshIcon } from "@hugeicons/core-free-icons";

import { InsightsHeader } from "@/components/insights/InsightsHeader";
import { NavDock } from "@/components/nav/NavDock";
import { Chip, type ChipTone } from "@/components/ui/Chip";
import { Icon } from "@/components/ui/Icon";
import { edgeEnds, layoutGraph, type GraphNode } from "@/lib/graph-layout";
import { format, type Messages } from "@/lib/i18n/messages";
import { formatShare, type LoadLevel, type StopLoads } from "@/lib/insights";
import { roughDistance, type Proximity, type Reach } from "@/lib/proximity";

type Props = { loads: StopLoads; proximity: Proximity; failed: boolean; t: Messages };

const LEVEL_FILL: Record<LoadLevel, string> = { quiet: "var(--info)", fair: "var(--ok)", busy: "var(--warn)", full: "var(--bad)" };
const LEVEL_TONE: Record<LoadLevel, ChipTone> = { quiet: "info", fair: "ok", busy: "warn", full: "bad" };
const REACH_RING: Record<Reach, string> = { near: "var(--ok)", walk: "var(--info)", far: "var(--warn)", remote: "var(--bad)" };
const REACH_TONE: Record<Reach, ChipTone> = { near: "ok", walk: "info", far: "warn", remote: "bad" };

const MIN_ZOOM = 0.6;
const MAX_ZOOM = 4;

/**
 * The Graph view of Insights: the stops as nodes where they really are (pushed apart so names never collide), each sized
 * by its subscribers, filled by how full the bus gets there and ringed by how far its students live; the places where 5
 * or more of a stop's students live as small nodes around it; and arrows from a stop to another its students live nearer
 * to. Drag to move, wheel or buttons to zoom; every node is a button (Tab moves node by node) that shows its figures in
 * the dock. No student is ever a node.
 */
export function GraphExplorer({ loads, proximity, failed, t }: Props) {
  const s = t.insights;
  const g = s.graph;
  const p = s.proximity;

  const loadById = useMemo(() => new Map(loads.stops.map((stop) => [stop.id, stop])), [loads.stops]);
  const proxById = useMemo(() => new Map(proximity.stops.map((stop) => [stop.id, stop])), [proximity.stops]);

  // The canvas takes the size of its area (one unit a pixel), so a wide screen spreads the stops and text stays its size.
  const box = useRef<HTMLDivElement>(null);
  const [size, setSize] = useState({ width: 1000, height: 640 });
  useEffect(() => {
    const el = box.current;
    if (!el) return;
    const watcher = new ResizeObserver(([entry]) => {
      const { width, height } = entry.contentRect;
      // Never smaller than this: on a phone the whole graph is drawn small, and the zoom buttons bring it closer.
      if (width > 0 && height > 0) setSize({ width: Math.max(Math.round(width), 760), height: Math.max(Math.round(height), 520) });
    });
    watcher.observe(el);
    return () => watcher.disconnect();
  }, []);

  const layout = useMemo(
    () =>
      layoutGraph(
        proximity.stops.flatMap((stop) => (stop.position ? [{ id: stop.id, name: stop.name, position: stop.position, riders: stop.subscribers }] : [])),
        proximity.lines.map((line) => ({ id: line.id, stopId: line.stopId, position: line.from, students: line.students, distance: line.distance })),
        proximity.nearerLines.map((line) => ({ id: line.id, from: line.fromId, to: line.toId, students: line.students })),
        size.width,
        size.height,
      ),
    [proximity, size],
  );
  const nodeById = useMemo(() => new Map(layout.nodes.map((n) => [n.id, n])), [layout.nodes]);

  const [selected, setSelected] = useState<string | null>(null);
  const [focused, setFocused] = useState<string | null>(null);
  const [view, setView] = useState({ k: 1, x: 0, y: 0 });
  const svg = useRef<SVGSVGElement>(null);
  const drag = useRef<{ x: number; y: number; vx: number; vy: number; moved: boolean } | null>(null);

  const distance = useCallback(
    (meters: number) => {
      const rough = roughDistance(meters);
      return format(rough.unit === "m" ? p.aboutM : p.aboutKm, { value: rough.value });
    },
    [p],
  );

  /** A point of the screen in the canvas's own units. */
  const toCanvas = (clientX: number, clientY: number) => {
    const el = svg.current;
    const m = el?.getScreenCTM();
    if (!el || !m) return { x: layout.width / 2, y: layout.height / 2 };
    const pt = new DOMPoint(clientX, clientY).matrixTransform(m.inverse());
    return { x: pt.x, y: pt.y };
  };

  const zoomAround = (factor: number, cx = layout.width / 2, cy = layout.height / 2) =>
    setView((v) => {
      const k = Math.min(MAX_ZOOM, Math.max(MIN_ZOOM, v.k * factor));
      // Keep the point under the cursor where it is.
      return { k, x: cx - ((cx - v.x) * k) / v.k, y: cy - ((cy - v.y) * k) / v.k };
    });

  const onWheel = (event: ReactWheelEvent<SVGSVGElement>) => {
    const at = toCanvas(event.clientX, event.clientY);
    zoomAround(event.deltaY < 0 ? 1.15 : 1 / 1.15, at.x, at.y);
  };

  const onPointerDown = (event: ReactPointerEvent<SVGSVGElement>) => {
    if ((event.target as Element).closest("[data-node]")) return;
    const at = toCanvas(event.clientX, event.clientY);
    drag.current = { x: at.x, y: at.y, vx: view.x, vy: view.y, moved: false };
    event.currentTarget.setPointerCapture(event.pointerId);
  };
  const onPointerMove = (event: ReactPointerEvent<SVGSVGElement>) => {
    const d = drag.current;
    if (!d) return;
    const at = toCanvas(event.clientX, event.clientY);
    // The canvas units move with the view, so measure against where the drag began.
    setView((v) => ({ ...v, x: d.vx + (at.x - d.x), y: d.vy + (at.y - d.y) }));
    d.moved = true;
  };
  const onPointerUp = () => {
    if (drag.current && !drag.current.moved) setSelected(null);
    drag.current = null;
  };

  const choose = (id: string) => setSelected((current) => (current === id ? null : id));

  const label = (node: GraphNode): string => {
    if (node.kind === "zone") {
      const stop = nodeById.get(node.stopId);
      return format(g.zone, { count: node.students, distance: distance(node.distance), stop: stop?.kind === "stop" ? stop.name : "" });
    }
    const load = loadById.get(node.id);
    const prox = proxById.get(node.id);
    const parts = [node.name];
    if (load?.level) parts.push(`${s.level[load.level]} (${formatShare(load.load ?? 0)})`);
    if (prox?.reach && prox.median !== null) parts.push(format(p.median, { distance: distance(prox.median) }));
    return parts.join(", ");
  };

  const chosen = selected ? nodeById.get(selected) : undefined;
  const ringOf = (id: string) => {
    const reach = proxById.get(id)?.reach;
    return reach ? REACH_RING[reach] : "var(--line)";
  };

  return (
    <>
      <div ref={box} className="fixed inset-x-0 top-0 bottom-[min(46vh,26rem)] z-0 bg-bg">
        <svg
          ref={svg}
          role="group"
          aria-label={g.label}
          viewBox={`0 0 ${layout.width} ${layout.height}`}
          className="h-full w-full cursor-grab touch-none select-none active:cursor-grabbing"
          onWheel={onWheel}
          onPointerDown={onPointerDown}
          onPointerMove={onPointerMove}
          onPointerUp={onPointerUp}
          onPointerCancel={onPointerUp}
        >
          <defs>
            <pattern id="graph-dots" width="24" height="24" patternUnits="userSpaceOnUse">
              <circle cx="1.5" cy="1.5" r="1.5" style={{ fill: "var(--line)" }} />
            </pattern>
            <marker id="graph-arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="5" markerHeight="5" orient="auto-start-reverse">
              <path d="M0,0 L10,5 L0,10 z" style={{ fill: "var(--info)" }} />
            </marker>
          </defs>
          <rect x={-5000} y={-5000} width={10000} height={10000} fill="url(#graph-dots)" />
          <g transform={`translate(${view.x} ${view.y}) scale(${view.k})`}>
            {layout.edges.map((edge) => {
              const a = nodeById.get(edge.from);
              const b = nodeById.get(edge.to);
              if (!a || !b) return null;
              const e = edgeEnds(a, b, edge.kind === "flow" ? 4 : 1);
              const faded = selected !== null && edge.from !== selected && edge.to !== selected;
              return edge.kind === "flow" ? (
                <line
                  key={edge.id}
                  {...e}
                  strokeWidth={edge.width}
                  strokeLinecap="round"
                  strokeDasharray="10 7"
                  markerEnd="url(#graph-arrow)"
                  style={{ stroke: "var(--info)", opacity: faded ? 0.25 : 0.95 }}
                />
              ) : (
                <line key={edge.id} {...e} strokeWidth={edge.width} strokeLinecap="round" style={{ stroke: "var(--accent)", opacity: faded ? 0.2 : 0.7 }} />
              );
            })}

            {layout.nodes.map((node) => {
              const isSelected = node.id === selected;
              const isFocused = node.id === focused;
              const faded = selected !== null && !isSelected && !(node.kind === "zone" && node.stopId === selected) && chosen?.kind !== "zone";
              const common = {
                "data-node": node.id,
                role: "button",
                tabIndex: 0,
                "aria-label": label(node),
                "aria-pressed": isSelected,
                onClick: () => choose(node.id),
                onKeyDown: (event: React.KeyboardEvent) => {
                  if (event.key === "Enter" || event.key === " ") {
                    event.preventDefault();
                    choose(node.id);
                  }
                },
                onFocus: () => setFocused(node.id),
                onBlur: () => setFocused((f) => (f === node.id ? null : f)),
                className: "cursor-pointer outline-none",
                style: { opacity: faded ? 0.35 : 1, transition: "opacity 200ms" },
              };
              if (node.kind === "zone") {
                return (
                  <g key={node.id} {...common}>
                    <title>{label(node)}</title>
                    {isSelected || isFocused ? <circle cx={node.x} cy={node.y} r={node.r + 5} fill="none" strokeWidth={2.5} style={{ stroke: "var(--focus)" }} /> : null}
                    <circle cx={node.x} cy={node.y} r={node.r} strokeWidth={2} style={{ fill: "var(--accent)", stroke: "var(--bg)" }} />
                  </g>
                );
              }
              const level = loadById.get(node.id)?.level;
              return (
                <g key={node.id} {...common}>
                  <title>{label(node)}</title>
                  {isSelected || isFocused ? <circle cx={node.x} cy={node.y} r={node.r + 8} fill="none" strokeWidth={3} style={{ stroke: "var(--focus)" }} /> : null}
                  <circle
                    cx={node.x}
                    cy={node.y}
                    r={node.r}
                    strokeWidth={5}
                    style={{ fill: level ? LEVEL_FILL[level] : "var(--surface-2)", fillOpacity: 0.9, stroke: ringOf(node.id) }}
                  />
                  <text
                    x={node.x}
                    y={node.y + node.r + 17}
                    textAnchor="middle"
                    fontSize={13}
                    fontWeight={700}
                    paintOrder="stroke"
                    strokeWidth={4}
                    strokeLinejoin="round"
                    style={{ fill: "var(--fg)", stroke: "var(--bg)" }}
                  >
                    {node.name}
                  </text>
                </g>
              );
            })}
          </g>
        </svg>

        <div className="absolute top-4 right-4 flex flex-col gap-1 rounded-md bg-surface p-1 shadow-float">
          {(
            [
              [Add01Icon, g.zoomIn, () => zoomAround(1.3)],
              [MinusSignIcon, g.zoomOut, () => zoomAround(1 / 1.3)],
              [RefreshIcon, g.reset, () => setView({ k: 1, x: 0, y: 0 })],
            ] as const
          ).map(([icon, text, onClick]) => (
            <button
              key={text}
              type="button"
              aria-label={text}
              data-tip={text}
              onClick={onClick}
              className="grid size-10 cursor-pointer place-items-center rounded-sm border-0 bg-transparent text-fg hover:bg-surface-2 focus-visible:outline-3 focus-visible:outline-focus"
            >
              <Icon icon={icon} size={20} />
            </button>
          ))}
        </div>
      </div>

      <NavDock>
        <section aria-label={s.title} className="flex flex-col gap-3">
          <InsightsHeader view="graph" help={g.help} t={t} />

          {failed ? (
            <p role="alert" className="rounded-sm bg-bad-bg px-3 py-2 text-sm text-bad">
              {s.loadError}
            </p>
          ) : null}

          <ul aria-label={g.legendLabel} className="m-0 grid list-none gap-1 p-0 text-xs text-muted sm:grid-cols-2">
            <li>{g.legendFill}</li>
            <li>{g.legendRing}</li>
            <li>{g.legendZone}</li>
            <li>{g.legendFlow}</li>
          </ul>

          <div aria-live="polite" className="min-h-[5.5rem] rounded-md bg-surface-2 p-4">
            {!chosen ? (
              <p className="m-0 text-sm text-muted">{layout.nodes.length === 0 ? s.empty : g.hint}</p>
            ) : chosen.kind === "zone" ? (
              <p className="m-0 text-sm font-semibold text-fg">{label(chosen)}</p>
            ) : (
              <StopPanel id={chosen.id} name={chosen.name} loads={loadById} prox={proxById} distance={distance} t={t} />
            )}
          </div>
        </section>
      </NavDock>
    </>
  );
}

function StopPanel({
  id,
  name,
  loads,
  prox,
  distance,
  t,
}: {
  id: string;
  name: string;
  loads: Map<string, StopLoads["stops"][number]>;
  prox: Map<string, Proximity["stops"][number]>;
  distance: (m: number) => string;
  t: Messages;
}) {
  const s = t.insights;
  const load = loads.get(id);
  const near = prox.get(id);
  return (
    <div className="flex flex-col gap-2">
      <div className="flex flex-wrap items-center gap-2">
        <h2 className="m-0 text-lg font-bold">{name}</h2>
        {load?.level ? <Chip tone={LEVEL_TONE[load.level]}>{`${s.level[load.level]} · ${format(s.stop.share, { share: formatShare(load.load ?? 0) })}`}</Chip> : null}
        {near?.reach ? <Chip tone={REACH_TONE[near.reach]}>{s.proximity.reach[near.reach]}</Chip> : null}
      </div>
      <p className="m-0 text-sm text-muted">
        {[
          load && load.departures > 0 ? format(s.stop.perDeparture, { count: Math.round(load.perDeparture * 10) / 10 }) : null,
          near ? format(s.graph.riders, { count: near.subscribers }) : null,
          near && near.median !== null ? format(s.proximity.median, { distance: distance(near.median) }) : near ? s.proximity.notEnough.replace("{count}", String(near.withArea)).replace("{min}", "5") : null,
        ]
          .filter(Boolean)
          .join(" · ")}
      </p>
      {near?.nearer.map((n) => (
        <p key={n.toId} className="m-0 text-sm font-semibold text-info">
          {format(s.proximity.nearer, { count: n.students, stop: n.toName, distance: distance(n.saved) })}
        </p>
      ))}
    </div>
  );
}
