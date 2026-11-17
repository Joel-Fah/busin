"use server";

import { revalidatePath } from "next/cache";

import { createClient } from "@/lib/supabase/server";

import { reasonProblem } from "./refunds";
import { requireStudent } from "./session";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export type RefundAskState = { sent: boolean; error: "short" | "long" | "notRefundable" | "generic" | null };

/** Asks the school to refund one of the student's payments (ADR 0029). The database checks it is theirs and refundable. */
export async function askRefund(_previous: RefundAskState, form: FormData): Promise<RefundAskState> {
  await requireStudent();
  const payment = String(form.get("payment") ?? "");
  const reason = String(form.get("reason") ?? "");
  if (!UUID.test(payment)) return { sent: false, error: "generic" };
  const problem = reasonProblem(reason);
  if (problem) return { sent: false, error: problem };
  const supabase = await createClient();
  const { error } = await supabase.rpc("request_refund", { p_payment: payment, p_reason: reason });
  if (error) {
    if (error.message === "not_refundable") return { sent: false, error: "notRefundable" };
    if (error.message === "reason_too_short" || error.message === "reason_required") return { sent: false, error: "short" };
    return { sent: false, error: "generic" };
  }
  revalidatePath("/app/subscription");
  return { sent: true, error: null };
}
