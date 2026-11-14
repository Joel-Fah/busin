/**
 * The parts of an installment plan side by side, each as wide as its share, with its percent and, when a price is known,
 * its amount. Used where a school chooses a plan and where a subscription's parts are shown.
 */
export function PlanParts({ percents, amounts, label }: { percents: number[]; amounts?: string[]; label: string }) {
  return (
    <ol aria-label={label} className="m-0 flex list-none gap-1 p-0">
      {percents.map((percent, index) => (
        <li
          key={index}
          style={{ flexGrow: percent, flexBasis: 0 }}
          className="flex min-w-0 flex-col rounded-xs bg-surface-2 px-2.5 py-2 first:rounded-l-md last:rounded-r-md"
        >
          <span className="text-sm font-bold">{percent}%</span>
          {amounts?.[index] ? <span className="truncate text-xs text-muted">{amounts[index]}</span> : null}
        </li>
      ))}
    </ol>
  );
}
