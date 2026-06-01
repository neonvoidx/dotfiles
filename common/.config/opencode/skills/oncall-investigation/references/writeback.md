# Investigation Writeback Guidance

Use this file before posting any investigation comment to Jira or OTS.

## Writeback contract

- This skill owns the investigation writeback format; use ticket helper skills only as transport for the final body.
- For investigation-required tickets, write complete investigations back to the ticket unless the user explicitly asks not to.
- For blocked investigations, do not automatically post ticket comments, add labels, transition status, or update companion fields.
- If the user explicitly asks to comment on the ticket while the investigation is blocked, write only a compact blocked-investigation update. It must state that the investigation is blocked, name the blockers, and identify the next unblock step.
- For user-requested blocked-investigation comments, add the `ai-triage-blocked` label when label mutation is supported. Do not add `ai-skill-triage`, project-scoped triage labels, NOC ticket-id labels, or `ai-rca`.
- Do not include the full investigation context, detailed evidence, complete RCA sections, status transitions, or companion-field updates for blocked investigations.
- After the user fixes the blockers and the investigation completes, post the full investigation comment, remove `ai-triage-blocked` when label mutation is supported, and then follow the normal label, status, and companion-field writeback process.
- Use `ots-ticket` or `jira-ticket` only to send the final comment body.
- For OTS-backed tickets, keep the full investigation in the ticket comment and, when the transport supports it and the investigation is complete, also update the short `Resolution Details` summary fields by default with concise versions of the same conclusion.
- If source-of-truth selection resolves to OTS (always for `human-cut`, or via `Master OTS` for non-human), treat the OTS ticket as authoritative for incident fields and do not substitute Jira values when OTS is unavailable.
- For Jira-backed tickets, keep the full investigation in the ticket comment and, when the issue exposes editable companion fields and the investigation is complete, also update the short `Root Cause Description`, `Resolution Description`, and `Status Update` fields by default with concise versions of the same conclusion.
- If the completed investigation was previously blocked and `ai-triage-blocked` is present, remove it when the ticket system and helper support label mutation. If removal is unsupported, state that limitation explicitly instead of implying the blocked label was cleared.
- After clearing any previous blocked label for a complete final investigation, check the live ticket labels. If `ai-skill-triage` is missing, add it when the ticket system and helper support label mutation.
- Also add the project-scoped label `ai-triaged-by-<ticket-project-key>` when missing on complete investigations. Derive `<ticket-project-key>` from the live ticket's project key reconciled against `team.tickets.jira_projects` or `team.tickets.ots_projects`; examples: `ai-triaged-by-AC`, `ai-triaged-by-AAT`, `ai-triaged-by-ORGMGMT`.
- If the live ticket project key is absent, conflicts with the selected team config, or more than one configured ticket project could apply, do not guess the project-scoped label. State the ambiguity explicitly and continue with the other supported writeback steps.
- If the final investigation identifies one or more related NOC incidents that are cited as reference context for the ticket, add each exact NOC ticket id such as `NOC-5429328` as a label on the ticket when the ticket system and helper support label mutation.
- Add NOC ticket-id labels only for NOC incidents that the writeback identifies as related reference context for the current incident. Do not add labels for merely nearby or unconfirmed NOC incidents.
- Add `ai-rca` only when the final writeback contains a confirmed root cause. Do not add it for hypotheses, likely causes, or still-open RCA investigations.
- After complete comment posting and label sync, check the live ticket status. If the ticket is still open or not-yet-started, move it to `In Progress` when the ticket system and helper support that transition.
- If the current ticket transport does not support label mutation, or the target ticket is not editable for labels, state that limitation explicitly instead of implying the label changed.
- If the current ticket transport does not support status mutation, state that limitation explicitly instead of implying the status changed.
- If the current ticket transport does not support the short summary companion fields, or the target ticket does not expose them as editable, state that limitation explicitly instead of implying they changed.
- If auth blocked any planned evidence surface, do not post a ticket comment by default. If the user explicitly asks to comment while blocked, post only the compact blocked-investigation update. State the blocker near the top of the comment, identify the blocked surfaces, and say that the investigation is blocked until that evidence is collected. Add `ai-triage-blocked` when supported; do not add normal AI triage labels, NOC ticket-id labels, update RCA companion fields, or transition ticket status for blocked-investigation writebacks.
- Every ticket comment written by this skill must begin with the prefix `[codex-gpt-5.5]` on the first line and mention the active On-Call Investigation skill version from `../SKILL.md`.
- First-line example: `[codex-gpt-5.5] On-Call Investigation v1.3.1`
- If the version in `../SKILL.md` has changed, use that current version instead of copying the example.
- Treat the ticket comment as a durable investigation artifact, not a quick note.
- Use markdown with explicit headers.
- Before posting, run a final format check against the exact body you are about to send.
- For investigation-required `human-cut` tickets, include a brief historical comparison note based on similar prior tickets, or explicitly state that no high-confidence historical match was found.
- For investigation-required `automation-cut` or `unknown` tickets, explicitly state that historical comparison was skipped and include the reason.
- For human-cut informational or service-request tickets that use prior-ticket context, label the section as `Historical Similar Ticket Reference (Non-RCA)` and avoid presenting the prior ticket as a confirmed RCA.
- For `human-cut` tickets, if configured FAQ/docs clearly answer the ticket question, post a concise `Reference FAQs (Non-RCA)` comment with answer summary and source names/URLs.
- Do not treat FAQ/doc guidance as confirmed RCA unless current incident evidence validates it.
- A FAQ/doc auto-comment does not replace final investigation writeback for investigation-required tickets.

