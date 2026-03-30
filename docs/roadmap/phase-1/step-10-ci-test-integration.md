# 🔄 Phase 1 — Step 10: Integrate Tests Into CI

## 📌 Context

After local stability was proven, the next checkpoint is CI behavior validation so pull requests verify API contract behavior, not only build and infrastructure wiring.

## 🎯 Scope decision

This step adds test execution to the existing validation flow:

- install both runtime and test dependencies in the validation job
- run contract tests during the validation job
- keep deploy job flow unchanged

## ✅ Implementation

Updated:

- `.github/workflows/deploy.yml`

Validation job changes:

- dependency install now includes:
  - `requirements.txt`
  - `requirements-dev.txt`
- new step added:
  - `python3 -m pytest -q tests`

Resulting validation pipeline order (relevant section):

1. checkout
2. setup python
3. install runtime + test dependencies
4. run API contract tests
5. compile modules
6. Docker/Helm/Terraform validation steps

## 🔁 Validation

Commands executed locally to mirror CI behavior:

```bash
./.venv/bin/python -m pytest -q tests
./.venv/bin/python -m compileall app
```

Results:

- tests: `14 passed`
- compile check: completed with no errors

## 🐞 Step execution notes (issues)

- No blocking issue occurred in this step.
- CI integration was applied only after local suite stability had already been verified in Step 9.

## 🏁 Completion criteria

Step 10 is complete when each pull request runs automated API behavior tests as part of validation, expanding CI confidence from infrastructure wiring to application contract correctness.
