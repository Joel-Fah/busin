"use client";

import { useState } from "react";
import { Copy01Icon, Delete02Icon, PencilEdit02Icon } from "@hugeicons/core-free-icons";

import { Button } from "@/components/ui/Button";
import { Menu } from "@/components/ui/Menu";
import { Modal } from "@/components/ui/Modal";
import { SideSheet } from "@/components/ui/SideSheet";
import { Tabs } from "@/components/ui/Tabs";

/** Live examples for the styleguide. They hold their own state so each component can be tried. */

export function SheetDemo() {
  const [open, setOpen] = useState(false);
  return (
    <>
      <Button variant="secondary" onClick={() => setOpen(true)}>
        Open the side sheet
      </Button>
      <SideSheet open={open} onClose={() => setOpen(false)} title="A floating side sheet" closeLabel="Close">
        <p className="text-base text-muted">
          It keeps a margin on every side and has rounded corners all round, so it floats above the page instead of
          being docked to the edge. It slides in, closes with Escape, with the button or with a click outside, and
          returns focus to where you were.
        </p>
        <Button onClick={() => setOpen(false)}>Got it</Button>
      </SideSheet>
    </>
  );
}

export function ModalDemo() {
  const [open, setOpen] = useState(false);
  const [done, setDone] = useState(false);
  return (
    <>
      <Button variant="danger" onClick={() => setOpen(true)}>
        Delete a stop
      </Button>
      {done ? <p className="mt-2 text-sm text-muted">Confirmed. Nothing was deleted, this is only an example.</p> : null}
      <Modal
        open={open}
        onClose={() => setOpen(false)}
        title="Delete this stop?"
        description="Students who use it will need to pick another. This cannot be undone."
        actions={
          <>
            <Button variant="secondary" onClick={() => setOpen(false)}>
              Keep it
            </Button>
            <Button
              variant="danger"
              onClick={() => {
                setDone(true);
                setOpen(false);
              }}
            >
              Delete
            </Button>
          </>
        }
      />
    </>
  );
}

export function TabsDemo() {
  const [active, setActive] = useState("pending");
  return (
    <div className="flex flex-col gap-3">
      <Tabs
        label="Filter by status"
        active={active}
        onSelect={setActive}
        items={[
          { id: "pending", label: "To review", href: "#tabs", count: 12, tone: "warn" },
          { id: "approved", label: "Approved", href: "#tabs", count: 148, tone: "ok" },
          { id: "rejected", label: "Rejected", href: "#tabs", count: 3, tone: "bad" },
          { id: "expired", label: "Expired", href: "#tabs", count: 0 },
        ]}
      />
      <p className="text-sm text-muted" data-testid="tabs-demo-state">
        Showing: {active}
      </p>
    </div>
  );
}

export function MenuDemo() {
  const [last, setLast] = useState("none yet");
  return (
    <div className="flex items-center gap-3">
      <Menu
        label="More actions"
        items={[
          { label: "Edit", icon: PencilEdit02Icon, onSelect: () => setLast("Edit") },
          { label: "Duplicate", icon: Copy01Icon, onSelect: () => setLast("Duplicate") },
          { label: "Delete", icon: Delete02Icon, danger: true, onSelect: () => setLast("Delete") },
        ]}
      />
      <p className="text-sm text-muted" data-testid="menu-demo-state">
        Last action: {last}
      </p>
    </div>
  );
}
