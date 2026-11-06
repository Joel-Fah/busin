"use client";

import { Alert02Icon, Cancel01Icon, CancelCircleIcon, CheckmarkCircle02Icon, InformationCircleIcon } from "@hugeicons/core-free-icons";
import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState, type ReactNode } from "react";

import { nextToast, toastDuration, type ToastItem, type ToastTone } from "@/lib/ui/toast";

import { Contour } from "./Contour";
import { Icon } from "./Icon";

type Show = (message: string, options?: { tone?: ToastTone; title?: string; duration?: number }) => void;

const ToastContext = createContext<Show>(() => {});

/** `const toast = useToast(); toast("Stop saved.", { tone: "ok" })`. Does nothing outside a ToastProvider. */
export function useToast(): Show {
  return useContext(ToastContext);
}

/** Keep in step with `toast-out` in theme.css. */
const TOAST_EXIT_MS = 380;

const LOOK = {
  ok: { box: "bg-ok-bg text-ok", icon: CheckmarkCircle02Icon },
  info: { box: "bg-info-bg text-info", icon: InformationCircleIcon },
  warn: { box: "bg-warn-bg text-warn", icon: Alert02Icon },
  bad: { box: "bg-bad-bg text-bad", icon: CancelCircleIcon },
} as const;

/**
 * Short messages that float at the top and go away by themselves, with the stitched thread and an icon for the
 * state. One at a time. Successes are announced politely (status), problems at once (alert). It is for
 * confirmations and reminders; an error the person must act on stays on the page too.
 */
export function ToastProvider({ children, closeLabel = "Close" }: { children: ReactNode; closeLabel?: string }) {
  const [toast, setToast] = useState<ToastItem | null>(null);
  const counter = useRef(0);
  const [leaving, setLeaving] = useState(false);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const exit = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Leaving takes a moment so the toast can glide away instead of vanishing.
  const dismiss = useCallback((id?: number) => {
    if (timer.current) clearTimeout(timer.current);
    if (exit.current) clearTimeout(exit.current);
    setLeaving(true);
    exit.current = setTimeout(() => {
      setToast((c) => (id === undefined || c?.id === id ? null : c));
      setLeaving(false);
    }, TOAST_EXIT_MS);
  }, []);

  const show = useCallback<Show>((message, options = {}) => {
    const tone = options.tone ?? "info";
    const item: ToastItem = { id: ++counter.current, tone, message, title: options.title, duration: toastDuration(tone, options.duration) };
    if (timer.current) clearTimeout(timer.current);
    if (exit.current) clearTimeout(exit.current);
    setLeaving(false);
    setToast((current) => nextToast(current, item));
    timer.current = setTimeout(() => dismiss(item.id), item.duration);
  }, [dismiss]);

  useEffect(() => () => {
    if (timer.current) clearTimeout(timer.current);
    if (exit.current) clearTimeout(exit.current);
  }, []);

  const value = useMemo(() => show, [show]);

  return (
    <ToastContext.Provider value={value}>
      {children}
      <div className="pointer-events-none fixed inset-x-0 top-4 z-[100] flex justify-center px-4">
        {toast && (
          <div
            key={toast.id}
            role={toast.tone === "bad" || toast.tone === "warn" ? "alert" : "status"}
            className={`${leaving ? "toast-out" : "toast-in"} pointer-events-auto relative flex w-full max-w-md items-start gap-3 rounded-md px-5 py-4 text-sm shadow-float ${LOOK[toast.tone].box}`}
            style={{ ["--thread-color" as string]: "currentColor" }}
          >
            <Contour radius={20} inset={4} dash={[5, 5]} />
            <Icon icon={LOOK[toast.tone].icon} size={22} className="mt-0.5 shrink-0" />
            <div className="min-w-0 flex-1 text-fg">
              {toast.title && <p className="font-bold">{toast.title}</p>}
              <p>{toast.message}</p>
            </div>
            <button
              type="button"
              onClick={() => dismiss(toast.id)}
              aria-label={closeLabel}
              className="relative -m-1 grid size-9 shrink-0 place-items-center rounded-full text-current opacity-80 transition-[opacity,background-color,transform] duration-[var(--dur-fast)] ease-[var(--ease-soft)] hover:bg-current/10 hover:opacity-100 focus-visible:opacity-100 focus-visible:outline-2 focus-visible:outline-offset-1 focus-visible:outline-current active:scale-90"
            >
              {/* The ring empties as the time runs out. */}
              <svg viewBox="0 0 36 36" className="pointer-events-none absolute inset-0 -rotate-90" aria-hidden="true">
                <circle cx="18" cy="18" r="16" fill="none" stroke="currentColor" strokeOpacity="0.18" strokeWidth="2" />
                {!leaving && (
                  <circle
                    key={toast.id}
                    className="toast-ring"
                    cx="18"
                    cy="18"
                    r="16"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    pathLength={100}
                    strokeDasharray={100}
                    style={{ animationDuration: `${toast.duration}ms` }}
                  />
                )}
              </svg>
              <Icon icon={Cancel01Icon} size={14} />
            </button>
          </div>
        )}
      </div>
    </ToastContext.Provider>
  );
}
