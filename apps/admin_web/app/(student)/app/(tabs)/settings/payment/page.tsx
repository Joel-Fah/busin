import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { Suspense } from "react";

import { PaymentPreference } from "@/components/student/PaymentPreference";
import { StudentPage } from "@/components/student/StudentPage";
import { schoolBilling } from "@/lib/billing";
import { getStudentCopy } from "@/lib/i18n/server";
import { requireStudent } from "@/lib/student/session";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "How you pay" };
export const instant = false;

export default function PaymentPage() {
  return (
    <Suspense fallback={<main className="min-h-dvh" aria-busy="true" />}>
      <Payment />
    </Suspense>
  );
}

/** How the student prefers to pay (ADR 0022). Only where the school offers installments: otherwise there is nothing to choose. */
async function Payment() {
  const student = await requireStudent();
  const { locale, s } = await getStudentCopy();
  const supabase = await createClient();
  const [school, me] = await Promise.all([
    supabase.from("schools").select("billing_period, price_xaf, installment_plan, currency").eq("id", student.schoolId).maybeSingle(),
    supabase.from("profiles").select("payment_preference").eq("id", student.userId).maybeSingle(),
  ]);
  const billing = schoolBilling(school.data);
  if (!billing || billing.period !== "semester" || !billing.plan) redirect("/app/profile");
  const current = me.data?.payment_preference === "full" || me.data?.payment_preference === "installments" ? me.data.payment_preference : null;
  return (
    <StudentPage lang={locale} title={s.me.payment.title} subtitle={s.me.payment.intro}>
      <PaymentPreference
        copy={s.me.payment}
        labels={{ full: s.subscription.paymentFull, installments: s.subscription.paymentInstallments, failed: s.subscription.errors.failed }}
        current={current}
      />
    </StudentPage>
  );
}
