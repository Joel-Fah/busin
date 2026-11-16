import type { Metadata } from "next";

import { PublicLegalPage, legalMetadata } from "@/components/landing/PublicLegalPage";

// Depends on the visitor's language (a cookie), so it is rendered per request.
export const instant = false;

export function generateMetadata(): Promise<Metadata> {
  return legalMetadata("acceptable-use");
}

export default function Page() {
  return <PublicLegalPage doc="acceptable-use" />;
}
