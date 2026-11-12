import type { Metadata } from "next";
import "@fontsource-variable/plus-jakarta-sans";

import { ScrollbarFade } from "@/components/ScrollbarFade";
import { ToastProvider } from "@/components/ui/Toast";
import { TooltipLayer } from "@/components/ui/TooltipLayer";
import { introInitScript } from "@/lib/intro";
import { themeInitScript } from "@/lib/theme";

import "./tailwind.css";

export const metadata: Metadata = {
  title: { default: "BusIn admin", template: "%s | BusIn admin" },
  description: "Administration portal for BusIn campus bus management.",
  robots: { index: false, follow: false },
};

// The language is chosen per visitor from a cookie, which is request-time data. Each page
// therefore sets `lang` on its own content wrapper instead of reading the cookie here.
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeInitScript + introInitScript }} />
      </head>
      <body>
        <ScrollbarFade />
        <TooltipLayer />
        <ToastProvider>{children}</ToastProvider>
      </body>
    </html>
  );
}
