"use client";

import { useState } from "react";
import { ArrowDown01Icon, ArrowUp01Icon } from "@hugeicons/core-free-icons";

import { Icon } from "@/components/ui/Icon";
import type { Messages } from "@/lib/i18n/messages";
import type { LoadLevel } from "@/lib/insights";
import type { Reach } from "@/lib/proximity";

export const LEVELS: LoadLevel[] = ["quiet", "fair", "busy", "full"];
export const REACHES: Reach[] = ["near", "walk", "far", "remote"];
export const LEVEL_COLOR: Record<LoadLevel, string> = { quiet: "var(--info)", fair: "var(--ok)", busy: "var(--warn)", full: "var(--bad)" };
export const REACH_COLOR: Record<Reach, string> = { near: "var(--ok)", walk: "var(--info)", far: "var(--warn)", remote: "var(--bad)" };

/** A stop as the graph draws it: a pale disc in the load's colour, a thin ring in the distance's colour. */
export function StopGlyph({ r = 9, level, reach }: { r?: number; level?: LoadLevel; reach?: Reach }) {
  const size = r * 2 + 10;
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} aria-hidden className="shrink-0">
      <circle cx={size / 2} cy={size / 2} r={r + 3} fill="none" strokeWidth={2} style={{ stroke: reach ? REACH_COLOR[reach] : "var(--line)" }} />
      <circle
        cx={size / 2}
        cy={size / 2}
        r={r}
        strokeWidth={1}
        style={{
          fill: level ? `color-mix(in srgb, ${LEVEL_COLOR[level]} 28%, var(--surface))` : "var(--surface-2)",
          stroke: level ? `color-mix(in srgb, ${LEVEL_COLOR[level]} 55%, transparent)` : "var(--line)",
        }}
      />
      {level ? <circle cx={size / 2} cy={size / 2} r={2.5} style={{ fill: LEVEL_COLOR[level] }} /> : null}
    </svg>
  );
}

function Row({ glyph, text }: { glyph: React.ReactNode; text: string }) {
  return (
    <li className="flex items-center gap-3">
      <span className="flex w-16 shrink-0 items-center justify-center gap-1">{glyph}</span>
      <span className="text-xs leading-snug text-fg">{text}</span>
    </li>
  );
}

/**
 * The guide floating beside the graph: "In short" (what the graph shows, in a few sentences) and "How to read" (each
 * shape drawn as it appears). It folds away; the page decides whether it starts open (on a wide screen) and moves the
 * graph aside while it is.
 */
