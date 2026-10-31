import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import { connection } from "next/server";

import type { Database } from "@/lib/database.types";
import { supabaseConfig } from "@/lib/env";

/**
 * Supabase client for Server Components, Server Actions and Route Handlers.
 * It acts as the signed-in user, so Row Level Security applies to every query.
 * Reads cookies, so call it only inside a <Suspense> boundary or a request-time handler.
 */
export async function createClient() {
  // Everything done with this client is specific to one signed-in user and reads the clock
  // (token expiry), so it must never be prerendered or prefetched. This opts out explicitly.
  await connection();
  const cookieStore = await cookies();
  const { url, key } = supabaseConfig();

  return createServerClient<Database>(url, key, {
    cookies: {
      getAll() {
        return cookieStore.getAll();
      },
      setAll(cookiesToSet) {
        try {
          for (const { name, value, options } of cookiesToSet) {
            cookieStore.set(name, value, options);
          }
        } catch {
          // Called from a Server Component, which cannot set cookies.
          // The proxy refreshes the session on every request, so this is safe to ignore.
        }
      },
    },
  });
}
