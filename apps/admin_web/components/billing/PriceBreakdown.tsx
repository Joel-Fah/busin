import { DataTable, Head, TableCard, Td, Th, Tr } from "@/components/ui/Table";

export type BreakdownRowView = { method: string; studentPays: string; businCharge: string; transactionCost: string; schoolReceives: string };

type Props = {
  caption: string;
  rows: BreakdownRowView[];
  labels: { method: string; studentPays: string; businCharge: string; transactionCost: string; schoolReceives: string };
  /** Dims the figures while a newer answer is on its way. */
  busy?: boolean;
};

/**
 * What a price means per way of paying: what the student pays, BusIn's charge, the transfer cost and what the school
 * receives. One row per way of paying, the figures right-aligned so they compare down a column; the last column, what
 * the school receives, is bold because it is the one the school is choosing for.
 */
export function PriceBreakdown({ caption, rows, labels, busy = false }: Props) {
  return (
    <TableCard>
      <div aria-busy={busy || undefined} className={`transition-opacity duration-(--dur-fast) ${busy ? "opacity-60" : ""}`}>
        <DataTable minWidth="34rem">
          <caption className="sr-only">{caption}</caption>
          <Head>
            <Th>{labels.method}</Th>
            <Th className="text-right">{labels.studentPays}</Th>
            <Th className="text-right">{labels.businCharge}</Th>
            <Th className="text-right">{labels.transactionCost}</Th>
            <Th className="text-right">{labels.schoolReceives}</Th>
          </Head>
          <tbody>
            {rows.map((row) => (
              <Tr key={row.method}>
                <th scope="row" className="px-5 py-3.5 font-semibold">
                  {row.method}
                </th>
                <Td className="text-right whitespace-nowrap tabular-nums">{row.studentPays}</Td>
                <Td className="text-right whitespace-nowrap tabular-nums text-muted">{row.businCharge}</Td>
                <Td className="text-right whitespace-nowrap tabular-nums text-muted">{row.transactionCost}</Td>
                <Td className="text-right font-bold whitespace-nowrap tabular-nums">{row.schoolReceives}</Td>
              </Tr>
            ))}
          </tbody>
        </DataTable>
      </div>
    </TableCard>
  );
}
