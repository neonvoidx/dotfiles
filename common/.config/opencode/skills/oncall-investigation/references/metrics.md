# Metrics and Scope Guidance

Use this file when the incident is alarm-backed, metric-backed, region-ambiguous, or time-window-ambiguous.

## Time-window guidance

- Start with the earliest credible incident signal from the ticket.
- Extend backward to catch possible triggers such as alarm onset or deploys.
- Extend forward through mitigation, recovery, or current impact.
- If the incident is alarm-backed, do not treat the alarm event's open time as the earliest possible bad request.
- Expand the first runtime search window earlier than the alarm event window by at least:
  - the alarm query lookback window
  - plus the alarm `pendingDuration`
- Use the alarm event open and close timestamps as the operator-visible firing window, but use the expanded window for the first metric replay and first source-aligned log search when hunting contributing requests.

## Region guidance

- Start with ticket-supplied runtime evidence such as an alarm URL, alarm id, fired metric name, or alarm-linked timestamps.
- Do not start region resolution from stored ticket fields such as `affectedRegion` when alarm or metric evidence is available.
- Treat ticket actor metadata as non-evidence for runtime region. Ignore actor-scoped fields such as `reporter.displayName`, `reporter.region`, `reporter.realm`, `lastModifiedBy.region`, and orchestration or notification author regions when determining the impacted service region.
- For alarm-backed incidents, resolve region from the alarm Evaluation output first.
- Prefer the region where the alarm query reproduces and where matching runtime evidence exists.
- When an alarm is present, treat the region shown in the alarm Evaluation output as the primary source of truth unless stronger runtime evidence later proves the failure is elsewhere.
- If a system-generated ticket points at one region but the fired metric and canary or service logs reproduce in another, investigate the reproduced region first and call out the metadata inconsistency in the conclusion.

## Availability-domain guidance

- Resolve AD from alarm or metric evidence using the same precedence discipline as region.
- If the alarm evaluation, fired metric dimensions, or direct metric query identifies a specific AD, use that AD as the default investigation AD.
- If the alarm or metric evidence does not identify a specific AD, do not guess one from ticket metadata or later runtime assumptions before the first log search.
- In that case, start with all ADs for the first log or deployment search, then narrow to a specific AD only after matching runtime evidence proves the failure is localized.

## Reconciling conflicting region signals

- Use this evidence order when region signals conflict:
  - alarm Evaluation region
  - fired metric location
  - direct metric query results
  - matching runtime logs
  - non-runtime ticket metadata
- Exclude `reporter`, `lastModifiedBy`, comment author regions, orchestration actor regions, and similar ticketing-system actor fields from the precedence order entirely because they may reflect where Jira-SD, OTS, Ocean, or ticket orchestration is running rather than where the service failed.
- Do not use stored ticket fields such as `affectedRegion` to resolve the incident region. When those fields disagree with the alarm Evaluation region, direct metric evidence, or matching runtime logs, ignore the ticket field and continue with runtime evidence.
- If ticket metadata conflicts with direct metric or log evidence, carry the mismatch forward explicitly and scope the investigation to the region where the signal is reproducible.

## Alarm-first metrics workflow

- If the ticket includes an alarm URL or alarm id, load the alarm definition before broad metric or log searches.
- Treat the alarm definition as the authoritative source for:
  - evaluated region
  - metric query
  - project
  - fleet
  - alarm compartment
  - pending duration
- Preserve the exact region from the alarm Evaluation output and use it as the default investigation region unless later metric or log evidence proves the incident reproduces elsewhere.
- Use configured alarms, dashboards, or service metric pages to identify:
  - relevant metric names
  - alarm query context
  - fleet or project names
  - panels or annotations that narrow the time window
- Query the metrics that correspond to the configured alarms or dashboards before broad log searches.
- Preserve which system emitted the metric because that decides the first log hop:
  - if the metric is emitted by splat or splat proxy logs, start with splat
  - if the metric is emitted by the downstream service itself, start with the downstream logs first and use the canonical request-id mining order from `logging.md`, then use splat afterward for end-to-end request-path confirmation
- When the alarm or dashboard is status-family based, preserve the status-code family from the metric so the first aligned log pass can use the matching `#statusCode` range when that field is available:
  - `2xx` -> `>= 200` and `< 300`
  - `4xx` -> `>= 400` and `< 500`
  - `5xx` -> `>= 500` and `< 600`
- Use the metric-derived status family only as the first narrowing filter in the system that owns that signal:
  - for splat-emitted status-family metrics, mine candidate request ids from splat first and then use `#Upstream.ResponseStatus` and `#Downstream.ResponseStatus` to determine whether the failure surfaced in splat or after downstream routing
  - for downstream-emitted service metrics, recover candidate requests using the canonical mining order in `logging.md`, then pivot back to splat for end-to-end confirmation
- Preserve any metric dimensions that can narrow the first aligned log search, especially routed operation, path, tenancy, fleet, and AD.
  - Use those dimensions with the status-family filter in splat when the metric is splat-backed and the ticket does not already include a request id.
  - Use those dimensions in the downstream request-id mining flow described in `logging.md` when the metric is emitted by the service itself, then carry the recovered request or workflow identifiers back into splat for E2E analysis.
- If the team config includes both service metric fleets and host metric fleets, check both when the incident could be host-local.
- Do not assume app and host telemetry share the same project or fleet name.

## Alarm-derived identifiers to preserve

For backend-availability, Flamingo, heartbeat, or single-AD capacity incidents, capture any alarm-derived identifiers that can drive deployment correlation, such as:
- region
- availability domain
- load balancer id
- backend set name
- host name

## Relationship to other references

- After metrics narrow the scope, use `logging.md` for runtime log searches.
- If the alarm points at canary-backed impact and the team config includes `team.canary`, use `canary.md`.
