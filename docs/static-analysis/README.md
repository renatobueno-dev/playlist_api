# 🔎 Static Analysis Step Records

This directory stores the step-by-step execution notes for static-analysis work in this repository.

Use [../STATIC_ANALYSIS.md](../STATIC_ANALYSIS.md) as the overview guide for:

- why static analysis matters here
- how to run `pylint` and `radon`
- how to interpret the results in this stack

Use this folder for the detailed cleanup path itself.

Each step file follows the same durable structure:

- context
- scope decision
- validation target
- completion criteria
- errors and issues observed (both repository findings and implementation friction)
- step execution notes

## 🗂️ Tracked steps

| Step | File                                                                               | Status    |
| ---- | ---------------------------------------------------------------------------------- | --------- |
| 1    | [step-1-pylint-baseline.md](./step-1-pylint-baseline.md)                           | Completed |
| 2    | [step-2-remaining-pylint-findings.md](./step-2-remaining-pylint-findings.md)       | Completed |
| 3    | [step-3-radon-complexity-hotspots.md](./step-3-radon-complexity-hotspots.md)       | Completed |
| 4    | [step-4-docstring-policy.md](./step-4-docstring-policy.md)                         | Completed |
| 5    | [step-5-framework-aware-suppressions.md](./step-5-framework-aware-suppressions.md) | Completed |
| 6    | [step-6-ci-enforcement-decision.md](./step-6-ci-enforcement-decision.md)           | Completed |
| 7    | [step-7-radon-maintenance-policy.md](./step-7-radon-maintenance-policy.md)         | Completed |

## 📌 Current state

- Step 1 is complete.
- Step 2 is complete.
- Step 3 is complete.
- Step 4 is complete.
- Step 5 is complete.
- Step 6 is complete.
- Step 7 is complete.
- `radon mi` remains healthy overall.
- The biggest complexity hotspots are concentrated in large contract tests rather than the runtime path.
- Static analysis is now part of the CI quality stack through the dedicated `python-quality` job.
- Step 6 remains useful as a historical decision record for the earlier local-only phase before CI enforcement was added.
- `radon` now has a documented maintenance policy. All tracked hotspots reached A-rank after the cleanup path; no B-ranked blocks remain.
