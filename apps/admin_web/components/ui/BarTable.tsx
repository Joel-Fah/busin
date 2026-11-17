import { barPercent } from "@/lib/payments";

import { DataTable, Head, TableCard, Td, Th, Tr } from "./Table";

export type BarTableRow = {
  key: string;
  /** The row's name, read first: a month, a stop. */
  label: string;
  /** The figures by column key, and how each is written. */
  values: Record<string, number>;
  display: Record<string, string>;
};

type Props = {
  caption: string;
  /** The heading of the first column (what the rows are). */
  rowHeading: string;
  columns: { key: string; label: string }[];
  rows: BarTableRow[];
  /** A row to set apart (the current month), with the words that say why, so it is never colour alone. */
  highlight?: { key: string; label: string };
};

/**
 * A table whose figures each carry a thin bar, scaled to the largest figure in the whole table, so sizes compare across
 * rows and columns at a glance while every number stays readable as text. It is a real table, so screen readers and a
 * keyboard get the figures without the bars. One quiet hue for every bar: the column heading names the measure. The
 * highlighted row's bars take the accent and its name says why.
 */
export function BarTable({ caption, rowHeading, columns, rows, highlight }: Props) {
  const max = Math.max(0, ...rows.flatMap((row) => columns.map((c) => row.values[c.key] ?? 0)));
  return (
    <TableCard>
      <DataTable minWidth={`${10 + columns.length * 8}rem`}>
        <caption className="sr-only">{caption}</caption>
        <Head>
          <Th>{rowHeading}</Th>
          {columns.map((c) => (
            <Th key={c.key} className="text-right">
              {c.label}
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
                  const width = barPercent(value, max);
                  return (
                    <Td key={c.key} className="text-right">
                      <span className="block font-semibold whitespace-nowrap tabular-nums">{row.display[c.key]}</span>
                      <span aria-hidden className="mt-1.5 flex h-1.5 rounded-[3px] bg-surface-2" data-tip={`${c.label}: ${row.display[c.key]}`}>
                        {width > 0 ? (
                          <span
                            className={`block h-full rounded-[3px] ${lit ? "bg-accent" : "bg-[color-mix(in_srgb,var(--fg)_30%,transparent)]"}`}
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
