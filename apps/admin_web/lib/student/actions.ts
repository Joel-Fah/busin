"use server";

import { redirect } from "next/navigation";

import { createClient } from "@/lib/supabase/server";

/** Ends the session and returns to the student sign-in page. The browser clears its own saved pages first. */
export async function signOutStudent(): Promise<void> {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/app/sign-in");
}
