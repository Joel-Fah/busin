# Build log

One row per merged or opened PR. Record what did not work and how it was resolved, so the history explains itself.

| Date | PR | Issue | Summary | What did not work / how resolved |
|---|---|---|---|---|
| 2026-10-30 | [#47](https://github.com/Joel-Fah/busin/pull/47) | [#32](https://github.com/Joel-Fah/busin/issues/32) | Phase 0: monorepo restructure, root docs, skills, templates | `git mv windows` failed with permission denied (a VS Code extension held the folder); moved the files one by one instead. The first foundation commit also held a broken STATUS handoff note (backticks ran as shell commands); fixed and squashed before pushing. |
| 2026-10-30 | [#49](https://github.com/Joel-Fah/busin/pull/49) | [#48](https://github.com/Joel-Fah/busin/issues/48) | Add priority labels (high, medium, low) to workflow, templates and open issues | Nothing failed. |
| 2026-10-30 | [#61](https://github.com/Joel-Fah/busin/pull/61) | [#60](https://github.com/Joel-Fah/busin/issues/60) | Phase 2a: busin_core with enums, models mirroring the tables, GeoPoint, ScanOutcome and QrCodeGenerator; 28 unit tests | Shell heredocs failed on quotes, so files were written with the file tool. Skipped equatable (v3 just released) and used a small ValueObject base. The Dart QR vector matches the database test and Node. The QR guide is in the unmerged Phase 1 PRs, so its note about the Dart generator is added after they merge. |
