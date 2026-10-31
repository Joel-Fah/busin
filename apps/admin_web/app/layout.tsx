import type { Metadata } from "next";
import localFont from "next/font/local";

import "./globals.css";

const bevellier = localFont({
  src: "./fonts/Bevellier-Variable.ttf",
  variable: "--font-bevellier",
  weight: "100 900",
  display: "swap",
});

export const metadata: Metadata = {
  title: { default: "BusIn admin", template: "%s | BusIn admin" },
  description: "Administration portal for BusIn campus bus management.",
  robots: { index: false, follow: false },
};

// The language is chosen per visitor from a cookie, which is request-time data. Each page
// therefore sets `lang` on its own content wrapper instead of reading the cookie here.
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={bevellier.variable}>
      <body>{children}</body>
    </html>
  );
}
