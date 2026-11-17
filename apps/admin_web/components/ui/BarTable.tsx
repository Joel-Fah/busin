import { TONE_BAR, TONE_TEXT, toneOf, type ToneRule } from "@/lib/money-tones";
import { barPercent } from "@/lib/payments";

import { DataTable, Head, TableCard, Td, Th, Tr } from "./Table";

export type BarTableRow = {
  key: string;
  /** The row's name, read first: a month, a stop. */
  label: string;
  /** The figures by column key, and how each is written. */
  values: Record<string, number>;
  display: Record<string, string>;
  /** The exact figure where `display` is written short (120K XAF): shown on hover and read by screen readers. */
  full?: Record<string, string>;
};

type Props = {
  caption: string;
  /** The heading of the first column (what the rows are). */
  rowHeading: string;
  /** Each measure, with its state colour: money in (ok), money out (bad), waiting (warn), payouts (info), or "signed" for
   * one that is good above zero and bad below (a margin). Without one, a quiet neutral. */
  columns: { key: string; label: string; tone?: ToneRule }[];
  rows: BarTableRow[];
  /** A row to set apart (the current month), with the words that say why, so it is never colour alone. */
  highlight?: { key: string; label: string };
};

/**
 * A table whose figures each carry a thin bar, scaled to the largest figure in the whole table, so sizes compare across
 * rows and columns at a glance while every number stays readable as text. It is a real table, so screen readers and a
 * keyboard get the figures without the bars. Each column's bars take its state colour (a dot beside its heading repeats
 * it, and the heading names the measure, so colour is never the only sign); a signed column colours each figure by its
 * sign. The highlighted row's bars are full strength and its name says why; the others are softer.
 */
export function BarTable({ caption, rowHeading, columns, rows, highlight }: Props) {
  const max = Math.max(0, ...rows.flatMap((row) => columns.map((c) => Math.abs(row.values[c.key] ?? 0))));
  return (
    <TableCard>
      <DataTable minWidth={`${10 + columns.length * 8}rem`}>
        <caption className="sr-only">{caption}</caption>
        <Head>
          <Th>{rowHeading}</Th>
          {columns.map((c) => (
            <Th key={c.key} className="text-right">
              <span className="inline-flex items-center gap-1.5">
                {c.tone ? <span aria-hidden className={`size-2 rounded-full ${TONE_BAR[c.tone === "signed" ? "ok" : c.tone]}`} /> : null}
                {c.label}
              </span>
            </Th>
          ))}
        </Head>
        <tbody>
          {rows.map((row) => {
            const lit = highlight?.key === row.key;
            return (
              <Tr key={row.key}>
                <th scope="row" className="px-5 py-3.5 text-left font-semibold whitespace-nowrap capitalize">
                  {row.label}
                  {lit ? <span className="ml-2 text-xs font-semibold text-muted normal-case">{highlight.label}</span> : null}
                </th>
                {columns.map((c) => {
                  const value = row.values[c.key] ?? 0;
                  const width = barPercent(Math.abs(value), max);
                  const tone = c.tone ? toneOf(c.tone, value) : "neutral";
                  return (
                    <Td key={c.key} className="text-right">
                      {row.full?.[c.key] && row.full[c.key] !== row.display[c.key] ? (
                        <span
                          data-tip={row.full[c.key]}
                          tabIndex={0}
                          className={`relative block cursor-help font-semibold whitespace-nowrap tabular-nums ${c.tone === "signed" ? TONE_TEXT[tone] : ""}`}
                        >
                          <span aria-hidden>{row.display[c.key]}</span>
                          <span className="sr-only">{row.full[c.key]}</span>
                        </span>
                      ) : (
                        <span className={`block font-semibold whitespace-nowrap tabular-nums ${c.tone === "signed" ? TONE_TEXT[tone] : ""}`}>{row.display[c.key]}</span>
                      )}
                      <span aria-hidden className="mt-1.5 flex h-1.5 rounded-[3px] bg-surface-2" data-tip={`${c.label}: ${row.display[c.key]}`}>
                        {width > 0 ? (
                          <span
                            className={`block h-full rounded-[3px] ${TONE_BAR[tone]} ${lit || !c.tone ? "" : "opacity-60"} ${lit && !c.tone ? "bg-accent!" : ""}`}
                            style={{ width: `${width}%` }}
                          />
                        ) : null}
                      </span>
                    </Td>
                  );
                })}
              </Tr>
            );
          })}
        </tbody>
      </DataTable>
    </TableCard>
  );
}