Required sections for complete investigation writeback:
- `Investigation Summary`
- `Findings`
- `Evidence`
- `Recommendations`
- `Action Items`

Add more sections when needed:
- `Investigation Process`
- `RCA`
- `Timeline`
- `Owner Split`

Use `Owner Split` when the investigation crosses service boundaries. State the upstream symptom owner, the downstream service or dependency indicated by runtime evidence, whether downstream evidence was confirmed, unavailable, ambiguous, or auth-blocked, and the next owner action. Do not assign downstream ownership from suspicion alone.

## Mandatory pre-post checklist

- Confirm the first line begins with `[codex-gpt-5.5]` and includes the active On-Call Investigation skill version from `../SKILL.md`.
- Confirm every required section header is present verbatim.
- Confirm the comment distinguishes confirmed facts from hypotheses.
- Confirm the comment includes one of:
  - a historical comparison note
  - an explicit no-match statement
  - an explicit skipped-comparison statement with reason for `automation-cut` or `unknown` tickets
- Confirm any FAQ/doc auto-comment uses `Reference FAQs (Non-RCA)` wording and includes source names/URLs.
- Confirm the comment ends with actionable next steps.
- Confirm that durable evidence identifiers are written in full, not shortened with ellipses or partial prefixes, especially for OCIDs, request ids, workflow instance ids, work request ids, alarm ids, and deployment ids.
- Confirm that the investigation is complete before normal writeback.
- If the investigation is blocked, confirm that the user explicitly asked for a blocked ticket comment before posting.
- If the investigation is blocked and the user requested a comment, confirm that the comment uses the compact blocked-investigation format and does not include a current summary, hypotheses, evidence detail, or the full investigation context.
- Confirm that any auth blocker is called out explicitly and that the comment says the investigation is blocked when required evidence could not be collected.
- For blocked-investigation comments, confirm whether `ai-triage-blocked` was already present, added successfully, or blocked by a ticket-system limitation.
- For complete investigations that were previously blocked, confirm whether `ai-triage-blocked` was removed successfully, already absent, or blocked by a ticket-system limitation.
- For complete investigations, confirm whether `ai-skill-triage` was already present, added successfully, or blocked by a ticket-system limitation.
- For complete investigations, confirm whether `ai-triaged-by-<ticket-project-key>` was derived from the ticket project plus selected team config and was already present, added successfully, intentionally skipped due to ambiguity, or blocked by a ticket-system limitation.
- For complete investigations, confirm whether each related NOC ticket-id label was already present, added successfully, intentionally skipped because no related NOC reference was confirmed, or blocked by a ticket-system limitation.
- Confirm whether `ai-rca` was added, intentionally skipped because RCA was not confirmed, skipped because the investigation was blocked, already present, or blocked by a ticket-system limitation.
- Confirm whether the short summary companion fields were updated, intentionally skipped because the investigation was blocked, intentionally skipped for another reason, or blocked by ticket-system limitations.
- For blocked-investigation writebacks, confirm that normal AI triage labels, NOC ticket-id labels, status transitions, and companion-field updates were intentionally skipped.
- For complete investigations, confirm whether the ticket remained open after comment posting and label sync and either transitioned it to `In Progress` or documented the transport limitation.
- If a previous comment was already posted in the wrong format, do not silently ignore it. Post a corrected follow-up comment that explicitly supersedes the earlier unstructured note.

## Minimal writeback skeleton

```md
[codex-gpt-5.5] On-Call Investigation v1.3.1

## Investigation Summary
...

## Findings
...

## Evidence
...

## Recommendations
...

## Action Items
...
```

## Minimal blocked-investigation skeleton

Use this smaller format only when required evidence remains blocked and the user explicitly asks for a ticket comment before the blockers are fixed. Do not add the full investigation sections until the blockers are fixed and the investigation completes.

```md
[codex-gpt-5.5] On-Call Investigation v1.3.1

## Investigation Blocked
The investigation is blocked because required evidence is unavailable.

## Blockers
- ...

## Next Step
- ...
```

