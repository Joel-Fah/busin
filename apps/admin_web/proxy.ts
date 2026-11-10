import { NextResponse, type NextRequest } from "next/server";

import { updateSession } from "@/lib/supabase/proxy";

// The landing page is public; signed-out visitors reach it at "/" through the rewrite below.
const PUBLIC_PATHS = ["/login", "/auth/callback", "/dev/login", "/landing", "/robots.txt", "/sitemap.xml"];

function isPublic(pathname: string): boolean {
  return PUBLIC_PATHS.some((path) => pathname === path || pathname.startsWith(`${path}/`));
}

export async function proxy(request: NextRequest) {
  const { response, signedIn } = await updateSession(request);

  // A visitor who is not signed in sees the landing page at the root address; a signed-in admin gets the overview there.
  if (!signedIn && request.nextUrl.pathname === "/") {
    const url = request.nextUrl.clone();
    url.pathname = "/landing";
    const landing = NextResponse.rewrite(url);
    // Keep any session cookie the refresh just set.
    for (const cookie of response.cookies.getAll()) landing.cookies.set(cookie);
    return landing;
  }

  if (!signedIn && !isPublic(request.nextUrl.pathname)) {
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    url.search = "";
    return NextResponse.redirect(url);
  }

  return response;
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|brand/|.*\\.(?:svg|png|jpg|jpeg|gif|webp|ico)$).*)"],
};
