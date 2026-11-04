import { Skeleton } from "./Skeleton";

/**
 * What a page with tabs and a list looks like while it loads: the same shapes in the same places, so
 * nothing jumps when the real content arrives.
 */
export function ListSkeleton({ rows = 6 }: { rows?: number }) {
  return (
    <section aria-busy="true" aria-label="Loading" className="flex flex-col gap-6">
      <div className="flex flex-col gap-3">
        <Skeleton className="h-12 w-72 sm:w-96" />
        <Skeleton className="h-4 w-80 max-w-full" />
      </div>
      <Skeleton className="h-12 w-full max-w-xl" />
      <div className="flex flex-col gap-3 rounded-lg bg-surface p-5 shadow-soft">
        {Array.from({ length: rows }, (_, index) => (
          <div key={index} className="flex items-center gap-4">
            <Skeleton className="size-10 shrink-0" />
            <Skeleton className="h-4 w-1/4" />
            <Skeleton className="hidden h-4 w-1/5 sm:block" />
            <Skeleton className="ml-auto h-6 w-20" />
          </div>
        ))}
      </div>
    </section>
  );
}
