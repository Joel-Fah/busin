"use client";

import { useEffect, useRef, useState, type ComponentProps } from "react";

import { browserClient } from "@/lib/supabase/browser";

import { FloatingNav, type NavKey } from "./FloatingNav";

type Counts = Partial<Record<NavKey, number>>;

/** The same three counts the layout reads on the server: head-only for the first two, ids and reasons for the third. */
async function readCounts(): Promise<Counts | null> {
  const supabase = browserClient();
  const [subscriptions, people, overdue] = await Promise.all([
    supabase.from("subscriptions").select("id", { count: "exact", head: true }).eq("status", "pending"),
    supabase.from("profiles").select("id", { count: "exact", head: true }).eq("role", "student").eq("status", "pending").not("join_requested_at", "is", null),
    supabase.rpc("admin_overdue_trips"),
  ]);
  if (subscriptions.error || people.error || overdue.error) return null;
  return { subscriptions: subscriptions.count ?? 0, people: people.count ?? 0, trips: overdue.data?.length ?? 0 };
}

/**
 * The portal's navigation with its badges kept live: a Realtime listener on the school's subscriptions and accounts (RLS
 * limits it to this admin's school; filtered by school too) recounts only the badges when one changes, a second or so
 * after the last change. Trips running too long are not a table event, so they are recounted every minute. Only while the
 * tab is visible; coming back recounts at once.
 */
export function LiveFloatingNav({ schoolId, counts: initial, ...props }: ComponentProps<typeof FloatingNav> & { schoolId: string }) {
  const [counts, setCounts] = useState<Counts>(initial ?? {});
  const timer = useRef<number | null>(null);

  useEffect(() => {
    const supabase = browserClient();
    let channel: ReturnType<typeof supabase.channel> | null = null;
    let stopped = false;

    const recount = () => {
      if (timer.current) window.clearTimeout(timer.current);
      timer.current = window.setTimeout(async () => {
        const next = await readCounts();
        if (next && !stopped) setCounts(next);
      }, 1200);
    };
    const open = async () => {
      if (channel) return;
      const { data } = await supabase.auth.getSession();
      if (stopped || channel || !data.session) return;
      await supabase.realtime.setAuth(data.session.access_token);
      if (stopped || channel) return;
      channel = supabase
        .channel(`nav-counts:${schoolId}`)
        .on("postgres_changes", { event: "*", schema: "public", table: "subscriptions", filter: `school_id=eq.${schoolId}` }, recount)
        .on("postgres_changes", { event: "*", schema: "public", table: "profiles", filter: `school_id=eq.${schoolId}` }, recount)
        .subscribe();
    };
    const close = () => {
      if (channel) void supabase.removeChannel(channel);
      channel = null;
    };
    const onVisible = () => {
      if (document.visibilityState === "visible") {
        void open();
        recount();
      } else close();
    };
    const minute = window.setInterval(() => {
      if (document.visibilityState === "visible") recount();
    }, 60_000);

    if (document.visibilityState === "visible") void open();
    document.addEventListener("visibilitychange", onVisible);
    return () => {
      stopped = true;
      document.removeEventListener("visibilitychange", onVisible);
      window.clearInterval(minute);
      if (timer.current) window.clearTimeout(timer.current);
      close();
    };
  }, [schoolId]);

  // A server render (after an action) brings fresh counts too: take them when they change.
  const [fromServer, setFromServer] = useState(initial);
  if (initial !== fromServer) {
    setFromServer(initial);
    if (initial) setCounts(initial);
  }

  return <FloatingNav {...props} counts={counts} />;
}