export function GraphGuide({ t, open, onToggle, summary }: { t: Messages; open: boolean; onToggle: () => void; summary: React.ReactNode }) {
  const g = t.insights.graph;
  const [tab, setTab] = useState<"short" | "read">("short");
  return (
    <aside aria-label={g.guide} className="fixed top-4 left-4 z-10 w-[min(21rem,calc(100vw-6rem))] rounded-md bg-surface/95 shadow-float backdrop-blur">
      <div className="flex items-center gap-1 p-1.5">
        {open ? (
          <div role="tablist" aria-label={g.guide} className="flex flex-1 gap-1">
            {(
              [
                ["short", g.inShort],
                ["read", g.readTitle],
              ] as const
            ).map(([id, text]) => (
              <button
                key={id}
                type="button"
                role="tab"
                aria-selected={tab === id}
                onClick={() => setTab(id)}
                className={
                  "cursor-pointer rounded-sm border-0 px-3 py-1.5 font-sans text-sm font-semibold focus-visible:outline-3 focus-visible:outline-focus " +
                  (tab === id ? "bg-surface-2 text-fg" : "bg-transparent text-muted hover:text-fg")
                }
              >
                {text}
              </button>
            ))}
          </div>
        ) : (
          <span className="flex-1 px-3 text-sm font-semibold text-fg">{g.guide}</span>
        )}
        <button
          type="button"
          aria-expanded={open}
          aria-label={open ? g.guideHide : g.guideShow}
          data-tip={open ? g.guideHide : g.guideShow}
          onClick={onToggle}
          className="grid size-8 cursor-pointer place-items-center rounded-sm border-0 bg-transparent text-muted hover:bg-surface-2 hover:text-fg focus-visible:outline-3 focus-visible:outline-focus"
        >
          <Icon icon={open ? ArrowUp01Icon : ArrowDown01Icon} size={18} />
        </button>
      </div>
      {open ? (
        <div role="tabpanel" className="max-h-[calc(100vh-24rem)] overflow-y-auto px-4 pt-1 pb-4">
          {tab === "short" ? (
            summary
          ) : (
            <ul className="m-0 flex list-none flex-col gap-3 p-0">
              <Row
                glyph={
                  <>
                    <StopGlyph r={5} />
                    <StopGlyph r={10} />
                  </>
                }
                text={g.keySize}
              />
              <Row
                glyph={
                  <span className="flex gap-0.5">
                    {LEVELS.map((level) => (
                      <span key={level} className="size-3 rounded-full" style={{ background: `color-mix(in srgb, ${LEVEL_COLOR[level]} 45%, var(--surface))`, boxShadow: `inset 0 0 0 1.5px ${LEVEL_COLOR[level]}` }} />
                    ))}
                  </span>
                }
                text={g.keyFill}
              />
              <Row
                glyph={
                  <span className="flex gap-0.5">
                    {REACHES.map((reach) => (
                      <span key={reach} className="size-3 rounded-full" style={{ boxShadow: `inset 0 0 0 2px ${REACH_COLOR[reach]}` }} />
                    ))}
                  </span>
                }
                text={g.keyRing}
              />
              <Row
                glyph={
                  <svg width="56" height="20" viewBox="0 0 56 20" aria-hidden>
                    <path d="M4 14 L 22 8 L 38 12 L 50 6" fill="none" strokeWidth={6} strokeLinecap="round" strokeLinejoin="round" style={{ stroke: "var(--info)", opacity: 0.25 }} />
                    <rect x="44" y="1" width="10" height="10" rx="2.5" style={{ fill: "var(--fg)" }} />
                  </svg>
                }
                text={g.keyRoute}
              />
              <Row
                glyph={
                  <svg width="56" height="20" viewBox="0 0 56 20" aria-hidden>
                    <path d="M8 14 Q 28 2 46 10" fill="none" strokeWidth={1.5} style={{ stroke: "var(--accent)", opacity: 0.5 }} />
                    <circle cx="8" cy="14" r="4" strokeWidth={1.5} style={{ fill: "var(--accent)", stroke: "var(--surface)" }} />
                  </svg>
                }
                text={g.keyZone}
              />
              <Row
                glyph={
                  <svg width="56" height="20" viewBox="0 0 56 20" aria-hidden>
                    <defs>
                      <marker id="legend-arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="5" markerHeight="5" orient="auto">
                        <path d="M0,0 L10,5 L0,10 z" style={{ fill: "var(--info)" }} />
                      </marker>
                    </defs>
                    <path d="M6 14 Q 28 2 48 10" fill="none" strokeWidth={1.75} strokeDasharray="4 4" markerEnd="url(#legend-arrow)" style={{ stroke: "var(--info)" }} />
                  </svg>
                }
                text={g.keyFlow}
              />
              <Row
                glyph={
                  <svg width="28" height="28" viewBox="0 0 28 28" aria-hidden>
                    <circle cx="14" cy="14" r="10" strokeWidth={1.5} strokeDasharray="3.5 3" style={{ fill: "color-mix(in srgb, var(--accent) 10%, transparent)", stroke: "var(--accent)" }} />
                  </svg>
                }
                text={g.keySuggested}
              />
              <li className="pt-1 text-xs text-muted">{g.keyHow}</li>
            </ul>
          )}
        </div>
      ) : null}
    </aside>
  );
}
