import { NextResponse, type NextRequest } from "next/server";

import { updateSession } from "@/lib/supabase/proxy";

// The landing page is public; signed-out visitors reach it at "/" through the rewrite below.
const PUBLIC_PATHS = [
  "/login",
  "/auth/callback",
  "/dev/login",
  "/landing",
  "/credits",
  "/robots.txt",
  "/sitemap.xml",
  "/llms.txt",
  "/.well-known/ard.json",
  // The student web app (ADR 0021): its sign-in, its offline page and what the browser fetches to install it.
  "/app/sign-in",
  "/app/offline",
  "/app/manifest.webmanifest",
  "/app/sw.js",
  "/app-icons",
];

function isPublic(pathname: string): boolean {
  // The student web app's share card is fetched by link previews, which are never signed in.
  if (/^\/app\/(opengraph|twitter)-image/.test(pathname)) return true;
  return PUBLIC_PATHS.some((path) => pathname === path || pathname.startsWith(`${path}/`));
}

export async function proxy(request: NextRequest) {
  const { response, signedIn, role } = await updateSession(request);
  const path = request.nextUrl.pathname;

  // Routing only, from the token: the pages check the live profile again. A student who reaches the portal's front
  // door goes to the student web app (ADR 0021), and the app's own address opens on its first tab.
  const goTo = (pathname: string) => {
    const url = request.nextUrl.clone();
    url.pathname = pathname;
    url.search = "";
    const redirect = NextResponse.redirect(url);
    for (const cookie of response.cookies.getAll()) redirect.cookies.set(cookie);
    return redirect;
  };
  if (signedIn && role === "student" && (path === "/" || path === "/login" || path === "/no-access")) return goTo("/app/subscription");
  if (signedIn && path === "/app") return goTo("/app/subscription");

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
    // Students sign in on their own page; everything else is the portal's.
    const student = request.nextUrl.pathname === "/app" || request.nextUrl.pathname.startsWith("/app/");
    url.pathname = student ? "/app/sign-in" : "/login";
    url.search = "";
    return NextResponse.redirect(url);
  }

  return response;
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|brand/|.*\\.(?:svg|png|jpg|jpeg|gif|webp|ico)$).*)"],
};
