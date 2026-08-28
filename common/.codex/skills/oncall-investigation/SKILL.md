---
name: oncall-investigation
description: Investigate production incidents using a service-team config that can combine Jira or OTS tickets, FAQ/doc URLs, Bitbucket or SCM repositories, local repo paths, alarm or metric pages, Lumberjack log settings, and Shepherd release scopes. Use when Codex needs a repeatable on-call workflow that correlates tickets, docs, metrics, logs, code, and recent deployments.
---

# On-Call Investigation

Current skill version: `1.6.0`.

Repository version source:
- remote_file_url: `https://bitbucket.oci.oraclecorp.com/projects/TENLS/repos/dev-starter-skills/raw/skills/oncall-investigation/SKILL.md?at=refs/heads/master`

This is the source of truth for the On-Call Investigation skill version. A change to any file under `skills/oncall-investigation/` is incomplete unless this version is incremented in the same change. Reviewers must hold or reject On-Call Investigation skill updates that do not include the version bump. Use semantic versioning: patch for wording or narrow rule clarifications, minor for workflow or writeback behavior changes, and major for intentionally incompatible investigation-contract changes.

Use this skill for incident triage and on-call investigation when the service team has already defined where Codex should read tickets, inspect FAQ/docs, inspect alarms or dashboards, search logs, check releases, and read code.

The skill is intentionally config-driven. A team can define one or more service entries in a shared TOML file and point Codex at the relevant entry during an investigation.

Use `assets/service-team-config.template.toml` as the starting point for new teams, keep real team configs under `assets/service-teams/`, and use `references/configuration.md` as the only config schema and field-reference document.

## Routing

- Use this skill for most incident, operational, and RCA tickets that are not `CHANGE` tickets.
- Use `CM Review` for `CHANGE` tickets, even when they mention incidents, manual remediation, or Shepherd release links.
- Use `Release Check` only as a sub-workflow when a non-`CHANGE` investigation needs release-specific Shepherd evidence. Keep this skill as the outer investigation workflow unless the user's primary question is release-specific.
- If the ticket, prompt, or attached AIPack summary includes precomputed RCA, region, timeline, or scope hints, treat that material as intake context to verify, not as source of truth over live ticket, alarm, metric, log, or release evidence.

## Fast Path

1. Run repository version preflight.
2. Load the service-team config and select the correct `[[team]]` block.
3. Validate the required auth before any ticket, OCI, DevOps, or logging reads:
   - check OCI session-backed auth such as OTS helpers before use
   - check token-backed auth such as `OP_TOKEN` before relying on direct DevOps or logging paths
   - for `oc1` OCI session auth, prefer the MCP `refresh_oci_session` tool when available and allow interactive browser authentication by default so the local profile is fixed before continuing
   - if a required token or session is still invalid after the allowed refresh or authentication flow, pause the investigation and tell the user exactly what to refresh before continuing
4. Read the incident ticket first and classify it as either:
   - `investigation required`
   - `informational / data-only`
5. Check AI eligibility from live ticket labels before any FAQ/doc pass, historical triage, broad evidence collection, or ticket mutation:
   - compare labels case-insensitively after trimming whitespace
   - if any label matches an AI-ineligible label, stop the investigation and warn the user that the ticket is not eligible for AI triage
   - include the exact matched label or labels in the warning
   - do not post comments, add labels, transition status, or update companion fields for AI-ineligible tickets unless the user gives a new explicit instruction outside this skill
6. For all AI-eligible tickets, classify the ticket cut type as:
   - `human-cut`
   - `automation-cut`
   - `unknown`
   - classify as `automation-cut` when reporter, creator, or initial context is clearly system- or bot-generated
   - if the cut type is `unknown`, skip historical triage unless the user explicitly asks for it
7. Resolve ticket source of truth:
   - if the ticket includes `Master OTS` reference or OTS ticket id/link, treat OTS as source of truth
   - otherwise, treat Jira as source of truth
   - when OTS is source of truth, do not use Jira for authoritative incident fields
   - if OTS source-of-truth read is unavailable, stop and ask for auth/session fix
