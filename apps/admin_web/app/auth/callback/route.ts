import { NextResponse, type NextRequest } from "next/server";

import { createClient } from "@/lib/supabase/server";

function toLogin(request: NextRequest, error: string) {
  return NextResponse.redirect(new URL(`/login?error=${error}`, request.url));
}

/**
 * Google sends the browser back here with a one-time code, which is exchanged for a session.
 * Sign-up is refused by the database when the email domain is not allowed; that failure
 * arrives here as a provider error and is shown on the login page.
 */
export async function GET(request: NextRequest) {
  const { searchParams } = request.nextUrl;

  const providerError = searchParams.get("error_description") ?? searchParams.get("error");
  if (providerError) {
    const refused = providerError.includes("Database error saving new user");
    return toLogin(request, refused ? "domain_not_allowed" : "auth_failed");
  }

  const code = searchParams.get("code");
  if (!code) return toLogin(request, "auth_failed");

  const supabase = await createClient();
  const { error } = await supabase.auth.exchangeCodeForSession(code);
  if (error) return toLogin(request, "auth_failed");

  return NextResponse.redirect(new URL("/", request.url));
}
