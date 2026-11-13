import type { Metadata, Viewport } from "next";

import { Suspense } from "react";

import { FirstOpen } from "@/components/student/FirstOpen";
import { ServiceWorker } from "@/components/student/ServiceWorker";
import { getStudentCopy } from "@/lib/i18n/server";
import { downloads } from "@/lib/landing/downloads";
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
    // iOS reads these, not the manifest: one per size it asks for (iPhone 180, iPad Pro 167, iPad 152). A copy also sits at
    // /apple-touch-icon.png and /apple-touch-icon-precomposed.png, which some iOS versions fetch first; without an icon in
    // time, iOS draws the first letter of the name instead.
    apple: [
      { url: "/app-icons/apple-touch-180.png", sizes: "180x180", type: "image/png" },
      { url: "/app-icons/apple-touch-167.png", sizes: "167x167", type: "image/png" },
      { url: "/app-icons/apple-touch-152.png", sizes: "152x152", type: "image/png" },
    ],
  },
  formatDetection: { telephone: false },
  // The share card of the student web app (opengraph-image.tsx beside this file), with its own words.
  openGraph: {
    type: "website",
    siteName: "BusIn",
    title: "BusIn, right in your browser",
    description: "Subscribe to the school bus, show your boarding code and follow your bus, from any phone or computer. No download.",
    url: "/app",
  },
  twitter: {
    card: "summary_large_image",
    title: "BusIn, right in your browser",
    description: "Subscribe to the school bus, show your boarding code and follow your bus, from any phone or computer. No download.",
  },
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
      <Suspense fallback={null}>
        <Welcome />
      </Suspense>
    </>
  );
}

/** The first-open welcome and the "better in the app" sheet, in the visitor's language, with the app links of the landing. */
async function Welcome() {
  const { s } = await getStudentCopy();
  const links = downloads();
  return <FirstOpen welcome={s.welcome} appSheet={s.appSheet} links={{ android: links.play ?? links.apk, ios: links.ios }} />;
}