8. Re-check AI eligibility after source-of-truth resolution if the workflow pivots to an OTS master or canonical incident ticket.
9. For `human-cut` tickets, run a best-effort FAQ/doc answer pass immediately after ticket intake:
   - if `[[team.faqs]]` is configured, read all configured FAQ URLs
   - compare ticket question and symptom context against FAQ/doc content
   - if the ticket question is clearly answerable from FAQ/docs and not contradicted by current ticket evidence, prepare a concise `Reference FAQs (Non-RCA)` draft with:
     - answer summary
     - source FAQ/doc names and URLs
     - explicit non-RCA wording (doc guidance, not incident proof)
   - if no strong FAQ/doc answer exists, or URLs are inaccessible, skip this step and continue triage
10. For `investigation required` and `human-cut` tickets, run a best-effort historical ticket triage immediately after ticket intake:
   - derive queue or equivalent context from live ticket metadata first
   - for Jira SD tickets, treat the project key as queue/context when explicit queue metadata is unavailable:
     - `.../projects/<PROJECT>/queues/custom/<id>/<ISSUE>` -> queue/context `<PROJECT>`
     - `.../browse/<PROJECT-123>` -> queue/context `<PROJECT>`
   - if queue metadata is unavailable or inaccessible, use request type, incident type, labels, and high-signal summary keywords
   - continue investigation even if no strong historical matches are found
11. For `informational / data-only` tickets:
   - gather only the requested facts
   - avoid broad code, log, or release exploration
   - return a concise answer
12. For `investigation required` tickets:
   - follow `references/workflow.md`
   - if the starting ticket is in Jira and it points to an OTS master or canonical incident ticket, pivot to the OTS ticket as the primary incident record before broad evidence collection
   - present the pre-execution investigation plan and wait for explicit user approval before broad evidence collection when working with a human user
   - load only the branch references needed for the current incident
   - use `references/metrics.md` as the canonical source for region resolution
   - keep this skill as the primary workflow when release evidence is present, and call `Release Check` only when release-specific behavior needs deeper analysis
   - if auth blocks any planned evidence surface such as alarms, metrics, logs, dashboards, releases, or code hosts, try the supported automatic recovery first, then ask the user to fix unresolved blockers before continuing
   - when required evidence remains blocked after supported recovery, mark the run as `investigation blocked`
   - do not automatically write ticket comments, labels, status transitions, or RCA companion-field updates while the investigation is blocked
   - if the user explicitly asks to comment on the ticket while the investigation is blocked, write only a compact blocked-investigation update, then add `ai-triage-blocked`
   - do not write the full investigation context, normal triage labels, status transitions, or RCA companion-field updates until the blockers are fixed and the investigation completes
   - after blockers are fixed and the investigation completes, draft the full investigation and present it to the user
   - after showing the complete draft, post that exact comment and synchronize the necessary complete-investigation labels without waiting for a second authorization step
   - automatically remove `ai-triage-blocked` when supported, add `ai-skill-triage` and the project-scoped `ai-triaged-by-<ticket-project-key>` label, add confirmed related NOC ids, and add `ai-rca` only for a confirmed root cause
   - require explicit user authorization before updating companion fields or transitioning ticket status
   - follow `references/writeback.md` for post-comment label and status handling, including adding exact related NOC ticket ids and project-scoped triage labels when supported
   - record durable memory only when the investigation produced a reusable lesson

Default classification:
- `investigation required` when there is active or recent customer impact, alarms, canary failures, repeated errors, failed workflows, unclear root cause, or an explicit request to determine cause or remediation
- `informational / data-only` when the user only wants data lookup, status reporting, or historical context and there is no request to determine cause or remediation

