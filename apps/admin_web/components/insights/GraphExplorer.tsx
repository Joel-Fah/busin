"use client";

import { useCallback, useEffect, useMemo, useRef, useState, useSyncExternalStore, type PointerEvent as ReactPointerEvent, type WheelEvent as ReactWheelEvent } from "react";
import { Add01Icon, MinusSignIcon, RefreshIcon } from "@hugeicons/core-free-icons";

import { GraphGuide, LEVEL_COLOR, REACH_COLOR } from "@/components/insights/GraphLegend";
import { InsightsHeader } from "@/components/insights/InsightsHeader";
import { NavDock } from "@/components/nav/NavDock";
import { Chip, type ChipTone } from "@/components/ui/Chip";
import { Icon } from "@/components/ui/Icon";
import { edgeEnds, layoutGraph, type GraphNode } from "@/lib/graph-layout";
import { graphFacts, type GraphFact } from "@/lib/graph-summary";
import { format, type Messages } from "@/lib/i18n/messages";
import { formatShare, type LoadLevel, type StopLoads } from "@/lib/insights";
import { roughDistance, type Proximity, type Reach } from "@/lib/proximity";
import type { Suggestion } from "@/lib/suggestions";

type Props = { loads: StopLoads; proximity: Proximity; suggestions?: Suggestion[]; failed: boolean; t: Messages };

const LEVEL_TONE: Record<LoadLevel, ChipTone> = { quiet: "info", fair: "ok", busy: "warn", full: "bad" };
const REACH_TONE: Record<Reach, ChipTone> = { near: "ok", walk: "info", far: "warn", remote: "bad" };

/** Whether the screen is wide enough to keep the guide open beside the graph (false on the server). */
function useWide(): boolean {
  return useSyncExternalStore(
    (change) => {
      const query = window.matchMedia("(min-width: 1024px)");
      query.addEventListener("change", change);
      return () => query.removeEventListener("change", change);
    },
    () => window.matchMedia("(min-width: 1024px)").matches,
    () => false,
  );
}

const MIN_ZOOM = 0.6;
const MAX_ZOOM = 4;

/** A gentle curve from one point to another, bending to the left of the way. */
function curve(e: { x1: number; y1: number; x2: number; y2: number }, bend = 0.12): string {
  const mx = (e.x1 + e.x2) / 2;
  const my = (e.y1 + e.y2) / 2;
  const cx = Math.round((mx - (e.y2 - e.y1) * bend) * 100) / 100;
  const cy = Math.round((my + (e.x2 - e.x1) * bend) * 100) / 100;
  return `M${e.x1} ${e.y1} Q${cx} ${cy} ${e.x2} ${e.y2}`;
}

/**
 * The Graph view of Insights, drawn quietly: each stop a pale disc in the colour of its load with a thin ring in the
 * colour of how far its students live, sized by subscribers and placed roughly where it is (names never collide); small
 * orange dots for places where 5 or more of its students live, joined by a faint curve; dashed blue curves to a stop its
 * students live nearer to; dashed rings for suggested new stops. "How to read" draws each shape, and "In short" says in
 * a few sentences what the graph shows. Drag, zoom, and every node is a button (Tab, Enter). No student is ever a node.
 */
