"use client";

import { Download04Icon } from "@hugeicons/core-free-icons";
import { useEffect, useState, useSyncExternalStore } from "react";

import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import type { StudentCopy } from "@/lib/i18n/student";

type InstallPrompt = Event & { prompt(): Promise<void>; userChoice: Promise<{ outcome: string }> };

const DISMISSED = "busin-install-dismissed";

function storedDismissal(): boolean {
  try {
    return window.localStorage.getItem(DISMISSED) === "1";
  } catch {
    return false;
  }
}

type Setting = "server" | "installed" | "dismissed" | "ios" | "other";

/** What this browser is: already running the installed app, dismissed the offer before, an iPhone or iPad, or anything else. */
function readSetting(): Setting {
  const standalone = window.matchMedia("(display-mode: standalone)").matches || (navigator as Navigator & { standalone?: boolean }).standalone === true;
  if (standalone) return "installed";
  if (storedDismissal()) return "dismissed";
  const ios = /iphone|ipad|ipod/i.test(navigator.userAgent) || (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);
  return ios ? "ios" : "other";
}

const noSubscription = () => () => {};

/**
 * Offers to install the web app: the browser's own prompt where there is one (Chrome, Edge, Samsung Internet), and the
 * Share steps on an iPhone, where it is the only way to get notifications. Hidden once installed or dismissed.
 */
export function InstallCard({ copy }: { copy: StudentCopy["install"] }) {
  const setting = useSyncExternalStore(noSubscription, readSetting, () => "server" as Setting);
  const [prompt, setPrompt] = useState<InstallPrompt | null>(null);
  const [closed, setClosed] = useState(false);

  useEffect(() => {
    const onPrompt = (event: Event) => {
      event.preventDefault();
      setPrompt(event as InstallPrompt);
    };
    const onInstalled = () => setClosed(true);
    window.addEventListener("beforeinstallprompt", onPrompt);
    window.addEventListener("appinstalled", onInstalled);
    return () => {
      window.removeEventListener("beforeinstallprompt", onPrompt);
      window.removeEventListener("appinstalled", onInstalled);
    };
  }, []);

  const offered = setting === "ios" || (setting === "other" && prompt !== null);
  if (closed || !offered) return null;
  const ios = setting === "ios";

  const dismiss = () => {
    try {
      window.localStorage.setItem(DISMISSED, "1");
    } catch {
      // Private mode: it shows again next time.
    }
    setClosed(true);
  };

  return (
    <section aria-labelledby="install-title" className="flex flex-col gap-3 rounded-lg bg-surface p-5 shadow-soft" data-testid="install-card">
      <div className="flex items-start gap-3">
        <span className="grid size-10 shrink-0 place-items-center rounded-sm bg-accent text-on-accent">
          <Icon icon={Download04Icon} size={20} />
        </span>
        <div className="min-w-0">
          <h2 id="install-title" className="m-0 text-base font-bold">
            {copy.title}
          </h2>
          <p className="m-0 mt-1 text-sm text-muted">{ios && !prompt ? copy.iosBody : copy.body}</p>
        </div>
      </div>
      <div className="flex flex-wrap gap-2">
        {prompt ? (
          <Button
            onClick={async () => {
              await prompt.prompt();
              await prompt.userChoice;
              setPrompt(null);
              setClosed(true);
            }}
          >
            {copy.button}
          </Button>
        ) : null}
        <Button variant="ghost" onClick={dismiss}>
          {copy.dismiss}
        </Button>
      </div>
    </section>
  );
}