AI-ineligible labels:
- `MFO_GENERATED_TICKET`
- `OCIONOCI`
- `PHONEBOOK-QUARTERLY-VALIDATION`
- `PSA`
- `RB-AUTOMATION`
- `RBC`
- `RBC_REGION_BUILD`
- `REGION_BUILD_FAILURE_RCA`
- `SC_AUTOCUT`
- `SECURITYCENTRAL`
- `VULNERABILITYSCAN`
- `AI-TRIAGING-NOT-NEEDED`

Default investigation order:
1. repository version preflight
2. team config
3. auth preflight
4. ticket
5. AI eligibility check from live labels
6. ticket cut-type classification
7. source-of-truth resolution (`Master OTS` => OTS, otherwise Jira)
8. AI eligibility re-check if source-of-truth resolution pivots to a different ticket
9. FAQ/doc answer pass (best-effort, human-cut only)
10. historical ticket triage (best-effort, human-cut and investigation-required only)
11. pre-execution plan
12. explicit approval for human-driven investigations
13. metrics and logs
14. regional NOC cross-check using the workflow-defined NOC correlation window when a concrete investigation region has been derived
15. impact analysis
16. deployments and releases using the workflow-defined deployment correlation window
17. code
18. conclusion review
19. show the writeback draft, then automatically post the complete comment and synchronize necessary labels

If the ticket is canary-backed, insert the canary flow before broad log hunting.

## Operational Checklist and Guardrails

Use this entrypoint summary to avoid missing the non-negotiables. The detailed execution order remains in `references/workflow.md`, and the detailed ticket-writeback contract remains in `references/writeback.md`.

Checklist:
- select the service-team config
- validate auth before evidence reads
- read the ticket and classify the work
- stop immediately with a warning when live ticket labels make the ticket AI-ineligible
- present the pre-execution plan and wait for approval in human-driven investigations
- collect evidence from the highest-signal sources first
- complete impact analysis
- challenge the conclusion before finalizing
- show the complete investigation draft, then automatically post that exact comment and synchronize necessary labels
- for blocked investigations, do not automatically comment, label, transition status, or update companion fields
- for user-requested blocked-investigation comments, add `ai-triage-blocked` and no normal triage labels

Must do:
- validate required OCI, ticket, DevOps, and logging auth before relying on those surfaces
- check live ticket labels against the AI-ineligible label set before broad investigation
- try supported automatic blocker recovery before stopping, then ask the user to fix unresolved blockers before continuing
- mark the investigation as `investigation blocked` only when required evidence remains blocked and the run cannot continue to completion
- use runtime evidence, not ticket actor metadata, for region and AD scope
- preserve full durable identifiers in the investigation writeback
- draft and show the complete final investigation, include the active On-Call Investigation skill version, and include the repo-latest version warning from `references/writeback.md` when the current run is stale or the repository version check could not be completed
- post the exact shown draft and synchronize necessary complete-investigation labels without waiting for a second authorization step
- after successful complete writeback, remove `ai-triage-blocked` when supported, sync `ai-skill-triage` and the project-scoped `ai-triaged-by-<ticket-project-key>` label, add confirmed related NOC ids, and add `ai-rca` only when the writeback contains a confirmed root cause
- obtain explicit user authorization before updating companion fields or transitioning ticket status

Must avoid:
- using this skill as the outer workflow for `CHANGE` tickets
- continuing AI triage after finding any AI-ineligible label on the live ticket
- trusting existing comments, AIPack summaries, or copied RCAs without live verification
- running broad metrics, logs, release, dashboard, or code investigation before explicit approval in human-driven investigations
- guessing region, AD, tenant, namespace, or release scope when stronger runtime evidence is unavailable
- presenting a complete RCA when planned evidence is missing or auth-blocked
- automatically writing ticket comments, applying normal triage labels, status-transitioning, or RCA companion-field updating tickets whose investigation is blocked
- updating companion fields or transitioning ticket status without explicit user authorization
- using `ai-skill-triage`, project-scoped triage labels, or `ai-rca` for blocked-investigation writebacks; use only `ai-triage-blocked` when the user explicitly requests a blocked ticket comment
- implying labels, status, or companion summary fields changed when the ticket transport could not mutate them

