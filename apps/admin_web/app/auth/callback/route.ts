import { NextResponse, type NextRequest } from "next/server";

import { SIGN_IN_FROM_COOKIE } from "@/lib/sign-in-from";
import { createClient } from "@/lib/supabase/server";

/**
 * Google sends the browser back here with a one-time code, which is exchanged for a session.
 * Sign-up is refused by the database when the email domain is not allowed; that failure
 * arrives here as a provider error and is shown on the sign-in page it started from.
 * A student goes on to the student web app (ADR 0021), everyone else to the portal, which turns away who it must.
 */
export async function GET(request: NextRequest) {
  const { searchParams } = request.nextUrl;
  const fromApp = request.cookies.get(SIGN_IN_FROM_COOKIE)?.value === "app";

  const fail = (portalKey: string, appKey: string) => {
    const response = NextResponse.redirect(new URL(fromApp ? `/app/sign-in?error=${appKey}` : `/login?error=${portalKey}`, request.url));
    response.cookies.delete(SIGN_IN_FROM_COOKIE);
    return response;
  };

  const providerError = searchParams.get("error_description") ?? searchParams.get("error");
  if (providerError) {
    const refused = providerError.includes("Database error saving new user");
    return refused ? fail("domain_not_allowed", "notAllowed") : fail("auth_failed", "failed");
  }

  const code = searchParams.get("code");
  if (!code) return fail("auth_failed", "failed");

  const supabase = await createClient();
  const { data, error } = await supabase.auth.exchangeCodeForSession(code);
  if (error || !data.user) return fail("auth_failed", "failed");

  const { data: profile } = await supabase.from("profiles").select("role").eq("id", data.user.id).maybeSingle();
  const response = NextResponse.redirect(new URL(profile?.role === "student" ? "/app" : "/", request.url));
  response.cookies.delete(SIGN_IN_FROM_COOKIE);
  return response;
}
