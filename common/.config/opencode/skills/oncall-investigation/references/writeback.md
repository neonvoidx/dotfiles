# Investigation Writeback Guidance

Use this file to draft or post an investigation result to Jira or OTS.

## Repository Version Preflight

Use the repository version preflight result captured at workflow start. If it is missing, run `repository-version-preflight` with `../SKILL.md` before drafting the customer-facing body.

When the active skill is stale, add this warning immediately after the first line:

`WARNING: This writeback is not using the latest On-Call Investigation skill version. It used On-Call Investigation vX.Y.Z, but the latest repository On-Call Investigation skill version is vA.B.C. The investigation may not include the latest workflow checks.`

When the repository comparison could not be completed, add this warning instead:

`WARNING: The On-Call Investigation repository version check could not be completed. This writeback used On-Call Investigation vX.Y.Z, but it could not verify whether that is the latest repository version. Blocker: <brief blocker>.`

The warning is informational and does not block a complete writeback.

## Writeback and Authorization Boundary

- Prepare and show a complete writeback draft after an investigation-required run.
- After showing the complete draft, post that exact comment to the authoritative ticket without waiting for a second authorization step.
- After successful comment posting, automatically synchronize the necessary complete-investigation labels defined below.
- Do not update companion fields or transition ticket status without explicit user authorization.
- Use `ots-ticket` or `jira-ticket` as the transport for comment and supported label mutations, then verify the attempted results.
- If comment posting fails, do not continue with label synchronization; report the failure without implying the ticket was updated.
- For AI-ineligible tickets, do not draft or post an investigation writeback unless the user gives a new explicit instruction outside this skill.
- For blocked investigations, do not post or mutate by default. If the user explicitly requests a blocked comment, use only the compact blocked format below and add only `ai-triage-blocked` when label mutation is supported.

## Complete Writeback Shape

Every ticket comment begins with:

`[codex-gpt-5.5] On-Call Investigation v<current-version>`

Replace `<current-version>` with the version in `../SKILL.md`.

Required sections for complete investigation writeback:
- `Investigation Summary`
- either `RCA` or `Assessment`
- `Impact`
- `Evidence`
- `Next Actions`

Use `RCA` only when the root cause is confirmed by current incident evidence. Otherwise, use `Assessment` for the leading hypothesis, confidence, contradictions, and next validating step. Do not place an unconfirmed hypothesis under an unqualified `RCA` heading.

Add these sections only when they provide decision value:
- `Recommendations` for durable prevention or design improvements that are distinct from immediate next actions
- `Timeline` when timing materially explains cause, impact, or mitigation
- `Owner Split` when evidence crosses service boundaries
- `Findings` when multiple novel conclusions do not fit cleanly in the core sections
- `Historical Similar Ticket Reference (Non-RCA)` only when prior tickets materially influenced the conclusion or handling
- `Reference FAQs (Non-RCA)` only when configured docs materially answer the ticket question

Default order:
1. `Investigation Summary`
2. `RCA` or `Assessment`
3. `Impact`
4. `Evidence`
5. conditional sections
6. `Next Actions`

## Lean Complete Writeback Skeleton

```md
[codex-gpt-5.5] On-Call Investigation v<current-version>

## Investigation Summary
- <decision-ready conclusion and current state>

## RCA
- <confirmed first failed dependency, code path, or runtime condition>

## Impact
- <confirmed scope and count, or explicitly unknown>

## Evidence
- <decision-relevant investigation delta>
- <full material identifiers once, plus scoped links or reproducible queries>

## Next Actions
- <owner> — <concrete action> — <expected result>
```

When root cause is not confirmed, replace `RCA` with:

```md
## Assessment
- Leading hypothesis: <hypothesis>
- Confidence: <high, medium, or low>
- Missing validation: <next evidence needed>
```

## Minimal Blocked-Investigation Skeleton

Use this format only when required evidence remains blocked and the user explicitly requests a ticket comment before the blockers are fixed.

```md
[codex-gpt-5.5] On-Call Investigation v<current-version>

## Investigation Blocked
Required evidence is unavailable, so this is not a complete RCA.

## Blockers
- <blocked evidence surface and exact access problem>

## Current Summary
- <what is confirmed so far>

## Next Step
- <specific unblock action and owner when known>
```

Do not add full evidence, normal triage labels, NOC labels, status transitions, or companion-field updates to a blocked writeback.

## Content Rules

