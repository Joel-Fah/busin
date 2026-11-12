"use server";

import { headers } from "next/headers";
import { redirect } from "next/navigation";

import { createClient } from "@/lib/supabase/server";

/** The public address of this site, used to tell Google where to send the user back. */
async function siteUrl(): Promise<string> {
  const configured = process.env.SITE_URL;
  if (configured) return configured.replace(/\/$/, "");

  const requestHeaders = await headers();
  const host = requestHeaders.get("x-forwarded-host") ?? requestHeaders.get("host");
  const protocol = requestHeaders.get("x-forwarded-proto") ?? (host?.startsWith("127.0.0.1") ? "http" : "https");
  return `${protocol}://${host}`;
}

/** Starts Google sign-in. The browser returns to /auth/callback with a one-time code. */
export async function signInWithGoogle(): Promise<void> {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: "google",
    options: {
      redirectTo: `${await siteUrl()}/auth/callback`,
      queryParams: { prompt: "select_account" },
    },
  });

  if (error || !data.url) redirect("/login?error=generic");
  redirect(data.url);
}

export async function signOut(): Promise<void> {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/login");
}
