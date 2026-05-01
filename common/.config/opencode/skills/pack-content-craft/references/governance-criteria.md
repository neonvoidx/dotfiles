# Governance Criteria

Tier model, admission criteria, and demotion triggers for pack resources. Loaded when pack-content-craft is invoked — not always-on.

## Principles

1. **Small by default** — default profile loads only what operators actually use.
2. **Evidence over volume** — no promotion without real usage evidence.
3. **Owned resources only** — every baseline resource has a current owner (DRI).
4. **Delete before deprecate** — stale content is removed, not annotated. Git preserves history.
5. **One job per resource** — a rule does one thing, a workflow solves one problem, a skill teaches one capability.

## Baseline in Control (BiC)

- Cap default-loaded (Tier A) resources to **2-4 per vector** (rules, skills, workflows, agents, MCP).
- **Meta-pack exception:** packs whose rules govern other packs' content (e.g., aipack-core) may exceed the cap when each rule is structurally mandatory. Rules exceeding the cap must use `paths`-based conditional loading where harness-supported.
- Additional resources remain opt-in (Tier B/C) only.
- Tier A requires: owner, use-case mapping, success metric, evidence, rollback condition, last-reviewed date. Missing any → keep out of Tier A.

## Demotion

- Demote from Tier A when: no review in 30 days, owner missing, repeated low-value outcomes, or safety regression.
- Retire resources demoted for 2 consecutive cycles unless owner presents a recovery plan.

## Verify

- Tier A counts per vector are within cap.
- Every Tier A item has owner + evidence + last-reviewed date.
