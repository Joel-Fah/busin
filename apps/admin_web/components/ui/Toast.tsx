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
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const dismiss = useCallback(() => {
    if (timer.current) clearTimeout(timer.current);
    setToast(null);
  }, []);

  const show = useCallback<Show>((message, options = {}) => {
    const tone = options.tone ?? "info";
    const item: ToastItem = { id: ++counter.current, tone, message, title: options.title, duration: toastDuration(tone, options.duration) };
    if (timer.current) clearTimeout(timer.current);
    setToast((current) => nextToast(current, item));
    timer.current = setTimeout(() => setToast((c) => (c?.id === item.id ? null : c)), item.duration);
  }, []);

  useEffect(() => () => {
    if (timer.current) clearTimeout(timer.current);
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
            className={`toast-in pointer-events-auto relative flex w-full max-w-md items-start gap-3 rounded-md px-5 py-4 text-sm shadow-float ${LOOK[toast.tone].box}`}
            style={{ ["--thread-color" as string]: "currentColor" }}
          >
            <Contour radius={20} inset={4} dash={[5, 5]} />
            <Icon icon={LOOK[toast.tone].icon} size={22} className="mt-0.5 shrink-0" />
            <div className="min-w-0 flex-1 text-fg">
              {toast.title && <p className="font-bold">{toast.title}</p>}
              <p>{toast.message}</p>
            </div>
            <button type="button" onClick={dismiss} aria-label={closeLabel} className="-m-1 rounded-sm p-1 text-muted hover:text-fg">
              <Icon icon={Cancel01Icon} size={18} />
            </button>
          </div>
        )}
      </div>
    </ToastContext.Provider>
  );
}
