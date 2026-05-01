---
name: oncall-investigation
description: Use when running production incident triage for an on-call service and you need a repeatable, config-driven workflow that correlates ticket evidence, metrics, logs, releases, and code before writing back findings.
metadata:
  owner: ocm
  last_updated: 2026-03-23
---

# On-Call Investigation

## Overview

Use this skill for incident triage and on-call investigation when the service team has already defined where Codex should read tickets, inspect alarms or dashboards, search logs, check releases, and read code.

The skill is intentionally config-driven. A team can define one or more service entries in a shared TOML file and point Codex at the relevant entry during an investigation.

Use `assets/service-team-config.template.toml` as the starting point, keep real team configs in your team repo or docs location, and read `references/configuration.md` when you need the full field map.

## Fast Path

1. Load the service-team config and select the correct `[[team]]` block.
2. Read the incident ticket first and classify it as either:
   - `investigation required`
   - `informational / data-only`
   Use these defaults:
   - `investigation required` when there is active or recent customer impact, alarms, canary failures, repeated errors, failed workflows, unclear root cause, or an explicit request to determine cause or remediation
   - `informational / data-only` when the user only wants data lookup, status reporting, or historical context and there is no request to determine cause or remediation
3. For `informational / data-only` tickets:
   - gather only the requested facts
   - avoid broad code, log, or release exploration
   - return a concise answer
4. For `investigation required` tickets:
   - derive the initial time window and region set from the ticket
   - capture strong identifiers such as request ids, workflow ids, tenants, alarms, metric names, or regions
   - gather metrics, logs, and deployment evidence in parallel when possible
   - search code only after the first evidence pass
   - challenge the current explanation before finalizing it
   - write the investigation back to the ticket
   - record durable memory if the investigation produced a reusable lesson

Default investigation order:
1. ticket
2. metrics and logs
3. deployments and releases
4. code
5. conclusion review
6. ticket writeback

If the ticket is canary-backed, insert the canary flow before broad log hunting.

## Workflow

### 1. Load and validate the team config

- The config may define one or many `migration.toml` blocks.
- If the user names a team, use that exact block.
- If the user gives only a ticket id or repo path, infer the team from matching ticket projects, repo settings, or local paths.
- If more than one team matches, stop and disambiguate before querying the wrong service.
- Review the configured sources before investigating:
  - ticket projects
  - remote repositories
  - local repo paths
  - alarm or metric sources
  - canary service config
  - optional ODO hints
  - Lumberjack tenant and namespaces
  - Shepherd project and flocks

### 2. Read the ticket and set scope

- Use the configured ticket sources as the primary incident entry point.
- If the config includes `ots_projects`, use OTS-capable tooling for OTS reads.
- If the config includes `jira_projects`, use Jira-capable tooling for Jira reads.
- Choose the ticket reader from the strongest source signal first:
  - if the user gives a Jira URL or Jira browse link, read it as Jira
  - if the user gives an OTS URL, ticket OCID, or OTS-specific resource path, read it as OTS
  - if the user explicitly says the ticket is from Jira or OTS, trust that unless the identifier clearly contradicts it
- When both Jira and OTS are configured for the same project key and the source is still ambiguous, check both systems only long enough to determine which one actually contains the incident ticket, then continue from that source.
- When both Jira and OTS contain related incident records, reconcile timestamps, severity, impact, and linked ticket ids before moving on.
- Treat existing human comments as unverified context until you confirm them independently.
- Gather:
  - ticket id
  - severity
  - summary
  - created time
  - impacted region hints
  - tenant or customer hints
  - mitigation notes
  - linked tickets or related incidents
- If the ticket contains system-generated canary failures, also capture:
  - failing canary name
  - fired metric name
  - failure timestamps
  - endpoint or operation
  - request ids such as `opc-request-id`
  - returned status or error text
- Derive an initial plan that includes:
  - incident scope
  - initial time window
  - initial region set
  - first evidence sources to query
  - the leading hypotheses worth testing

### 3. Collect evidence

- Collect evidence according to the current plan rather than exploring every source at once.
- Start with the highest-signal sources for the current hypothesis.
- Expand only when the current evidence is insufficient or contradictory.

Time window guidance:
- Start with the earliest credible incident signal from the ticket.
- Extend backward to catch possible triggers such as alarm onset or deploys.
- Extend forward through mitigation, recovery, or current impact.

Region guidance:
- Start with ticket evidence.
- Refine with alarm regions, metric anomalies, and log hits.

Metrics guidance:
- Use configured alarms, dashboards, or service metric pages to identify:
  - relevant metric names
  - alarm query context
  - fleet or project names
  - panels or annotations that narrow the time window
- Query the metrics that correspond to the configured alarms or dashboards before broad log searches.
- If the team config includes both service metric fleets and host metric fleets, check both when the incident could be host-local.
- Do not assume app and host telemetry share the same project or fleet name.
- For backend-availability, Flamingo, heartbeat, or single-AD capacity incidents, capture any alarm-derived identifiers that can drive deployment correlation, such as:
  - region
  - availability domain
  - load balancer id
  - backend set name
  - host name

