"use server";

import { notFound, redirect } from "next/navigation";

import { devLoginAllowed } from "@/lib/dev-login";
import { createClient } from "@/lib/supabase/server";

/**
 * Development-only password sign-in for local test accounts (created with `npm run dev:user`).
 * It refuses to run unless this is a development server talking to a backend on this machine.
 * It is not a second way into a real deployment: in a production build it always returns not found.
 */
export async function signInWithPassword(formData: FormData): Promise<void> {
  if (!devLoginAllowed()) notFound();

  const email = formData.get("email");
  const password = formData.get("password");
  if (typeof email !== "string" || typeof password !== "string" || !email || !password) {
    redirect("/dev/login?error=invalid");
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword({ email: email.trim(), password });
  if (error) redirect("/dev/login?error=invalid");

  redirect("/");
}
