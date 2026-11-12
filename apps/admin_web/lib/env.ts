/**
 * Public configuration only. Nothing here is a secret: the Supabase URL and the publishable
 * key are meant to be visible in the browser. Row Level Security protects the data.
 * Values must be read as literal `process.env.NEXT_PUBLIC_*` so Next can inline them.
 */
function required(name: string, value: string | undefined): string {
  if (!value) {
    throw new Error(`Missing environment variable ${name}. Copy .env.example to .env.local and fill it in.`);
  }
  return value;
}

export function supabaseConfig(): { url: string; key: string } {
  return {
    url: required("NEXT_PUBLIC_SUPABASE_URL", process.env.NEXT_PUBLIC_SUPABASE_URL),
    key: required(
      "NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY",
      process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
    ),
  };
}
