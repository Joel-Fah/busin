import { School01Icon } from "@hugeicons/core-free-icons";
import type { Metadata } from "next";
import { Suspense } from "react";

import { GatePage } from "@/components/student/GatePage";
import { RefreshOnReturn } from "@/components/student/RefreshOnReturn";
import { SignOutForm } from "@/components/student/SignOutForm";
import { WaitingActions } from "@/components/student/WaitingActions";
import { Icon } from "@/components/ui/Icon";
import { supabaseConfig } from "@/lib/env";
import { format } from "@/lib/i18n/format";
import { getStudentCopy } from "@/lib/i18n/server";
import { logoUrl } from "@/lib/school";
import { requireGate } from "@/lib/student/session";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Waiting" };
export const instant = false;

export default function WaitingPage() {
  return (
    <Suspense fallback={<main className="min-h-dvh bg-bg" aria-busy="true" />}>
      <Waiting />
    </Suspense>
  );
}

/**
 * A student who asked to join a school, while it checks (ADR 0012). A pending account gets no push, so the page asks the
 * server again whenever the student comes back to it.
 */
async function Waiting() {
  const { profile } = await requireGate("awaitingSchool");
  const { locale, s } = await getStudentCopy();
  const supabase = await createClient();
  const { data } = await supabase.rpc("my_join_request");
  const request = data?.[0];
  const school = request?.school_name || profile.schools?.name || "";
  const logo = logoUrl(request?.school_logo_path, supabaseConfig().url);
  const date = request?.requested_at ? new Intl.DateTimeFormat(locale, { dateStyle: "long" }).format(new Date(request.requested_at)) : "";

  return (
    <GatePage lang={locale} title={format(s.waiting.title, { school })}>
      <RefreshOnReturn />
      <div className="grid size-20 place-items-center overflow-hidden rounded-md bg-white shadow-soft">
        {logo ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={logo} alt="" className="size-full object-contain" />
        ) : (
          <Icon icon={School01Icon} size={32} className="text-brand" />
        )}
      </div>
      <p className="m-0 text-muted">{date ? format(s.waiting.body, { date }) : s.waiting.still}</p>
      <WaitingActions copy={s.waiting} errors={s.join} />
      <div className="mt-auto pt-6">
        <SignOutForm label={s.profile.signOut} />
      </div>
    </GatePage>
  );
}