### 4. Canary flow

- Use this flow when the ticket is canary-backed and the team config includes `team.canary`.
- Start from the fired metric, not from a guessed canary name.
- Treat the ticket's fired metric as the authoritative clue for which canary actually failed.
- Use the configured `role = "canary"` metric fleet to confirm which failure series fired.
- Use `service_project`, `phonebook`, incident region, and time window to resolve the real runtime canary.
- Fetch the raw canary run logs before broader Lumberjack searching.
- Extract request ids, workflow ids, endpoint names, downstream status codes, and explicit exception text from the raw canary log first.

Preferred canary-backed investigation order:
1. ticket
2. canary logs
3. splat logs
4. downstream application logs
5. metrics
6. releases
7. code

If the fired metric does not map cleanly to a canary name, keep that as an open issue and state which candidate canaries were considered.

### 5. Search Lumberjack and DevOps logs

- Use the configured Lumberjack scope as the starting point.
- Teams may configure either:
  - explicit `tenant_name` plus namespace list
  - discovery hints such as `phonebook` plus `project`
- If a `phonebook` is configured, fetch candidate compartments for the incident region before guessing manually.
- Derive the log time range and region set from the incident, unless the user explicitly asks for a fixed range.
- Start with the narrowest useful time slice and region that can test the current hypothesis.
- When strong identifiers already exist, prefer fielded filters over broad message or path matching.
- If a concrete request id or workflow id is known, use it as the primary correlation key before broadening into endpoint-path, message-text, or time-window-only searches.

Common high-signal fields:
- `#opc-request-id`
- `#logger`
- `logGroup`
- `#wfInstanceId`
- `#wfDef`

Namespace-discovery rules:
- Treat configured namespaces as starting hints, not guaranteed runtime truth.
- Before concluding that a service has no logs, validate the exact searchable tuple:
  - region
  - compartment
  - namespace
  - log type
- Recommended matching order:
  1. use `phonebook` and region to fetch claimed compartments
  2. try the configured namespace against those candidate compartments
  3. if the namespace is still ambiguous or empty, use tenant-based namespace discovery to find the runtime namespace and returned compartment
- If a configured namespace returns no hits, check whether the namespace is valid only under a different claimed compartment or whether the service uses a region- or tenant-specific runtime namespace.

Splat guidance:
- If request tracing suggests an edge or routing issue, check splat before concluding the request never reached the target service.
- If the team config includes an explicit splat block, prefer its tenant and namespace hints over global defaults.
- For splat log searches, expect `splat-proxy` or `splat-proxy-overlay`.
- In `R1` / `REGION1`, splat Lumberjack searches should use tenant `mpapi`.
- In other realms, splat Lumberjack searches typically use tenant `splat`.
- When tracing through splat, prefer searching by the request-id middle segment with `#opc-request-id='*<middle-segment>*'` before adding URI/path text.
- Use splat to answer:
  - did the request arrive at proxy?
  - which downstream operation was selected?
  - did splat receive a downstream response, and what status came back?
- If splat shows downstream invocation and repeated downstream `500` responses, move immediately to the downstream application's logs with the same request id.

### 6. Check ODO, releases, and code

ODO guidance:
- Use ODO correlation when the symptom looks host-local or capacity-local, for example:
  - backend count drops
  - Flamingo alarms
  - heartbeat deficits
  - single-AD serving loss
  - drain/start/bounce windows on a small number of hosts
- Derive region, AD, and incident window from the ticket and alarm evidence first. Do not require those values to be hard-coded in config.
- Start with the smallest plausible ODO search surface:
  - incident AD
  - incident window
  - any known deployment id or application alias from the ticket
- Do not rule ODO in or out by alias matching alone. Some updater or helper applications may not include the service name in their alias.
- If the team config includes `team.odo`, treat it as optional discovery help rather than the source of truth.
- Confirm service association using the strongest available runtime evidence, such as:
  - affected host or node name
  - backend set name
  - load balancer id
  - tenant name
  - artifact set or artifact type
  - deployment step timing such as `REMOVE_FROM_SERVICE`, `START`, `VALIDATE`, and `ADD_BACK_TO_SERVICE`
- If the available ODO tools do not provide a single direct host-to-all-applications lookup, use AD-scoped deployment inventory plus detailed deployment inspection to reconstruct the host and backend relationship before concluding.

Release guidance:
- If the team config includes Shepherd flocks, inspect releases or execution targets in the incident window.
- Look for:
  - roll-forwards
  - rollbacks
  - partial failures
  - region-specific execution issues
  - timing overlap with the first bad metric or log signal
- Compare release start and completion times against the first confirmed failure.
- Do not assume a nearby deploy or bounce is the trigger; it may be mitigation or recovery.
- If no Shepherd config exists, skip release analysis instead of guessing.

