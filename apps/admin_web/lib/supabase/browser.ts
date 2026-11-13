"use client";

import { createBrowserClient } from "@supabase/ssr";
import type { SupabaseClient } from "@supabase/supabase-js";

import type { Database } from "@/lib/database.types";
import { supabaseConfig } from "@/lib/env";

let client: SupabaseClient<Database> | null = null;

/**
 * The browser's client, for what must be live or must not pass through the server: Realtime, file uploads and the
 * student web app's sign-in. It shares the session cookie the server reads. One per tab.
 */
export function browserClient(): SupabaseClient<Database> {
  if (!client) {
    const { url, key } = supabaseConfig();
    client = createBrowserClient<Database>(url, key);
  }
  return client;
}
