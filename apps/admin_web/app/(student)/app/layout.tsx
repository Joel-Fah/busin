import type { Metadata, Viewport } from "next";

import { ServiceWorker } from "@/components/student/ServiceWorker";
import { RoughFilter } from "@/components/ui/RoughFilter";

/**
 * The student web app (ADR 0021): a PWA at /app with its own manifest and service worker, scoped to /app/. Nothing here
 * comes from the portal's pages or navigation, so a student downloads none of it.
 */
export const metadata: Metadata = {
  title: { default: "BusIn", template: "%s | BusIn" },
  description: "Subscribe to the school bus, show your boarding code and follow your bus.",
  applicationName: "BusIn",
  manifest: "/app/manifest.webmanifest",
  appleWebApp: { capable: true, title: "BusIn", statusBarStyle: "default" },
  icons: {
    icon: [
      { url: "/app-icons/icon-192.png", sizes: "192x192", type: "image/png" },
      { url: "/app-icons/icon-512.png", sizes: "512x512", type: "image/png" },
    ],
    apple: [{ url: "/app-icons/apple-touch-180.png", sizes: "180x180" }],
  },
  formatDetection: { telephone: false },
  robots: { index: false, follow: false },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#f4f8f8" },
    { media: "(prefers-color-scheme: dark)", color: "#00181d" },
  ],
};

export default function StudentAppLayout({ children }: { children: React.ReactNode }) {
  return (
    <>
      <ServiceWorker />
      <RoughFilter />
      {children}
    </>
  );
}
