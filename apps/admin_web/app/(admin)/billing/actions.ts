"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { requireAdmin } from "@/lib/auth";
import { MAX_PRICE, billingSaveError, breakdownLines, parseBillingForm } from "@/lib/billing";
import { isFeesPaidBy } from "@/lib/payments";
import { createClient } from "@/lib/supabase/server";

/** Saves the school's billing through the database function, which checks the administrator and every value again. */
export async function saveBilling(formData: FormData): Promise<void> {
  await requireAdmin();
  const parsed = parseBillingForm(formData);
  if (!parsed.ok) redirect(`/billing?error=${parsed.field}`);
  const { period, price, plan } = parsed.value;

  const supabase = await createClient();
  // The generated types do not mark function arguments as nullable; the function takes null to mean "in full only".
  const { error } = await supabase.rpc("admin_set_billing", { p_period: period, p_price: price, p_plan: plan as unknown as string });
  if (error) redirect(`/billing?error=${billingSaveError(error.message)}`);

  revalidatePath("/billing");
  revalidatePath("/");
  redirect("/billing?done=saved");
}

/** Who pays BusIn's charge and the transfer costs (ADR 0029), saved at once through `admin_set_fees_paid_by` (audited). */
export async function saveFeesPaidBy(who: string): Promise<{ ok: boolean }> {
  await requireAdmin();
  if (!isFeesPaidBy(who)) return { ok: false };
  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_set_fees_paid_by", { p_who: who });
  if (error) return { ok: false };
  revalidatePath("/billing");
  revalidatePath("/payments");
  return { ok: true };
}

export type BreakdownLine = { method: string; studentPays: number; businCharge: number; transactionCost: number; schoolReceives: number };

/**
 * What a price would mean per way of paying, before it is saved: the database works it out (`price_breakdown` with the
 * typed price), so the portal never repeats the fee rules. Null when the price is not one the database takes.
 */
export async function previewBreakdown(price: number): Promise<BreakdownLine[] | null> {
  await requireAdmin();
  if (!Number.isInteger(price) || price < 1 || price > MAX_PRICE) return null;
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("price_breakdown", { p_price: price });
  if (error || !data) return null;
  return breakdownLines(data);
}
