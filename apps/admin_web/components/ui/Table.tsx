import type { ReactNode } from "react";

/**
 * The table pieces every list uses, so lists look alike: a raised rounded surface, quiet uppercase
 * headings, rows that tint on hover. They are plain table elements, so screen readers get a real table.
 */

export function TableCard({ children }: { children: ReactNode }) {
  return <div className="overflow-x-auto rounded-lg bg-surface shadow-soft">{children}</div>;
}

export function DataTable({ children, minWidth = "36rem" }: { children: ReactNode; minWidth?: string }) {
  return (
    <table className="w-full border-collapse text-left text-sm" style={{ minWidth }}>
      {children}
    </table>
  );
}

/** The heading row. Give it the column names as <Th> cells. */
export function Head({ children }: { children: ReactNode }) {
  return (
    <thead>
      <tr>{children}</tr>
    </thead>
  );
}

export function Th({ children, className = "" }: { children?: ReactNode; className?: string }) {
  return (
    <th scope="col" className={`px-5 py-4 text-xs font-semibold tracking-wide text-muted uppercase ${className}`}>
      {children}
    </th>
  );
}

export function Tr({ children }: { children: ReactNode }) {
  return <tr className="border-t border-line transition-colors duration-(--dur-fast) hover:bg-surface-2">{children}</tr>;
}

export function Td({ children, className = "" }: { children?: ReactNode; className?: string }) {
  return <td className={`px-5 py-3.5 ${className}`}>{children}</td>;
}
