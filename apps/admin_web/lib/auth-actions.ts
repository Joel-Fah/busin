"use server";

import { cookies, headers } from "next/headers";
import { redirect } from "next/navigation";

import { SIGN_IN_FROM_COOKIE } from "@/lib/sign-in-from";
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

/**
 * Starts Google sign-in. The browser returns to /auth/callback with a one-time code. A form from the student web app
 * sends `from=app`, so an error comes back to its own sign-in page; where a signed-in person lands is decided by role.
 */
export async function signInWithGoogle(formData?: FormData): Promise<void> {
  const fromApp = formData?.get("from") === "app";
  (await cookies()).set(SIGN_IN_FROM_COOKIE, fromApp ? "app" : "portal", { httpOnly: true, sameSite: "lax", path: "/", maxAge: 600 });
  const supabase = await createClient();
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: "google",
    options: {
      redirectTo: `${await siteUrl()}/auth/callback`,
      queryParams: { prompt: "select_account" },
    },
  });

  if (error || !data.url) redirect(fromApp ? "/app/sign-in?error=failed" : "/login?error=generic");
  redirect(data.url);
}

export async function signOut(): Promise<void> {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/login");
}
