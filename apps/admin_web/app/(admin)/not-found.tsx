import Link from "next/link";
import { Suspense } from "react";

import { getMessages } from "@/lib/i18n/server";

export default function AdminNotFound() {
  return (
    <Suspense fallback={<section aria-busy="true" />}>
      <NotFoundContent />
    </Suspense>
  );
}

async function NotFoundContent() {
  const { t } = await getMessages();
  return (
    <section className="stack">
      <h1>{t.notFound.title}</h1>
      <p>{t.notFound.body}</p>
      <p>
        <Link href="/">{t.notFound.back}</Link>
      </p>
    </section>
  );
}
