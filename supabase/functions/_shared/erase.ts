// Erasing the accounts whose deletion is due (ADR 0028). Pure orchestration: the Edge Function and the local tool give
// it the three steps (Storage, Auth, the database); the order and the failure rules live here, with the tests.
//
// Order, for each account: 1. delete its payment proof files (Storage API: SQL cannot remove the stored files);
// 2. soft-delete its sign-in account (Supabase keeps a hashed id; the same Google account can start afresh);
// 3. erase its profile and personal rows (database). A failure stops that account at that step; the next run starts it
// again from the top, and each step is safe to repeat (an account already soft-deleted counts as done).

export type DueAccount = { user_id: string; files: string[] | null };

export type EraseSteps = {
  removeFiles(paths: string[]): Promise<void>;
  deleteSignIn(userId: string): Promise<void>;
  eraseProfile(userId: string): Promise<void>;
};

export type EraseOutcome = { erased: number; failed: { step: "files" | "sign_in" | "profile"; error: string }[] };

/** Storage removes at most this many paths per call. */
export const FILES_PER_CALL = 100;

export function chunk<T>(items: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < items.length; i += size) out.push(items.slice(i, i + size));
  return out;
}

/** "User not found" from Auth means a previous run already did it: the step is done. */
export function alreadyGone(message: string): boolean {
  return /not.?found|user_not_found/i.test(message);
}

export async function eraseDue(due: DueAccount[], steps: EraseSteps): Promise<EraseOutcome> {
  const outcome: EraseOutcome = { erased: 0, failed: [] };
  for (const account of due) {
    let step: EraseOutcome["failed"][number]["step"] = "files";
    try {
      for (const paths of chunk(account.files ?? [], FILES_PER_CALL)) await steps.removeFiles(paths);
      step = "sign_in";
      try {
        await steps.deleteSignIn(account.user_id);
      } catch (error) {
        if (!alreadyGone(String((error as Error)?.message ?? error))) throw error;
      }
      step = "profile";
      await steps.eraseProfile(account.user_id);
      outcome.erased += 1;
    } catch (error) {
      // No ids or emails in the outcome: it may end up in logs.
      outcome.failed.push({ step, error: String((error as Error)?.message ?? error).slice(0, 200) });
    }
  }
  return outcome;
}