Code guidance:
- Prefer configured local repo paths for:
  - symbol search
  - config lookup
  - deployment spec analysis
  - log or metric name tracing
- Use configured Bitbucket repos or SCM repos when:
  - no local clone is available
  - ownership or repository identity needs confirmation
  - the investigation spans multiple services and not all repos are cloned locally
- Keep code conclusions grounded in the evidence already gathered from tickets, metrics, logs, and releases.

### 7. Review and challenge the conclusion

- Before finalizing the investigation, actively challenge the current explanation.
- Ask:
  - what facts are confirmed versus inferred?
  - does any evidence contradict the current hypothesis?
  - did the failure start before or after the suspected trigger?
  - could the observed recovery action be mitigation rather than root cause?
  - is there a simpler explanation at proxy, downstream, host, release, or code level that still fits the timeline better?
- Do not treat the first plausible root cause as final until it survives this review.
- If uncertainty remains, label the conclusion as a hypothesis and state the next best validating step.

### 8. Synthesize the investigation

- Before writing back, assemble the investigation into a concise, decision-ready summary.
- Build a short timeline that includes:
  - incident start
  - first alarm or metric anomaly
  - first corroborating logs
  - overlapping deploy or rollback events
- Include a current-status snapshot when known:
  - affected host, shard, store, or region slice
  - whether the failure is still recurring
  - whether recovery appears tied to restart, bounce, rebuild, rollback, or natural recovery
- Separate clearly:
  - confirmed facts
  - strong hypotheses
  - missing evidence
- End the synthesis with the next best validating step.

### 9. Write back to the ticket

- Apply the mutation gate before any ticket writeback:
  - Label: `MUTATION`
  - Target: the exact incident ticket id and system (Jira or OTS)
  - Action: add one investigation comment
  - Expected outcome: durable, evidence-based comment linked to this investigation
  - Rollback: add a corrective follow-up comment if the content is incorrect
  - Wait for explicit `yes` before posting
- For investigation-required tickets, prepare the writeback by default unless the user explicitly asks not to.
- Every ticket comment written by this skill must begin with the prefix `[codex-gpt-5.4]` on the first line.
- Treat the ticket comment as a durable investigation artifact, not a quick note.
- Use markdown with explicit headers.

Required sections:
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

The ticket comment should capture:
- scope and approach
- investigation order
- key evidence streams checked
- exact incident identifiers when available, such as region, AD, tenant, account, workflow id, request id, work request id, alarm id, metric name, deployment id, application alias, host name, backend set, and load balancer id
- confirmed findings
- important metrics, counts, timestamps, or retry limits
- what failed first versus what happened later as a consequence
- current status, including whether cleanup, retry, requeue, bounce, or rollback happened
- related incidents and whether the current incident is the same underlying chain or only a similar symptom
- best conclusion
- recommended follow-up
- explicit owner split when relevant

Evidence rules:
- Keep the writeback evidence-based.
- Distinguish clearly between confirmed facts and hypotheses.
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

### 10. Record durable memory if applicable

- After the investigation, decide whether any learning is durable enough to record.
- Follow the global memory protocol in `AGENTS.md`:
  - `Critical` for cross-project or Codex-wide reusable guidance
  - `Normal` for project- or domain-specific durable guidance
  - `Low` for transient run notes that should not be recorded
- Record memory only when the investigation produced a reusable lesson, stable workflow correction, durable service quirk, or high-cost failure pattern.
- Do not store transient timestamps, ticket ids, one-off counts, or secrets as memory.

## Config Guidance

- The config file should live with the service team's docs, wrapper skill, or repo-local automation materials.
- Prefer one shared config file with multiple `migration.toml` blocks over many one-off files.
- Keep identifiers explicit:
  - Jira project keys
  - OTS project keys
  - named code repositories with remote identifiers and local repo paths
  - alarm ids, dashboard ids, or dashboard URLs
  - named service metric fleets
  - optional canary lookup blocks with phonebook plus service-project fields
  - named host metric fleets when they differ from service telemetry
  - optional ODO hints when alias-based discovery is ambiguous
  - Lumberjack namespace objects
  - optional splat tenant and namespace hints
  - Shepherd project and named flock scopes

## Notes

- This skill is primarily investigative and read-only.
- Use `references/configuration.md` for the recommended config structure.
- Use `assets/service-team-config.template.toml` as the bootstrap template for new teams.
- If the investigation needs PR review context for a suspected code change, pair this skill with an available PR review skill or direct repository tooling.
- For teams that depend on splat tracing, include splat Lumberjack tenant and namespace hints explicitly in the service-team config so request tracing does not stall on environment-specific defaults.
- If a tool reports that it "could not get operator token," do not assume `OP_TOKEN` is missing from `~/.env`.
- Distinguish between:
  - env-backed workflows that read an existing `OP_TOKEN`
  - tool paths that try to mint or refresh a token through SSH/operator-token helpers
- When the local environment already has a valid `OP_TOKEN`, prefer env-backed REST calls or env-backed clients before concluding there is an auth gap.
