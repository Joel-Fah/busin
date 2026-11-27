"use client";

import { Contour } from "@/components/ui/Contour";
import { Button } from "@/components/ui/Button";
import type { StudentCopy } from "@/lib/i18n/student";
import { MAP_COLORS } from "@/lib/student/bus-map";

import { Sheet } from "./Sheet";

/** A marker as the map draws it: a filled circle with a white edge, and a soft ring for those that ping. */
function Dot({ color, size, ring = false }: { color: string; size: number; ring?: boolean }) {
  const dot = <span className="block rounded-full border-[2.5px] border-white shadow-soft" style={{ width: size, height: size, background: color }} />;
  if (!ring) return dot;
  return (
    <span className="grid place-items-center rounded-full" style={{ width: size + 10, height: size + 10, background: `color-mix(in srgb, ${color} 22%, transparent)` }}>
      {dot}
    </span>
  );
}

/** A short stretch of line: the route solid, the trail dashed. */
function Line({ color, dashed = false }: { color: string; dashed?: boolean }) {
  if (!dashed) return <span className="block h-1 w-8 rounded-xs opacity-60" style={{ background: color }} />;
  return (
    <span className="flex gap-[3px] opacity-55">
      {[0, 1, 2, 3].map((i) => (
        <span key={i} className="block h-[3px] w-[5px] rounded-xs" style={{ background: color }} />
      ))}
    </span>
  );
}

/** What the bus map shows, as in the app: each marker and line in its own colour, then how the tab works. */
export function BusLegend({ open, onClose, copy }: { open: boolean; onClose: () => void; copy: StudentCopy["bus"]["legend"] }) {
  const rows: [React.ReactNode, string][] = [
    [<Dot key="mine" color={MAP_COLORS.myStop} size={16} ring />, copy.myStop],
    [<Dot key="stop" color={MAP_COLORS.stop} size={11} />, copy.stop],
    [<Dot key="bus" color={MAP_COLORS.bus} size={18} ring />, copy.bus],
    [<Dot key="me" color={MAP_COLORS.me} size={15} />, copy.me],
    [<Dot key="campus" color={MAP_COLORS.campus} size={18} />, copy.campus],
    [<Line key="route" color={MAP_COLORS.route} />, copy.route],
    [<Line key="trail" color={MAP_COLORS.trail} dashed />, copy.trail],
  ];
  return (
    <Sheet open={open} onClose={onClose} label={copy.title} placement="bottom">
      <Contour radius={36} inset={12} />
      <div className="relative flex flex-col gap-4 px-7 pt-4 pb-2" data-testid="bus-legend">
        <span aria-hidden className="mx-auto h-1.5 w-12 rounded-full bg-line" />
        <h2 className="m-0 text-xl font-extrabold tracking-tight">{copy.title}</h2>
        <ul className="m-0 flex list-none flex-col gap-3 p-0">
          {rows.map(([swatch, words]) => (
            <li key={words} className="flex items-start gap-3 text-sm">
              <span aria-hidden className="grid h-[22px] w-9 shrink-0 place-items-center">
                {swatch}
              </span>
              <span>{words}</span>
            </li>
          ))}
        </ul>
        <p className="m-0 rounded-md bg-info-bg px-5 py-4 text-sm text-info">{copy.how}</p>
        <Button variant="secondary" onClick={onClose} className="w-full">
          {copy.close}
        </Button>
      </div>
    </Sheet>
  );
}
