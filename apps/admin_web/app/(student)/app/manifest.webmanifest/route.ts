/**
 * The web app manifest of the student web app (ADR 0021). Scoped to /app/ so the portal is never part of the installed
 * app. The icon is the teal mark on white, to tell it apart from the installed mobile app.
 */
export function GET() {
  const manifest = {
    id: "/app",
    name: "BusIn",
    short_name: "BusIn",
    description: "Subscribe to the school bus, show your boarding code and follow your bus.",
    start_url: "/app",
    scope: "/app/",
    display: "standalone",
    orientation: "portrait",
    background_color: "#ffffff",
    theme_color: "#f4f8f8",
    categories: ["education", "travel"],
    icons: [
      { src: "/app-icons/icon-192.png", sizes: "192x192", type: "image/png", purpose: "any" },
      { src: "/app-icons/icon-512.png", sizes: "512x512", type: "image/png", purpose: "any" },
      { src: "/app-icons/maskable-512.png", sizes: "512x512", type: "image/png", purpose: "maskable" },
    ],
  };
  return new Response(JSON.stringify(manifest), {
    headers: { "Content-Type": "application/manifest+json", "Cache-Control": "public, max-age=3600" },
  });
}
