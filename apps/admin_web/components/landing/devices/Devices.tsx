import type { ReactNode } from "react";

/**
 * Devices drawn in HTML for the landing page: a metal frame that follows the theme (light aluminium by day, graphite by
 * night), a black bezel, side buttons, and a screen in the page's own colours. Decorative (the text beside each says
 * the same thing), so they are hidden from screen readers.
 */

const FRAME =
  "bg-linear-to-b from-[#f4f7f8] via-[#d9e1e4] to-[#bfcace] ring-1 ring-black/10 dark:from-[#4a575c] dark:via-[#2b3539] dark:to-[#161d20] dark:ring-white/10";
const BEZEL = "bg-[#080c0e]";

/** The status bar: the time on the left, signal, wifi and battery on the right; the camera sits between them. */
function StatusBar({ time, kind }: { time: ReactNode; kind: "iphone" | "android" }) {
  return (
    <div className="absolute inset-x-0 top-0 z-30 flex h-9 items-center justify-between px-[18px] text-[11px] font-bold tabular-nums text-fg">
      <span>{time}</span>
      {kind === "iphone" ? (
        <span className="absolute left-1/2 top-2 h-[18px] w-[52px] -translate-x-1/2 rounded-[9px] bg-[#080c0e]" />
      ) : (
        <span className="absolute left-1/2 top-3 size-[11px] -translate-x-1/2 rounded-full bg-[#080c0e] ring-2 ring-[#1b2428]" />
      )}
      <span className="flex items-center gap-1">
        <svg viewBox="0 0 17 11" className="h-[8px] w-auto" fill="currentColor">
          <rect x="0" y="7" width="3" height="4" rx="0.8" />
          <rect x="4.6" y="5" width="3" height="6" rx="0.8" />
          <rect x="9.2" y="2.6" width="3" height="8.4" rx="0.8" />
          <rect x="13.8" y="0" width="3" height="11" rx="0.8" />
        </svg>
        <svg viewBox="0 0 16 12" className="h-[8px] w-auto" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
          <path d="M1.5 4.4a9.5 9.5 0 0 1 13 0M4 7.2a6 6 0 0 1 8 0" />
          <circle cx="8" cy="10" r="1.2" fill="currentColor" stroke="none" />
        </svg>
        <span className="relative flex h-[9px] w-[18px] items-center rounded-[3px] border border-current/45 p-[1.5px]">
          <span className="h-full w-[74%] rounded-[1.5px] bg-current" />
          <span className="absolute -right-[3px] h-1 w-[2px] rounded-r-[1px] bg-current/45" />
        </span>
      </span>
    </div>
  );
}

type PhoneProps = { children: ReactNode; time?: ReactNode; kind?: "iphone" | "android"; className?: string };

/** A phone in portrait. iPhone has the island and squarer sides; Android a punch-hole camera and slimmer bezels. */
export function Phone({ children, time = "6:40", kind = "iphone", className = "" }: PhoneProps) {
  const iphone = kind === "iphone";
  return (
    <div aria-hidden className={`relative aspect-[9/18.6] shrink-0 ${className}`}>
      {/* side buttons, just outside the frame */}
      <span className={`absolute -left-[3px] top-[18%] h-7 w-[4px] rounded-l-[2px] ${FRAME}`} />
      {iphone ? <span className={`absolute -left-[3px] top-[26%] h-12 w-[4px] rounded-l-[2px] ${FRAME}`} /> : null}
      <span className={`absolute -right-[3px] top-[24%] h-16 w-[4px] rounded-r-[2px] ${FRAME}`} />
      <div className={`relative size-full rounded-[36px] p-[3px] shadow-float ${FRAME}`}>
        <div className={`size-full rounded-[33px] ${iphone ? "p-[8px]" : "p-[6px]"} ${BEZEL}`}>
          <div className={`relative size-full overflow-hidden bg-bg ${iphone ? "rounded-[25px]" : "rounded-[27px]"}`}>
            <StatusBar time={time} kind={kind} />
            {children}
            <span className="absolute bottom-1.5 left-1/2 z-30 h-1 w-24 -translate-x-1/2 rounded-[2px] bg-fg/70" />
          </div>
        </div>
      </div>
    </div>
  );
}

/** A tablet in landscape, for the driver's and the door staff's view. */
export function Tablet({ children, className = "" }: { children: ReactNode; className?: string }) {
  return (
    <div aria-hidden className={`relative aspect-[4/3] shrink-0 ${className}`}>
      <span className={`absolute -top-[3px] right-[18%] h-[4px] w-10 rounded-t-[2px] ${FRAME}`} />
      <div className={`relative size-full rounded-[28px] p-[3px] shadow-float ${FRAME}`}>
        <div className={`relative size-full rounded-[25px] p-[13px] ${BEZEL}`}>
          <span className="absolute left-1/2 top-[5px] size-[5px] -translate-x-1/2 rounded-full bg-[#1b2428]" />
          <div className="relative size-full overflow-hidden rounded-[12px] bg-bg">{children}</div>
        </div>
      </div>
    </div>
  );
}

/** A laptop: the lid with its screen, and the base seen from the front. */
export function Laptop({ children, className = "" }: { children: ReactNode; className?: string }) {
  return (
    <div aria-hidden className={`relative shrink-0 ${className}`}>
      <div className={`relative mx-auto aspect-[16/10.4] w-[88%] rounded-t-[20px] p-[3px] shadow-float ${FRAME}`}>
        <div className={`relative size-full rounded-t-[17px] px-[12px] pb-[14px] pt-[16px] ${BEZEL}`}>
          <span className="absolute left-1/2 top-[6px] size-[5px] -translate-x-1/2 rounded-full bg-[#1b2428]" />
          <div className="relative size-full overflow-hidden rounded-[8px] bg-bg">{children}</div>
        </div>
      </div>
      <div className={`relative h-4 rounded-b-[16px] ${FRAME}`}>
        <span className="absolute left-1/2 top-0 h-[5px] w-24 -translate-x-1/2 rounded-b-[8px] bg-black/12 dark:bg-black/30" />
      </div>
    </div>
  );
}