- Write the investigation delta, not ticket boilerplate.
- Do not repeat information already present on the ticket unless the investigation independently verifies, corrects, quantifies, contradicts, or materially correlates it.
- Distinguish confirmed facts from hypotheses.
- State impact scope and count when supported; otherwise state exactly what could not be quantified and why.
- Preserve full OCIDs, request ids, workflow ids, work request ids, alarm ids, and deployment ids only when they are material to reproduction or validation.
- Introduce each full identifier once, then refer to it clearly instead of repeating it in every section.
- Prefer short log excerpts or paraphrases over stack-trace dumps.
- Include scoped investigation links pinned to the incident window and strongest filters. Avoid broad default links.
- Include a negative NOC, Shepherd, ODO, dashboard, release, metric, or log check only when it rules out a plausible cause or materially changes confidence. Keep it to one concise sentence unless additional detail is needed to reproduce the result.
- Include historical comparison only when it materially changed confidence, handling, ownership, or next actions. Do not add no-match or skipped-comparison boilerplate solely to satisfy the template.
- Include FAQ/doc references only when they materially answer the ticket question. Mark them `Non-RCA` unless current incident evidence independently confirms the conclusion.
- End with concrete next actions, not a generic monitoring statement.
- Do not mention internal formatting rules or skill-process rationale in the customer-facing comment.

### Section boundaries

- `Impact` states the resulting scope and count.
- `Evidence` explains how the scope or conclusion was derived, without restating the result in every bullet.
- `RCA` or `Assessment` states the causal conclusion and confidence.
- `Findings` contains only additional novel conclusions that do not fit the other core sections.

### Meaningful findings

Every finding must include or clearly identify:
- a new conclusion not already stated on the ticket
- the evidence that supports it
- whether it is confirmed or inferred
- why it changes RCA confidence, scope, ownership, or next actions

Omit `Findings` when there are no novel conclusions. Do not use it to repeat `RCA`, `Assessment`, `Impact`, or `Evidence`.

## Post-Comment Mutation Plan

Apply this section only after the complete comment body is final and posts successfully.

### Companion fields

- Keep the markdown comment as the durable artifact.
- Update Jira `Root Cause Description`, `Resolution Description`, and `Status Update`, or the corresponding OTS resolution summary fields, only when the fields exist, the transport supports them, and the authorization includes companion-field mutation.
- Keep companion fields to one sentence each.
- Do not write a leading hypothesis into a root-cause field as if it were confirmed. Leave the field unchanged unless the user explicitly authorizes a clearly qualified hypothesis.
- Skip companion fields for blocked investigations.

### Labels

- Remove `ai-triage-blocked` after a completed investigation when supported.
- Add `ai-skill-triage` and `ai-triaged-by-<ticket-project-key>` automatically after a successful complete writeback.
- Derive the project-scoped label from the live ticket project reconciled against the selected team config. Do not guess when ambiguous.
- Add exact related NOC ticket ids only when those incidents are confirmed reference context in the final comment.
- Add `ai-rca` only when the final comment contains a confirmed root cause.
- For an explicitly requested blocked comment, add only `ai-triage-blocked`.

### Status

- After a complete comment and label sync, transition an open or not-yet-started ticket to `In Progress` only when explicit authorization includes status mutation and the transport supports it.
- Never transition status for a blocked investigation.

Report unsupported or out-of-scope mutations in the assistant response. Do not clutter the ticket comment with internal transport diagnostics unless the limitation affects incident handling.

## Pre-Post Checklist

- The first line contains the active skill version and any required version warning follows it.
- The body uses `RCA` only for a confirmed cause; otherwise it uses `Assessment`.
- `Investigation Summary` adds information beyond the ticket description.
- `Impact` states confirmed scope or an explicit evidence gap.
- `Evidence` contains only decision-relevant investigation delta and reproducible identifiers or links.
- Information already present on the ticket appears only when it was independently verified, corrected, quantified, contradicted, or materially correlated.
- Every `Findings` entry is novel, evidence-supported, confidence-qualified, and operationally relevant; otherwise the section is omitted.
- Conditional historical, FAQ, timeline, owner, findings, and recommendations sections appear only when they add decision value.
- `Next Actions` identifies concrete owner/action follow-up when known.
- The exact draft has been shown to the user unless a clearly approved unattended automation mode applies, and the posted comment matches that draft.
- Necessary complete-investigation labels are synchronized only after successful comment posting.
- Explicit authorization covers every companion-field and status mutation.
- Blocked and AI-ineligible safeguards remain intact.
