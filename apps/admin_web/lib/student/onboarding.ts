"use server";

import { redirect } from "next/navigation";

import { createClient } from "@/lib/supabase/server";

import { checkFullName, checkMatricule, checkPhone, normalizePhone, type FieldProblem } from "./profile";
import { currentAccess, requireGate } from "./session";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export type JoinState = { error: "tooSoon" | "failed" | null };

/**
 * Asks a school to let a student in (ADR 0012), from the join page or to change school while waiting. The server checks
 * everything (open school, accepted email, a request at most every 30 seconds); this only maps its answer.
 */
export async function askToJoin(_previous: JoinState, formData: FormData): Promise<JoinState> {
  const { access } = await currentAccess();
  // Only a pending student, with or without a request, may ask to join.
  if (access.kind !== "needsSchool" && access.kind !== "awaitingSchool") redirect("/app/subscription");
  const schoolId = formData.get("school");
  if (typeof schoolId !== "string" || !UUID.test(schoolId)) return { error: "failed" };
  const supabase = await createClient();
  const { error } = await supabase.rpc("request_school", { p_school_id: schoolId });
  if (error) return { error: error.code === "54000" ? "tooSoon" : "failed" };
  redirect("/app/waiting");
}

/** Withdraws the request, to choose another school. */
export async function withdrawRequest(): Promise<JoinState> {
  await requireGate("awaitingSchool");
  const supabase = await createClient();
  // The generated types do not allow null, but the function takes it to mean "withdraw".
  const { error } = await supabase.rpc("request_school", { p_school_id: null as unknown as string });
  if (error) return { error: error.code === "54000" ? "tooSoon" : "failed" };
  redirect("/app/join");
}

/**
 * Asks again where the person belongs: the first tab's guard sends anyone not ready yet (still waiting, declined) to their
 * gate. Not "/app": the proxy's redirect of that address inside an action would leave the old address in the bar.
 */
export async function checkAgain(): Promise<void> {
  redirect("/app/subscription");
}

export type SetupState = {
  problems: Partial<Record<"fullName" | "matricule" | "phone", FieldProblem>>;
  error: "failed" | null;
  values: { fullName: string; matricule: string; phone: string; faculty: string; department: string; program: string };
};

/**
 * Saves the details a verified student must give before using the app: name, student number and phone, and optionally
 * department and program. The student may only change these columns (the update grant); RLS limits it to their own row.
 */
export async function saveSetup(_previous: SetupState, formData: FormData): Promise<SetupState> {
  const { profile } = await requireGate("needsSetup");
  const text = (name: string) => {
    const value = formData.get(name);
    return typeof value === "string" ? value : "";
  };
  const values = {
    fullName: text("fullName"),
    matricule: text("matricule"),
    phone: text("phone"),
    faculty: text("faculty"),
    department: text("department"),
    program: text("program"),
  };
  const problems: SetupState["problems"] = {};
  const name = checkFullName(values.fullName);
  const matricule = checkMatricule(values.matricule);
  const phone = checkPhone(values.phone);
  if (name) problems.fullName = name;
  if (matricule) problems.matricule = matricule;
  if (phone) problems.phone = phone;
  if (Object.keys(problems).length > 0) return { problems, error: null, values };

  const supabase = await createClient();
  const { error } = await supabase
    .from("profiles")
    .update({
      full_name: values.fullName.trim(),
      matricule: values.matricule.trim(),
      phone: normalizePhone(values.phone),
      department_id: UUID.test(values.department) ? values.department : null,
      program_id: UUID.test(values.program) ? values.program : null,
    })
    .eq("id", profile.id);
  if (error) return { problems: {}, error: "failed", values };
  redirect("/app/subscription");
}
