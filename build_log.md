# Build log

One row per merged or opened PR. Record what did not work and how it was resolved, so the history explains itself.

| Date | PR | Issue | Summary | What did not work / how resolved |
|---|---|---|---|---|
| 2026-10-30 | pending | pending | Phase 0: monorepo restructure, root docs, skills, templates | `git mv windows` failed with permission denied (a VS Code extension held the folder); moved the files one by one instead. `gh` is not installed, so issue and PR creation waits for the owner. |
