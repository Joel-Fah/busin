"use client";

import { useSyncExternalStore } from "react";
import { ComputerIcon, Moon02Icon, Sun03Icon } from "@hugeicons/core-free-icons";

import { THEME_STORAGE_KEY, THEMES, parseTheme, type Theme } from "@/lib/theme";

import { Icon } from "./Icon";

const CHANGE_EVENT = "busin-theme-change";
const ICONS = { system: ComputerIcon, light: Sun03Icon, dark: Moon02Icon } as const;

function subscribe(onChange: () => void) {
  window.addEventListener("storage", onChange);
  window.addEventListener(CHANGE_EVENT, onChange);
  return () => {
    window.removeEventListener("storage", onChange);
    window.removeEventListener(CHANGE_EVENT, onChange);
  };
}

function readTheme(): Theme {
  try {
    return parseTheme(localStorage.getItem(THEME_STORAGE_KEY));
  } catch {
    return "system";
  }
}

function applyTheme(theme: Theme) {
  try {
    if (theme === "system") localStorage.removeItem(THEME_STORAGE_KEY);
    else localStorage.setItem(THEME_STORAGE_KEY, theme);
  } catch {
    // Storage can be blocked; the choice then lasts until the page is closed.
  }
  if (theme === "system") delete document.documentElement.dataset.theme;
  else document.documentElement.dataset.theme = theme;
  window.dispatchEvent(new Event(CHANGE_EVENT));
}

type Props = {
  labels: { group: string } & Record<Theme, string>;
  /** Only the icons show; each button keeps its name for screen readers and as a tooltip. */
  iconOnly?: boolean;
};

/** System, light or dark. The choice stays in this browser and is applied before first paint. */
export function ThemeToggle({ labels, iconOnly = false }: Props) {
  const current = useSyncExternalStore(subscribe, readTheme, () => "system" as Theme);

  return (
    <div role="group" aria-label={labels.group} className="inline-flex gap-1 rounded-md bg-surface-2 p-1">
      {THEMES.map((theme) => (
        <button
          key={theme}
          type="button"
          aria-pressed={current === theme}
          aria-label={iconOnly ? labels[theme] : undefined}
          title={iconOnly ? labels[theme] : undefined}
          onClick={() => applyTheme(theme)}
          className={
            "inline-flex h-10 cursor-pointer items-center justify-center gap-2 rounded-sm border-0 font-sans text-sm font-semibold " +
            (iconOnly ? "w-10 px-0 " : "px-4 ") +
            "transition-colors duration-(--dur-fast) focus-visible:outline-3 focus-visible:outline-focus " +
            (current === theme ? "bg-surface text-fg shadow-soft" : "bg-transparent text-muted hover:text-fg")
          }
        >
          <Icon icon={ICONS[theme]} size={18} />
          {iconOnly ? null : labels[theme]}
        </button>
      ))}
    </div>
  );
}
