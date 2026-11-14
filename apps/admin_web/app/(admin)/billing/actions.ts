"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { requireAdmin } from "@/lib/auth";
import { billingSaveError, parseBillingForm } from "@/lib/billing";
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