## Reference Guide

Read references progressively instead of loading everything up front.

- `references/workflow.md`
  - Read for the end-to-end investigation process, decision points, synthesis, and memory handling.
- `references/configuration.md`
  - Read for team-config structure, field semantics, multi-team examples, and selection rules.
- `references/metrics.md`
  - Read when the incident is alarm-backed, metric-backed, region-ambiguous, or time-window-ambiguous.
- `references/canary.md`
  - Read when the ticket is canary-backed and the team config includes `team.canary`.
- `references/logging.md`
  - Read when searching Lumberjack, DevOps, or splat logs, or when the right tenant, compartment, or namespace is uncertain.
- `../release-check/references/workflow.md`
  - Read when the ticket includes a specific Shepherd release link or identifier, or when the investigation becomes release-first; treat `Release Check` as the source of truth for release evidence order, raw target-log review, sibling-release comparison, and release-specific timeline construction.
- `references/writeback.md`
  - Read before posting any investigation comment so the final body, active skill-version disclosure, companion summary-field updates, and post-comment ticket sync all match the required writeback contract.

## Working Rules

- Use this skill for most non-`CHANGE` tickets. Route `CHANGE` tickets to `CM Review`.
- Treat existing human comments as unverified context until they are confirmed independently.
- Treat Jira SD as human-source by default unless the reporter, creator, or initial context is clearly bot- or system-generated.
- Ticket source of truth rule: if `Master OTS` is present, OTS is source of truth; otherwise Jira is source of truth.
- When OTS is source of truth, Jira is not authoritative for incident fields.
- Before FAQ/doc answers, historical triage, broad investigation, or writeback, compare live ticket labels case-insensitively against the AI-ineligible label set. If any match, stop and warn the user with the matched labels.
- For human-cut tickets, use `[[team.faqs]]` URLs as best-effort doc context, and prepare a concise `Reference FAQs (Non-RCA)` draft only when docs clearly answer the ticket question without contradiction. Post it only with explicit authorization or in a clearly approved unattended automation mode.
- Treat AIPack or other AI-generated investigation summaries the same way: preserve useful identifiers, but re-verify RCA, scope, region, and timeline claims against live evidence before relying on them.
- Validate the required token- or session-based auth before execution instead of discovering auth failures midway through the investigation.
- If a required token or session is invalid, first use the supported automatic refresh or authentication path. If it still cannot be recovered, pause and notify the user which token or session must be refreshed before continuing.
- If auth blocks any evidence surface required by the plan, do not present the result as a complete RCA. Ask the user to fix unresolved blockers before continuing and mark the run as `investigation blocked`. Do not automatically comment or mutate ticket labels/status while blocked. If the user explicitly asks to comment while blocked, write only a compact blocked-investigation update, then add `ai-triage-blocked`; wait until the blockers are fixed and the investigation completes before using the full writeback process, normal triage labels, status transitions, or RCA companion-field updates.
- Use the configured ticket sources as the primary incident entry point, and use `ots-ticket` or `jira-ticket` as transport helpers for ticket reads and writes.
- For human-driven investigations, present a concise execution plan after ticket intake, then pause and wait for explicit user approval before broad evidence gathering. In unattended automation, derive the same plan internally without stopping for presentation.
- Keep broad incident correlation inside this skill, including deciding whether nearby releases, ODO activity, or execution-target timing are relevant.
- When the ticket provides a specific Shepherd release, or when release investigation becomes the primary RCA path, use `Release Check` as the source of truth for release-specific investigation behavior instead of redefining the same rules inside this skill. Keep this skill as the outer workflow unless the question is purely release-specific.
- Keep code conclusions grounded in the evidence already gathered from tickets, metrics, logs, and releases.
- This skill is primarily investigative, with automatic complete-investigation comment and label writeback. Companion-field updates and status transitions require explicit authorization; memory updates follow the active runtime memory policy.
- If the investigation needs PR review context for a suspected code change, pair it with `bitbucket-pr` or `scm-pr` as appropriate.
