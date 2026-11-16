import { Suspense } from "react";
import { Compass01Icon } from "@hugeicons/core-free-icons";

import { ButtonLink } from "@/components/ui/Button";
import { getMessages } from "@/lib/i18n/server";

/** The same "not found" as the school portal: the console never says it exists to someone who may not open it. */
export default function PlatformNotFound() {
  return (
    <Suspense fallback={<section aria-busy="true" />}>
      <NotFoundContent />
    </Suspense>
  );
}

async function NotFoundContent() {
  const { t } = await getMessages();
  return (
    <section className="flex flex-col items-start gap-4 py-8">
      <h1 className="text-4xl font-extrabold tracking-tight sm:text-5xl">{t.notFound.title}</h1>
      <p className="max-w-xl text-base text-muted">{t.notFound.body}</p>
      <ButtonLink href="/" icon={Compass01Icon}>
        {t.notFound.back}
      </ButtonLink>
    </section>
  );
}