## Short summary companion fields

- Keep the comment as the durable investigation artifact.
- For complete OTS-backed tickets, and for complete Jira-backed tickets when the issue exposes editable companion fields, also prepare three short summary strings when the investigation is mature enough:
  - `Root cause description`
  - `Resolution description`
  - `Status update`
- These fields should be brief scan-friendly summaries, not replacements for the markdown comment.
- For Jira-backed tickets, map these summaries onto the issue fields `Root Cause Description`, `Resolution Description`, and `Status Update`.
- Good default pattern:
  - `Root cause description`: one sentence on the best confirmed cause, or the leading hypothesis if still unconfirmed
  - `Resolution description`: one sentence on mitigation, recovery, or the operator action taken
  - `Status update`: one sentence on current state and the next active owner step
- If the investigation is still in progress but not blocked, say so plainly instead of overstating certainty.
- If the investigation is blocked, skip these companion fields until blockers are fixed and the investigation completes.

## Content expectations

The ticket comment should capture:
- scope and approach
- investigation order
- key evidence streams checked
- exact incident identifiers when available, such as region, AD, tenant, account, workflow id, request id, work request id, alarm id, metric name, deployment id, application alias, host name, backend set, and load balancer id
- full durable resource identifiers when available. Do not shorten or partially mask identifiers such as tenancy OCIDs, resource OCIDs, request ids, workflow instance ids, work request ids, alarm ids, or deployment ids inside the main ticket comment because the next reader should be able to copy them directly and re-run the evidence lookup.
- confirmed findings
- important metrics, counts, timestamps, or retry limits
- what failed first versus what happened later as a consequence
- current status, including whether cleanup, retry, requeue, bounce, or rollback happened
- related incidents and whether the current incident is the same underlying chain or only a similar symptom
- any related NOC incident ids cited as reference context, and whether their exact ticket ids were added as labels or could not be synced due to ticket-system limitations
- a short historical comparison outcome that states:
  - for `human-cut`: top comparable tickets and the strongest matching signals when available
  - for `human-cut`: explicit no-match language when no high-confidence historical match was found
  - for `automation-cut` or `unknown`: explicit skipped-comparison language with reason
  - confidence level and known gaps
- when the ticket is a service-request or informational path, include a short `Historical Similar Ticket Reference (Non-RCA)` note with:
  - prior ticket id(s)
  - handling pattern reused
  - explicit non-RCA wording
- when FAQ/docs clearly answer a `human-cut` ticket question, include a short `Reference FAQs (Non-RCA)` note with:
  - answer summary
  - source FAQ/doc names and URLs
  - explicit non-RCA wording
- best conclusion
- recommended follow-up
- explicit owner split when relevant

## Evidence rules

- Keep the writeback evidence-based.
- Distinguish clearly between confirmed facts and hypotheses.
- In the main ticket comment, keep durable identifiers copyable and complete:
  - use the full OCID, full `opc-request-id`, full workflow instance id, and other full lookup keys whenever they are cited as evidence
  - do not replace the middle of an identifier with `...`, abbreviate to only the first few characters, or describe it as "same request id as above" when the exact value is material evidence
  - if the same full identifier is reused many times, introduce it once in full and then reference it clearly, but keep at least one full copy in the durable comment body
- The short companion summary fields may stay concise and do not need to repeat every full identifier, but they must not contradict or replace the full identifiers recorded in the main comment.
- If auth blocked alarms, metrics, logs, releases, dashboards, or other planned evidence sources, do not post a ticket comment by default. If the user explicitly asks for a blocked-investigation ticket comment, post only the compact blocked-investigation update. Include a visible investigation-blocked warning, list the missing evidence surfaces, identify the next unblock step, and avoid writing the comment as if the RCA were complete. Add `ai-triage-blocked` when supported; do not add normal triage labels, NOC ticket-id labels, transition status, or update RCA companion fields for blocked-investigation tickets.
- If the ticket already contains an inherited or copied RCA from an older incident, explicitly state whether current evidence confirms it, refines it, or contradicts it.
- Prefer short log excerpts or paraphrases plus decisive fields instead of long stack traces.
- Include direct investigation URLs whenever applicable:
  - alarm permalinks pinned to the investigated timestamp
  - Grafana dashboards or dashboard views scoped to the incident window
  - DevOps or Lumberjack log links scoped to the incident window, region, namespace, and strongest filters
  - metric pages or saved queries for the exact MQL used
  - ODO deployment or application pages for the exact deployment ids cited
- Group links by evidence type such as `Metrics`, `Logs`, `Dashboards`, and `Deployments`.
- If a source has no stable shareable URL, include the exact query, filter, or command needed to reproduce it.
- Avoid broad default log links that force the next reader to rediscover the window or filters.

End with actionable next steps instead of a generic monitoring statement.
