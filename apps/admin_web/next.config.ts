import type { NextConfig } from "next";

// Baseline security headers. Location is allowed for this site only, and only when an administrator asks the Stops page to show where they are; it never leaves the browser. A nonce-based Content-Security-Policy is a separate follow-up.
const securityHeaders = [
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "X-Frame-Options", value: "DENY" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=(self)" },
];

const nextConfig: NextConfig = {
  // The Docker image (apps/admin_web/Dockerfile) builds a self-contained server. Left off otherwise so `next start` stays plain.
  output: process.env.NEXT_OUTPUT === "standalone" ? "standalone" : undefined,
  cacheComponents: true,
  partialPrefetching: true,
  poweredByHeader: false,
  // The stylesheets are put into the page itself, so the first paint does not wait for three extra requests.
  experimental: { inlineCss: true },
  // The development indicator sits bottom-left by default, over the sidebar sign-out button.
  devIndicators: { position: "bottom-right" },
  async headers() {
    return [{ source: "/:path*", headers: securityHeaders }];
  },
};

export default nextConfig;
