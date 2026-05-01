# Execution Baselines — Detail

Extracted from: `rules/ocm-execution-baselines.md`

## When not to use

- Non-pack code under the repo root (modules like `platform/`, `release/`, etc.).
- Not an operational runbook for production changes.

## Requirements (inputs)

Capture these **before** executing or authoring:

- **Intent + scope**: what you will produce/run, and what is explicitly out of scope.
- **Execution mode**: one of:
  - authoring-only (local markdown/code edits)
  - read-only execution (queries, list/get, validation gates)
  - mutation-intent (create/update/delete/terminate; see Mutation gate)
- **Tool surface**: which harness + which access surface(s) you will touch.
- **Access readiness**: which warmup(s) you ran (or will run) to avoid auth surprises.
- **Evidence plan (sanitized)**: where you will store proof of verification (if needed) and what snippets are safe to retain.
- **Rollback story (required for mutation-intent)**: the specific rollback action(s) you will take if the mutation is wrong or partial.

## Audit expectations

For any non-trivial execution (multiple calls, multi-step workflow, or any mutation-intent), you must be able to answer:

- **What changed** (or what you proved), and **why**.
- **When** it was executed (timestamp / window).
- **What evidence** supports the claim (sanitized output, diff, validation gate output).
- **Who approved mutation** (explicit "yes" in the chat, or a ticket/PR reference).

## Steps

1) **Preflight.**
   - Confirm the intended execution mode (authoring-only vs read-only vs mutation-intent).
   - If you will touch an external tool surface, run the relevant access warmup(s) first (see `skills/ocm-dev/access-warmups-detail.md`).

2) **Execute in read-only first.**
   - Prefer discovery/list/read calls before any state change.
   - If a step could write state, treat it as mutation-intent and apply the Mutation gate.

3) **Apply the Mutation gate (stop + confirm).**
   - If any step will mutate state, you must stop and ask for explicit confirmation.
   - Your confirmation request must include:
     - the exact target(s) (resource/ticket/repo/branch)
     - the exact action(s) (create/update/delete/terminate)
     - the expected outcome (what success looks like)
     - the **rollback story** (what you will do if it goes wrong)
     - the evidence you will capture (sanitized)

4) **Run the workflow; do not restate it.**
   - Follow the relevant workflow as written and keep this rule as governance only.

5) **Capture minimal evidence (sanitized) and produce a handoff artifact when needed.**
   - Keep evidence small and portable (no secrets; no forbidden identifiers).
   - If the work affects oncall continuity, generate a handoff note using: `workflows/generate-handoff-note.md`.

## Outputs

- New and updated artifacts must follow the authoring standard structure.
- New artifacts must be linkable and reusable (prefer relative links within the pack).

## Evidence

When you need to retain evidence of verification (local-only; never commit):

- Store it under a gitignored local directory (for example: `.generated/evidence/ocm-ai-pack/<YYYY-MM-DD>/`).
- Keep evidence safe to share (no secrets, no forbidden identifiers). If it is not safe to share, do not store it.

## Failure modes

- **`aipack doctor` fails (secrets/portability).**
  - Recovery: remove the violating content; replace secrets with `{env:VAR}` placeholders; remove absolute paths; re-run validation.

- **A workflow mixes discovery and mutation without a gate.**
  - Recovery: split the flow or add an explicit "MUTATION (stop + confirm)" step immediately before any state change.

- **Mutation was attempted without a rollback story.**
  - Recovery: stop; document current state; define rollback; only then re-attempt with explicit confirmation.

- **Docs drift (same rule duplicated across multiple workflows).**
  - Recovery: move governance text into `rules/` and link to it from workflows.

## References

- Pack structure + non-negotiables: `AGENTS.md`
- Access warmups governance: `skills/ocm-dev/access-warmups-detail.md`
- Handoff template: `skills/ocm-dev/handoff-template.md`
