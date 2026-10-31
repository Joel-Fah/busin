import { supabaseConfig } from "@/lib/env";

const LOCAL_HOSTS = new Set(["127.0.0.1", "localhost", "[::1]"]);

/**
 * True only for a development server talking to a backend on this same machine.
 * Both conditions must hold. In a production build `NODE_ENV` is "production", so the
 * development-only sign-in page and action refuse to run, whatever the backend address is.
 */
export function isLocalDevelopment(nodeEnv: string | undefined, supabaseUrl: string): boolean {
  if (nodeEnv !== "development") return false;
  try {
    return LOCAL_HOSTS.has(new URL(supabaseUrl).hostname);
  } catch {
    return false;
  }
}

/** Whether the development-only sign-in is available for this process. */
export function devLoginAllowed(): boolean {
  return isLocalDevelopment(process.env.NODE_ENV, supabaseConfig().url);
}