export function GraphExplorer({ loads, proximity, suggestions = [], failed, t }: Props) {
  const s = t.insights;
  const g = s.graph;
  const p = s.proximity;

  const loadById = useMemo(() => new Map(loads.stops.map((stop) => [stop.id, stop])), [loads.stops]);
  const proxById = useMemo(() => new Map(proximity.stops.map((stop) => [stop.id, stop])), [proximity.stops]);

  // The canvas takes the size of its area (one unit a pixel), never smaller than a laptop's: a phone shows it small.
  const box = useRef<HTMLDivElement>(null);
  const [size, setSize] = useState({ width: 1000, height: 640 });
  useEffect(() => {
    const el = box.current;
    if (!el) return;
    const watcher = new ResizeObserver(([entry]) => {
      const { width, height } = entry.contentRect;
      if (width > 0 && height > 0) setSize({ width: Math.max(Math.round(width), 760), height: Math.max(Math.round(height), 520) });
    });
    watcher.observe(el);
    return () => watcher.disconnect();
  }, []);

  // The guide starts open on a wide screen and folded on a phone; while open beside the graph, the graph moves aside.
  const wide = useWide();
  const [guideChoice, setGuideChoice] = useState<boolean | null>(null);
  const guideOpen = guideChoice ?? wide;

  // The canvas ends where the dock begins (the dock's height changes with its content and the screen), so no node hides
  // under it.
  const dock = useRef<HTMLElement>(null);
  const [below, setBelow] = useState<number | null>(null);
  useEffect(() => {
    const el = dock.current;
    if (!el) return;
    // The dock's card starts a little above its content.
    const measure = () => setBelow(Math.max(0, Math.round(window.innerHeight - el.getBoundingClientRect().top + 44)));
    measure();
    const watcher = new ResizeObserver(measure);
    watcher.observe(el);
    window.addEventListener("resize", measure);
    return () => {
      watcher.disconnect();
      window.removeEventListener("resize", measure);
    };
  }, []);

  const layout = useMemo(
    () =>
      layoutGraph(
        proximity.stops.flatMap((stop) => (stop.position ? [{ id: stop.id, name: stop.name, position: stop.position, riders: stop.subscribers }] : [])),
        proximity.lines.map((line) => ({ id: line.id, stopId: line.stopId, position: line.from, students: line.students, distance: line.distance })),
        proximity.nearerLines.map((line) => ({ id: line.id, from: line.fromId, to: line.toId, students: line.students })),
        size.width,
        size.height,
        suggestions.flatMap((item) => (item.kind === "new_stop" ? [{ id: item.id, name: item.place, position: item.position, students: item.students }] : [])),
      ),
    [proximity, size, suggestions],
  );
  const nodeById = useMemo(() => new Map(layout.nodes.map((n) => [n.id, n])), [layout.nodes]);
  const facts = useMemo(() => graphFacts(loads, proximity, suggestions), [loads, proximity, suggestions]);

  const [selected, setSelected] = useState<string | null>(null);
  // The report card beside the node being pointed at (or reached with the keyboard), in the canvas's own pixels.
  const [tip, setTip] = useState<{ id: string; x: number; top: number; bottom: number; width: number; height: number } | null>(null);
  const showTip = (id: string, el: Element) => {
    const area = box.current?.getBoundingClientRect();
    if (!area) return;
    const r = el.getBoundingClientRect();
    setTip({ id, x: r.left + r.width / 2 - area.left, top: r.top - area.top, bottom: r.bottom - area.top, width: area.width, height: area.height });
  };
  const [hovered, setHovered] = useState<string | null>(null);
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

  const toCanvas = (clientX: number, clientY: number) => {
    const el = svg.current;
    const m = el?.getScreenCTM();
    if (!el || !m) return { x: layout.width / 2, y: layout.height / 2 };
    const pt = new DOMPoint(clientX, clientY).matrixTransform(m.inverse());
    return { x: pt.x, y: pt.y };
  };
  const zoomAround = (factor: number, cx = layout.width / 2, cy = layout.height / 2) => {
    setTip(null);
    setView((v) => {
      const k = Math.min(MAX_ZOOM, Math.max(MIN_ZOOM, v.k * factor));
      return { k, x: cx - ((cx - v.x) * k) / v.k, y: cy - ((cy - v.y) * k) / v.k };
    });
  };
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
    setView((v) => ({ ...v, x: d.vx + (at.x - d.x), y: d.vy + (at.y - d.y) }));
    if (!d.moved) setTip(null);
    d.moved = true;
  };
  const onPointerUp = () => {
    if (drag.current && !drag.current.moved) setSelected(null);
    drag.current = null;
  };
  const choose = (id: string) => setSelected((current) => (current === id ? null : id));

  const label = (node: GraphNode): string => {
    if (node.kind === "suggested") return format(s.suggestions.graphNode, { place: node.name, count: node.students });
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

  // What is lit: the chosen (or hovered) node, its own student dots and the stops it is linked to; the rest steps back.
  const lit = useMemo(() => {
    const id = selected ?? hovered;
    if (!id) return null;
    const set = new Set([id]);
    for (const e of layout.edges) {
      if (e.from === id) set.add(e.to);
      if (e.to === id) set.add(e.from);
    }
    return set;
  }, [selected, hovered, layout.edges]);
  const chosen = selected ? nodeById.get(selected) : undefined;

  return (
    <>
      <div
        ref={box}
        className="fixed top-0 right-0 z-0 bg-bg transition-[left] duration-(--dur) ease-soft"
        style={{ bottom: below ?? "min(46vh, 26rem)", left: guideOpen && wide ? "23rem" : 0 }}
      >
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
            <pattern id="graph-dots" width="28" height="28" patternUnits="userSpaceOnUse">
              <circle cx="1" cy="1" r="1" style={{ fill: "var(--line)" }} />
            </pattern>
            <marker id="graph-arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="4" markerHeight="4" orient="auto-start-reverse">
              <path d="M0,0 L10,5 L0,10 z" style={{ fill: "var(--info)" }} />
            </marker>
          </defs>
          <rect x={-5000} y={-5000} width={10000} height={10000} fill="url(#graph-dots)" opacity={0.7} />
          <g transform={`translate(${view.x} ${view.y}) scale(${view.k})`}>
            {layout.edges.map((edge) => {
              const a = nodeById.get(edge.from);
              const b = nodeById.get(edge.to);
              if (!a || !b) return null;
              const on = !lit || (lit.has(edge.from) && lit.has(edge.to));
              return edge.kind === "flow" ? (
                <path
                  key={edge.id}
                  d={curve(edgeEnds(a, b, 6), 0.18)}
                  fill="none"
                  strokeWidth={Math.min(edge.width * 0.5, 3)}
                  strokeLinecap="round"
                  strokeDasharray="5 5"
                  markerEnd="url(#graph-arrow)"
                  style={{ stroke: "var(--info)", opacity: on ? 0.85 : 0.15, transition: "opacity 200ms" }}
                />
              ) : (
                <path
                  key={edge.id}
                  d={curve(edgeEnds(a, b, 1), 0.1)}
                  fill="none"
                  strokeWidth={Math.min(edge.width * 0.45, 2.5)}
                  strokeLinecap="round"
                  style={{ stroke: "var(--accent)", opacity: on ? 0.45 : 0.1, transition: "opacity 200ms" }}
                />
              );
            })}

            {layout.nodes.map((node) => {
              const isSelected = node.id === selected;
              const isFocused = node.id === focused;
              const on = !lit || lit.has(node.id);
              const strong = isSelected || node.id === hovered;
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
                onFocus: (event: React.FocusEvent<SVGGElement>) => {
                  setFocused(node.id);
                  showTip(node.id, event.currentTarget);
                },
                onBlur: () => {
                  setFocused((f) => (f === node.id ? null : f));
                  setTip((t) => (t?.id === node.id ? null : t));
                },
                onPointerEnter: (event: React.PointerEvent<SVGGElement>) => {
                  setHovered(node.id);
                  if (!drag.current) showTip(node.id, event.currentTarget);
                },
                onPointerLeave: () => {
                  setHovered((h) => (h === node.id ? null : h));
                  setTip((t) => (t?.id === node.id ? null : t));
                },
                className: "cursor-pointer outline-none",
                style: { opacity: on ? 1 : 0.3, transition: "opacity 200ms" },
              };
              const focusRing = isSelected || isFocused ? <circle cx={node.x} cy={node.y} r={node.r + 9} fill="none" strokeWidth={1.5} strokeDasharray={isFocused && !isSelected ? "3 3" : undefined} style={{ stroke: "var(--fg)", opacity: 0.6 }} /> : null;
              const name = (color: string) => (
                <text
                  x={node.x}
                  y={node.y + node.r + 18}
                  textAnchor="middle"
                  fontSize={12}
                  fontWeight={600}
                  paintOrder="stroke"
                  strokeWidth={4}
                  strokeLinejoin="round"
                  style={{ fill: color, stroke: "var(--bg)" }}
                >
                  {node.kind === "zone" ? "" : node.name}
                </text>
              );

              if (node.kind === "suggested") {
                return (
                  <g key={node.id} {...common}>
                    {focusRing}
                    <circle cx={node.x} cy={node.y} r={node.r} strokeWidth={1.5} strokeDasharray="4 4" style={{ fill: "color-mix(in srgb, var(--accent) 10%, transparent)", stroke: "var(--accent)" }} />
                    {name("var(--accent)")}
                  </g>
                );
              }
              if (node.kind === "zone") {
                return (
                  <g key={node.id} {...common}>
                    {isSelected || isFocused ? <circle cx={node.x} cy={node.y} r={node.r + 5} fill="none" strokeWidth={1.5} style={{ stroke: "var(--fg)", opacity: 0.6 }} /> : null}
                    <circle cx={node.x} cy={node.y} r={Math.max(4, node.r * 0.7)} strokeWidth={1.5} style={{ fill: "var(--accent)", stroke: "var(--bg)", opacity: 0.85 }} />
                  </g>
                );
              }
              const level = loadById.get(node.id)?.level;
              const reach = proxById.get(node.id)?.reach;
              return (
                <g key={node.id} {...common}>
                  {focusRing}
                  <circle cx={node.x} cy={node.y} r={node.r + 4} fill="none" strokeWidth={2} style={{ stroke: reach ? REACH_COLOR[reach] : "var(--line)", opacity: 0.9 }} />
                  <circle
                    cx={node.x}
                    cy={node.y}
                    r={node.r}
                    strokeWidth={1}
                    style={{
                      fill: level ? `color-mix(in srgb, ${LEVEL_COLOR[level]} 24%, var(--surface))` : "var(--surface-2)",
                      stroke: level ? `color-mix(in srgb, ${LEVEL_COLOR[level]} 50%, transparent)` : "var(--line)",
                    }}
                  />
                  {level ? <circle cx={node.x} cy={node.y} r={3} style={{ fill: LEVEL_COLOR[level] }} /> : null}
                  {name(strong ? "var(--fg)" : "var(--muted)")}
                </g>
              );
            })}
          </g>
        </svg>

        {tip && nodeById.get(tip.id) ? <NodeReport tip={tip} node={nodeById.get(tip.id)!} label={label} loads={loadById} prox={proxById} distance={distance} t={t} /> : null}


        <div className="absolute top-4 right-4 flex flex-col gap-1 rounded-md bg-surface/95 p-1 shadow-float backdrop-blur">
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
              className="grid size-9 cursor-pointer place-items-center rounded-sm border-0 bg-transparent text-muted hover:bg-surface-2 hover:text-fg focus-visible:outline-3 focus-visible:outline-focus"
            >
              <Icon icon={icon} size={18} />
            </button>
          ))}
        </div>
      </div>

      <GraphGuide
        t={t}
        open={guideOpen}
        onToggle={() => setGuideChoice(!guideOpen)}
        summary={
          layout.nodes.length === 0 ? (
            <p className="m-0 text-sm text-muted">{s.empty}</p>
          ) : (
            <ul className="m-0 flex list-disc flex-col gap-1.5 pl-4 text-sm text-fg marker:text-muted">
              {facts.map((fact) => (
                <li key={fact.kind}>{factText(fact, t, distance)}</li>
              ))}
            </ul>
          )
        }
      />

      <NavDock>
        <section ref={dock} aria-label={s.title} className="flex flex-col gap-3">
          <InsightsHeader view="graph" help={g.help} t={t} />

          {failed ? (
            <p role="alert" className="rounded-sm bg-bad-bg px-3 py-2 text-sm text-bad">
              {s.loadError}
            </p>
          ) : null}

          <div aria-live="polite" className="rounded-md bg-surface-2 p-4">
            {!chosen ? (
              <p className="m-0 text-sm text-muted">{g.hint}</p>
            ) : chosen.kind === "zone" || chosen.kind === "suggested" ? (
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

const CARD_WIDTH = 288;

/**
 * The report of the node being pointed at, in the guide's style: above the node, or below when there is no room above,
 * kept inside the canvas. It never takes the pointer, so moving on to the next node is smooth.
 */
function NodeReport({
  tip,
  node,
  label,
  loads,
  prox,
  distance,
  t,
}: {
  tip: { x: number; top: number; bottom: number; width: number; height: number };
  node: GraphNode;
  label: (node: GraphNode) => string;
  loads: Map<string, StopLoads["stops"][number]>;
  prox: Map<string, Proximity["stops"][number]>;
  distance: (m: number) => string;
  t: Messages;
}) {
  const below = tip.top < 200;
  const left = Math.min(Math.max(tip.x - CARD_WIDTH / 2, 8), Math.max(8, tip.width - CARD_WIDTH - 8));
  return (
    // Screen readers already hear each node's name and figures (its label); the card is for the eye.
    <div
      aria-hidden
      data-graph-report
      className="pointer-events-none absolute z-20 rounded-md bg-surface/95 p-3.5 shadow-float backdrop-blur"
      style={{ width: CARD_WIDTH, left, ...(below ? { top: tip.bottom + 10 } : { bottom: tip.height - tip.top + 10 }) }}
    >
      {node.kind === "stop" ? (
        <StopPanel id={node.id} name={node.name} loads={loads} prox={prox} distance={distance} t={t} />
      ) : (
        <p className="m-0 text-sm font-semibold text-fg">{label(node)}</p>
      )}
    </div>
  );
}

/** One fact of "In short" as a sentence. */
function factText(fact: GraphFact, t: Messages, distance: (m: number) => string): string {
  const f = t.insights.graph.facts;
  switch (fact.kind) {
    case "stops":
      return format(f.stops, { stops: fact.stops, subscribers: fact.subscribers, withArea: fact.withArea });
    case "fullest":
      return format(f.fullest, { stop: fact.stop, level: t.insights.level[fact.level].toLowerCase(), share: formatShare(fact.share) });
    case "allQuiet":
      return f.allQuiet;
    case "farthest":
      return format(f.farthest, { stop: fact.stop, distance: distance(fact.metres) });
    case "nearer":
      return format(f.nearer, { groups: fact.groups, students: fact.students, from: fact.from, to: fact.to });
    case "suggested":
      return format(f.suggested, { count: fact.count, first: fact.first });
    case "notEnough":
      return format(f.notEnough, { stops: fact.stops });
  }
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
        <h2 className="m-0 text-base font-bold">{name}</h2>
        {load?.level ? <Chip tone={LEVEL_TONE[load.level]}>{`${s.level[load.level]} · ${format(s.stop.share, { share: formatShare(load.load ?? 0) })}`}</Chip> : null}
        {near?.reach ? <Chip tone={REACH_TONE[near.reach]}>{s.proximity.reach[near.reach]}</Chip> : null}
      </div>
      <p className="m-0 text-sm text-muted">
        {[
          load && load.departures > 0 ? format(s.stop.perDeparture, { count: Math.round(load.perDeparture * 10) / 10 }) : null,
          near ? format(s.graph.riders, { count: near.subscribers }) : null,
          near && near.median !== null
            ? format(s.proximity.median, { distance: distance(near.median) })
            : near
              ? format(s.proximity.notEnough, { count: near.withArea, min: 5 })
              : null,
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
