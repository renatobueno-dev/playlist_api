# 🧪 Phase 1 — Step 2: First Test Layer Decision

## 📌 Context

After defining the minimum test scope in Step 1, the next decision is the first testing layer to implement.
The immediate confidence gap is API behavior correctness, not infrastructure wiring.

## 🎯 Layer decision

The first testing level is:

- API contract tests

This means tests are centered on request/response behavior and persisted outcome through API endpoints.

## ✅ Behavior expectations for this layer

The first-layer tests must answer:

1. Does the endpoint accept valid input?
2. Does the endpoint reject invalid input with expected status codes?
3. Does the endpoint return expected response shape?
4. Does the endpoint produce expected data-state changes?

## 🚫 Out of scope in Step 2

- Kubernetes tests
- Docker tests
- Istio tests
- GitHub Actions workflow behavior tests
- broad end-to-end environment matrices

## 🏁 Completion criteria

Step 2 is complete when the test strategy explicitly treats API contract behavior as the first validation layer.

## 📝 Step execution notes

- The first layer is now locked to API contract behavior for this roadmap cycle.
- No coding/runtime issue was observed in this step because this is a decision and documentation step.
