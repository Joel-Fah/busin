"use server";

import { revalidatePath } from "next/cache";

import { requirePlatformAdmin } from "@/lib/auth";
import type { Json } from "@/lib/database.types";
import { isUuid } from "@/lib/ids";
import {
  parseInfraCost,
  parseSchoolTerms,
  parseSettings,
  parseSettingsForm,
  parseWalletMovement,
  platformPaymentErrorKey,
  settingsChanges,
  type PlatformPaymentState,
} from "@/lib/platform-payments";
import { createClient } from "@/lib/supabase/server";

// Every console payments action checks the platform admin here, reads its form again on the server, and lets the
// database function check the caller once more (42501), validate, and write the platform audit (ADR 0027 and 0029).

function refresh(): void {
  revalidatePath("/platform", "layout");
}

const refused = (error: { code?: string; message?: string }): PlatformPaymentState => ({ ok: false, error: platformPaymentErrorKey(error.code, error.message) });

/**
 * Saves the payment settings and the operators' rates. The current values are read again here and only what differs is
 * sent, so the platform audit names each change; an operator's rate is its own call (`platform_set_provider_rate`).
 */
export async function savePaymentSettings(_previous: PlatformPaymentState, formData: FormData): Promise<PlatformPaymentState> {
  await requirePlatformAdmin();
  const parsed = parseSettingsForm(formData);
  if (!parsed.ok) return { ok: false, error: `field:${parsed.field}` };

  const supabase = await createClient();
  const { data, error } = await supabase.rpc("platform_payment_settings");
  if (error) return refused(error);
  const changes = settingsChanges(parseSettings(data), parsed.value);
  if (Object.keys(changes.settings).length === 0 && changes.rates.length === 0) return { ok: true, done: "unchanged" };

  if (Object.keys(changes.settings).length > 0) {
    const { error: saveError } = await supabase.rpc("platform_set_payment_settings", { p_settings: changes.settings as Json });
    if (saveError) return refused(saveError);
  }
  for (const rate of changes.rates) {
    const { error: rateError } = await supabase.rpc("platform_set_provider_rate", {
      p_provider: rate.provider,
      p_operation: rate.operation,
      // Null (not set) stops payments with that operator for that kind of transaction.
      p_percent: rate.percent as number,
      p_fixed_xaf: rate.fixed,
    });
    if (rateError) return refused(rateError);
  }
  refresh();
  return { ok: true, done: "saved" };
}

/** Adds a month's infrastructure cost (a label, an amount, a note), so the margin is the real one. */
export async function addInfraCost(_previous: PlatformPaymentState, formData: FormData): Promise<PlatformPaymentState> {
  await requirePlatformAdmin();
  const parsed = parseInfraCost(formData);
  if (!parsed.ok) return { ok: false, error: parsed.error };
  const { month, label, amount, note } = parsed.value;

  const supabase = await createClient();
  const { error } = await supabase.rpc("platform_add_infra_cost", { p_month: month, p_label: label, p_amount_xaf: amount, ...(note ? { p_note: note } : {}) });
  if (error) return refused(error);
  refresh();
  return { ok: true, done: "added" };
}

/** Deletes an infrastructure cost, after the confirmation on the page. */
export async function deleteInfraCost(_previous: PlatformPaymentState, formData: FormData): Promise<PlatformPaymentState> {
  await requirePlatformAdmin();
  const id = formData.get("cost");
  if (!isUuid(id)) return { ok: false, error: "not_found" };

  const supabase = await createClient();
  const { error } = await supabase.rpc("platform_delete_infra_cost", { p_id: id });
  if (error) return refused(error);
  refresh();
  return { ok: true, done: "removed" };
}

/** Records BusIn taking money out of its pawaPay wallet (to its bank) or putting money in; the books count it. */
export async function addWalletMovement(_previous: PlatformPaymentState, formData: FormData): Promise<PlatformPaymentState> {
  await requirePlatformAdmin();
  const parsed = parseWalletMovement(formData);
  if (!parsed.ok) return { ok: false, error: parsed.error };
  const { kind, amount, note } = parsed.value;

  const supabase = await createClient();
  const { error } = await supabase.rpc("platform_add_wallet_movement", { p_kind: kind, p_amount_xaf: amount, ...(note ? { p_note: note } : {}) });
  if (error) return refused(error);
  refresh();
  return { ok: true, done: "recorded" };
}

/** Removes a wallet movement entered by mistake; the books stop counting it. */
export async function deleteWalletMovement(_previous: PlatformPaymentState, formData: FormData): Promise<PlatformPaymentState> {
  await requirePlatformAdmin();
  const id = formData.get("movement");
  if (!isUuid(id)) return { ok: false, error: "not_found" };

  const supabase = await createClient();
  const { error } = await supabase.rpc("platform_delete_wallet_movement", { p_id: id });
  if (error) return refused(error);
  refresh();
  return { ok: true, done: "removed" };
}

/**
 * Confirms a payout number waiting for a second administrator, for a school that has only one: the platform admin checks
 * the number with them first. The database refuses a number no longer waiting (`not_proposed`).
 */
export async function confirmPayoutAccount(_previous: PlatformPaymentState, formData: FormData): Promise<PlatformPaymentState> {
  await requirePlatformAdmin();
  const account = formData.get("account");
  if (!isUuid(account)) return { ok: false, error: "not_found" };

  const supabase = await createClient();
  const { error } = await supabase.rpc("platform_confirm_payout_account", { p_account: account });
  if (error) return refused(error);
  refresh();
  return { ok: true, done: "confirmed" };
}

/**
 * A school's payment terms: mobile money on or off, the day BusIn's charges start (none: no charges yet), and the
 * school's own charges (none: the platform's).
 */
export async function saveSchoolPaymentTerms(_previous: PlatformPaymentState, formData: FormData): Promise<PlatformPaymentState> {
  await requirePlatformAdmin();
  const parsed = parseSchoolTerms(formData);
  if (!parsed.ok) return { ok: false, error: parsed.error };
  const { school, enabled, chargesFrom, chargeSemester, chargeMonth } = parsed.value;

  const supabase = await createClient();
  // A value left out is null in the database: no date, or the platform's charge.
  const { error } = await supabase.rpc("platform_set_school_payment_terms", {
    p_school: school,
    p_enabled: enabled,
    ...(chargesFrom ? { p_charges_from: chargesFrom } : {}),
    ...(chargeSemester !== null ? { p_charge_semester_xaf: chargeSemester } : {}),
    ...(chargeMonth !== null ? { p_charge_month_xaf: chargeMonth } : {}),
  });
  if (error) return refused(error);
  refresh();
  return { ok: true, done: "saved" };
}
