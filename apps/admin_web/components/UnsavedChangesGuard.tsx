"use client";

import { useRouter } from "next/navigation";
import { useEffect, useRef, useState } from "react";

import { Button } from "@/components/ui/Button";
import { Modal } from "@/components/ui/Modal";

type Copy = { title: string; body: string; stay: string; save: string; leave: string };

/** What the form holds now, as text, to compare with how it was when the page opened. Files are left out. */
function snapshot(form: HTMLFormElement): string {
  const entries: [string, string][] = [];
  for (const [name, value] of new FormData(form)) {
    if (name === "next" || name.startsWith("$ACTION")) continue;
    if (typeof value === "string") entries.push([name, value]);
  }
  return JSON.stringify(entries);
}

/**
 * Keeps a form's changes from being lost by mistake: the form only saves when its button is pressed, and it is easy to
 * think it saves by itself. While the form differs from how the page opened:
 * - following a link (the navigation, a card, Back) opens a dialog: go back to the form, save and go on, or leave
 *   without saving;
 * - closing or reloading the tab gets the browser's own warning.
 * "Save and continue" sends the form with the address to go to (`next`); the server goes there once it has saved, or
 * comes back to the form with what is wrong.
 */
export function UnsavedChangesGuard({ formId, copy }: { formId: string; copy: Copy }) {
  const router = useRouter();
  const initial = useRef<string | null>(null);
  const submitting = useRef(false);
  const [target, setTarget] = useState<string | null>(null);

  useEffect(() => {
    const form = document.getElementById(formId) as HTMLFormElement | null;
    if (!form) return;
    // After the fields have settled (a phone field formats its number on the first render).
    const frame = requestAnimationFrame(() => (initial.current = snapshot(form)));
    const dirty = () => !submitting.current && initial.current !== null && snapshot(form) !== initial.current;

    const onSubmit = () => {
      submitting.current = true;
    };
    const onClick = (event: MouseEvent) => {
      if (event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
      const link = (event.target as Element | null)?.closest?.("a[href]") as HTMLAnchorElement | null;
      if (!link || link.target === "_blank" || link.hasAttribute("download")) return;
      const url = new URL(link.href, window.location.href);
      // A link to a part of this same page is not leaving it.
      if (url.origin === window.location.origin && url.pathname === window.location.pathname && url.search === window.location.search && url.hash) return;
      if (!dirty()) return;
      event.preventDefault();
      event.stopPropagation();
      setTarget(url.origin === window.location.origin ? `${url.pathname}${url.search}${url.hash}` : url.href);
    };
    const onUnload = (event: BeforeUnloadEvent) => {
      if (!dirty()) return;
      event.preventDefault();
      // Older browsers need a value set to show their warning.
      event.returnValue = "";
    };

    form.addEventListener("submit", onSubmit);
    // Capture, so the dialog opens before the router follows the link.
    document.addEventListener("click", onClick, true);
    window.addEventListener("beforeunload", onUnload);
    return () => {
      cancelAnimationFrame(frame);
      form.removeEventListener("submit", onSubmit);
      document.removeEventListener("click", onClick, true);
      window.removeEventListener("beforeunload", onUnload);
    };
  }, [formId]);

  const go = (to: string) => {
    submitting.current = true;
    if (to.startsWith("/")) router.push(to);
    else window.location.assign(to);
  };

  const saveAndGo = () => {
    const form = document.getElementById(formId) as HTMLFormElement | null;
    if (!form || !target) return;
    let next = form.querySelector<HTMLInputElement>('input[name="next"]');
    if (!next) {
      next = document.createElement("input");
      next.type = "hidden";
      next.name = "next";
      form.appendChild(next);
    }
    // Only an address on this site goes to the server; another site is opened after the save from the form page.
    next.value = target.startsWith("/") ? target : "";
    setTarget(null);
    form.requestSubmit();
  };

  return (
    <Modal
      open={target !== null}
      onClose={() => setTarget(null)}
      title={copy.title}
      description={copy.body}
      actions={
        <>
          <Button variant="ghost" onClick={() => target && go(target)}>
            {copy.leave}
          </Button>
          <Button variant="secondary" onClick={() => setTarget(null)}>
            {copy.stay}
          </Button>
          <Button onClick={saveAndGo}>{copy.save}</Button>
        </>
      }
    />
  );
}
