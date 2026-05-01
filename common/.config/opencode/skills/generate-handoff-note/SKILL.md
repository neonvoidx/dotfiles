---
name: generate-handoff-note
description: '[Workflow] Create a concise handoff note for the next oncall using jira tickets'
source_type: workflow
metadata:
    last_updated: 2026-03-10T00:00:00Z
    owner: ocm
---

## Harness targets

Harness-neutral. Use in any chat-based harness (OpenCode/Codex/Cline/etc.). If your harness supports Jira tools, you may use them for **read-only** ticket discovery.

## Tool routing

OCMSD and OCB tickets live on Jira Service Desk, not the main Jira instance. Alarm tickets are transitioning to OTS — each Jira-SD alarm ticket has a corresponding OTS ticket.

- Use `atlassian-sd_jira_get_project_issues` and `atlassian-sd_jira_get_issue` for ticket discovery and detail.
- Do NOT use `atlassian_jira_search` or `atlassian_jira_get_issue` — wrong Jira instance, returns empty results for OCMSD/OCB.
- Use `dope_get_regions` to resolve full region names.
- When OTS MCP is available and alarm tickets need write operations (comments, status updates), use `ots_get_ots_ticket` and `ots_add_ots_ticket_comment` — Jira-SD is read-only for alarm tickets.

## Inputs

- **Shift window**: start/end timestamps or “last N hours”. Default: **last 12 hours**.
- **Ticket source**: Jira project(s). Default: **OCMSD + OCB** via `atlassian-sd`.
- **Scope hints (optional)**: region(s), service/component, severity/priority, notable incidents.
- **Ticket limit (optional)**: maximum tickets to include. Default: **10**.
- **Enrichments (optional)**: `timestamps`, `group`, `engineers` — all **on by default**. User may disable.

If the user does not specify inputs, use the defaults and proceed. Only ask for clarification if the request conflicts with defaults or is ambiguous.

## Defaults

- Group: **requires action** first, **closed** last.
- Include event timestamps per ticket.
- Include engineer-to-ticket summary at the top.
- Ticket links use the base: `https://jira-sd.mc1.oracleiaas.com`.
- Keep each ticket summary concise (single screen when possible).

## Output shape

Produce a single plain-text handoff note:

```text
Engineers involved
- <name>: <ticket-1>, <ticket-2>
- Unassigned: <ticket-3>

Requires action

Ticket: <Jira link>
Region: <full region name>
Event timestamp:
- <alarm transition time>; ticket created <creation time>
Root Cause:
- <1-liner>
Action taken:
- <what you did>
Further actions:
- <pending action items>

Closed

Ticket: <Jira link>
...
```

Omit sections the user has disabled (engineer summary, group headers, event timestamps).

## Mutation

No mutation by default (read-only ticket lookup + note generation).

If you propose any mutation (commenting on tickets, transitioning status, assigning, editing fields), stop and ask for explicit confirmation listing:
- exact ticket(s)
- exact action(s)
- the text you will post (if any)

## Preflight

Verify MCP access for each tool surface used in this workflow. Make one read-only call per surface. If any auth check fails, stop and report before proceeding.

## Steps

1. Apply defaults for any inputs the user did not specify. Do not ask clarifying questions unless the request is ambiguous.
2. Query tickets using `atlassian-sd_jira_get_project_issues` for each project (OCMSD, OCB).
   - If the combined result exceeds the ticket limit, keep the most recent by creation time.
3. For each ticket, call `atlassian-sd_jira_get_issue` to extract:
   - region (full name — use `dope_get_regions` to resolve if needed)
   - event/alarm timestamp and ticket creation time
   - root cause (one line; “unknown” if not yet determined)
   - action taken (what was done during the shift)
   - further actions (clear next steps + owners if known)
   - assignee
4. Assemble the handoff note using the **Output shape**.
5. Group: **requires action** first, **closed** last.
6. Ask the user: “Any additional context to include (e.g., links to dashboards, incidents, or a short narrative of the shift)?”

## Verify

- The document includes the sections: **Inputs**, **Defaults**, **Output shape**, and **Verify**.
- Every ticket block includes: Ticket, Region, Event timestamp, Root Cause, Action taken, Further actions.
- Ticket links use `https://jira-sd.mc1.oracleiaas.com`.
- Requires-action tickets appear before closed tickets.
- Root Cause is a single line (or explicitly “unknown”).
- Further actions are actionable (next step phrased as a verb).

## Done when

- A single handoff note is produced in the **Output shape** and sorted per **Defaults**.
- The user confirms whether additional context is needed (and it is incorporated if provided).
