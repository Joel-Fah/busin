# Build log

One row per merged or opened PR. Record what did not work and how it was resolved, so the history explains itself.

| Date | PR | Issue | Summary | What did not work / how resolved |
|---|---|---|---|---|
| 2026-10-30 | [#47](https://github.com/Joel-Fah/busin/pull/47) | [#32](https://github.com/Joel-Fah/busin/issues/32) | Phase 0: monorepo restructure, root docs, skills, templates | `git mv windows` failed with permission denied (a VS Code extension held the folder); moved the files one by one instead. The first foundation commit also held a broken STATUS handoff note (backticks ran as shell commands); fixed and squashed before pushing. |
| 2026-10-30 | [#49](https://github.com/Joel-Fah/busin/pull/49) | [#48](https://github.com/Joel-Fah/busin/issues/48) | Add priority labels (high, medium, low) to workflow, templates and open issues | Nothing failed. |
| 2026-10-30 | pending | [#58](https://github.com/Joel-Fah/busin/issues/58) | ADR 0007: Riverpod, go_router, shared_preferences, flutter_secure_storage, drift; skill and architecture updated | Blog claims about GetX being removed conflicted, so the ADR relies on pub.dev facts only and marks that claim unverified. |
