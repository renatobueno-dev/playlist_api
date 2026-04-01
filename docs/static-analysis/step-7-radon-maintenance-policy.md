# 🧭 Static Analysis — Step 7: `radon` Maintenance Policy

## 📌 Context

After the earlier cleanup steps:

- `pylint` is clean
- `radon mi` remains healthy across the repo
- no `radon cc` blocks remain in ranks `C`, `D`, `E`, or `F`

That changes the `radon` conversation from hotspot cleanup to maintenance discipline.

The remaining complexity signals are now concentrated in a small set of `B`-ranked blocks, with the rest of the repo sitting at `A`.

## 🎯 Scope decision

Do **not** chase lower complexity scores across the whole repository.

Instead, define a durable maintenance rule:

- `A` blocks need no action by default
- `B` blocks are optional cleanup targets
- `C` and above should trigger active refactoring soon

This keeps future cleanup proportional to value instead of turning `radon` into a busywork loop.

## ✅ Validation target

The repository should clearly record:

- what remaining `B`-ranked hotspots exist
- which of them are worth refactoring first
- when `A`-ranked blocks should be left alone
- the practical threshold for future action

## 🏁 Completion criteria

Step 7 is complete when the static-analysis docs explicitly define:

- the ranked maintenance threshold for `radon`
- the highest-value `B`-ranked follow-up targets
- that no immediate action is required for `A`-ranked blocks

## ⚠️ Errors and issues observed

This step did not expose a new repository defect. It was a prioritization step.

Observed repository considerations:

- the remaining `B`-ranked blocks are mostly in contract tests
- the first highest-priority hotspot was the combined playlist-song missing-resource contract test
- the main non-test hotspot is `_resolve_songs` in the playlist service

Coding and implementation issues during the step:

- the main challenge was avoiding overreaction to healthy `B`-ranked blocks
- a maintenance policy was more useful here than another forced refactor pass
- the step needed to distinguish between "worth revisiting later" and "needs action now"
- once that first `B` hotspot was intentionally revisited, the safest refactor was to split by missing-resource case rather than invent new shared test abstractions
- the main coding constraint was preserving the same `404` detail contract while decomposing one matrix-style test into four narrower endpoint-specific checks
- the service-helper follow-up needed to reduce branch density without obscuring the playlist lookup flow behind generic abstractions

## 📝 Step execution notes

- Step completed in the current cycle.
- Current `radon` maintenance policy:
  - `A`: no action unless the file is already being edited
  - `B`: optional cleanup when readability suffers or nearby code is already changing
  - `C+`: refactor soon
- First applied follow-up:
  - the combined playlist-song missing-resource test was split into narrower link/unlink 404 cases
- Result of that follow-up:
  - the former `B / 9` hotspot became four separate `A / 3` tests
- Second applied follow-up:
  - `_resolve_songs` was split into normalization, song lookup, and missing-song validation helpers
- Result of that follow-up:
  - `_resolve_songs` dropped from `B / 7` to `A / 3`
- Remaining practical hotspot focus:
  - the remaining `B` ranks are now concentrated in larger contract tests rather than runtime helpers
- Current conclusion:
  - the repository is in a healthy `radon` state
  - remaining `B` ranks are a maintenance queue, not a blocker
