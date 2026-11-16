import { strict as assert } from "node:assert";
import { test } from "node:test";

import { chunk, eraseDue, type EraseSteps } from "./erase.ts";

function recorder(fail: Partial<Record<"files" | "signIn" | "profile", string>> = {}) {
  const calls: string[] = [];
  const steps: EraseSteps = {
    async removeFiles(paths) {
      calls.push(`files:${paths.length}`);
      if (fail.files) throw new Error(fail.files);
    },
    async deleteSignIn(id) {
      calls.push(`signIn:${id}`);
      if (fail.signIn) throw new Error(fail.signIn);
    },
    async eraseProfile(id) {
      calls.push(`profile:${id}`);
      if (fail.profile) throw new Error(fail.profile);
    },
  };
  return { calls, steps };
}

test("files go first, in chunks, then the sign-in account, then the profile", async () => {
  const { calls, steps } = recorder();
  const files = Array.from({ length: 150 }, (_, i) => `s/u1/${i}.jpg`);
  const outcome = await eraseDue([{ user_id: "u1", files }, { user_id: "u2", files: null }], steps);
  assert.deepEqual(calls, ["files:100", "files:50", "signIn:u1", "profile:u1", "signIn:u2", "profile:u2"]);
  assert.deepEqual(outcome, { erased: 2, failed: [] });
});

test("a file failure stops that account before anything else, and the next one goes on", async () => {
  const { calls, steps } = recorder({ files: "storage down" });
  const outcome = await eraseDue([{ user_id: "u1", files: ["a"] }], steps);
  assert.deepEqual(calls, ["files:1"]);
  assert.deepEqual(outcome.failed, [{ step: "files", error: "storage down" }]);
});

test("a sign-in account already gone counts as done", async () => {
  const { calls, steps } = recorder({ signIn: "User not found" });
  const outcome = await eraseDue([{ user_id: "u1", files: [] }], steps);
  assert.deepEqual(calls, ["signIn:u1", "profile:u1"]);
  assert.equal(outcome.erased, 1);
});

test("another sign-in failure stops before the profile", async () => {
  const { calls, steps } = recorder({ signIn: "auth unavailable" });
  const outcome = await eraseDue([{ user_id: "u1", files: [] }], steps);
  assert.deepEqual(calls, ["signIn:u1"]);
  assert.deepEqual(outcome.failed, [{ step: "sign_in", error: "auth unavailable" }]);
});

test("chunk splits evenly", () => {
  assert.deepEqual(chunk([1, 2, 3], 2), [[1, 2], [3]]);
  assert.deepEqual(chunk([], 2), []);
});
