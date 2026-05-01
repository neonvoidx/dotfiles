# On-Call Investigation Configuration

This skill expects a TOML config that can describe one or more service teams.

## Design Goals

- One shared file can support multiple service teams.
- Tickets, code sources, observability sources, log scopes, and release scopes stay together.
- Investigation time windows and regions come from ticket plus metrics evidence, not from hard-coded defaults.

## Field Notes

### `team.tickets`

- `jira_projects`: Jira project keys that should be treated as valid incident sources for this team.
- `ots_projects`: OTS project keys that should be treated as valid incident sources for this team.
- You can set either list or both.
- If both are set for the same project key, the investigation should choose the reader from the ticket URL or identifier first, then reconcile cross-linked records only when both systems actually contain incident context.

### `team.code`

- Use one `[[team.code.repositories]]` block per codebase or component.
- Supported fields:
  - `name`
  - `role`
  - `bitbucket_repo`
  - `scm_repo`
- `local_repo_path`
- A repository block may include Bitbucket, SCM, local clone info, or any combination of them.
- Prefer stable, portable `local_repo_path` values (relative paths in repo context or environment-derived paths) so the skill can search deterministically across machines.

### `team.observability.alarm_sources`

Each alarm source should describe how the team wants Codex to find alarm-backed metric context.

Supported source patterns for the config:

- `kind = "alarm"`
  - include `alarm_id`
  - optionally include `region`
- `kind = "phonebook_project"`
  - include `phonebook`
  - include `project`

Optional fields:

- `name`
- `region`
- `notes`

### `team.observability.metric_fleets`

Use one `[[team.observability.metric_fleets]]` block per major service component or fleet.

Suggested fields:

- `name`
- `role`
- `project`
- `fleet`

Each component can point at a different telemetry project when needed. Do not force canary, worker, or host fleets to reuse the team's primary project if the runtime emits those metrics elsewhere.

### `team.canary`

Use this optional block when the service has a canary system that should be checked directly during incident triage.

Suggested fields:

- `phonebook`
- `service_project`
- `notes`

Use this block when the incident ticket includes fired canary metrics and the workflow should:

1. read the fired metric name from the ticket
2. use the corresponding `role = "canary"` entry in `team.observability.metric_fleets` as the alarm-metric context
3. use the configured `service_project` as the actual canary-service context when resolving ownership or runtime candidates
4. match the fired metric name to the runtime canary name
5. fetch the raw canary run logs for the matching run before switching to broader service logs

The canary block is only for canary-service lookup and raw run-log retrieval. Keep the corresponding `role = "canary"` entry in `team.observability.metric_fleets` as the single source of truth for the fired canary alarm metrics, including shared telemetry patterns such as `test-service` / `canary-run-results`.

### `team.observability.host_metric_fleets`

Use this when host telemetry lives in a different project or fleet from the service's application telemetry.

Suggested fields:

- `name`
- `role`
- `project`
- `fleet`

Use this for signals such as host CPU, memory, disk, heartbeat, or other infrastructure-level metrics that may help confirm a host-local incident.

### `team.observability.metric_sources`

Use this when the team has dashboards or metric pages that help Codex derive the right queries.

Supported patterns:

- `kind = "grafana_dashboard"`
  - include `dashboard_uid`, `dashboard_id`, or both
- `kind = "metric_page"`
  - include a stable `url`

Optional fields:

- `name`
- `project`
- `notes`

### `team.odo`

Use this optional block when the service is ODO-managed and incidents may require deployment correlation.

The investigation should still derive region, availability domain, time window, and any alarm-specific identifiers from the ticket and live evidence. Do not treat this config as the primary source for incident scope.

Suggested fields for `[team.odo]`:

- `phonebook`
- `notes`

Optional `[[team.odo.hints]]` blocks can be used when service discovery is ambiguous.

Suggested fields for each hint:

- `name`
- `role`
- `application_aliases`
- `application_alias_patterns`
- `tenant_names`
- `artifact_set_identifiers`
- `notes`

Use ODO hints sparingly. They are only for durable discovery anchors, not for encoding every host, backend, load balancer, or deployment detail in config.

Typical use cases:

1. the service has one or two stable ODO application aliases that should be checked first
2. updater or helper aliases do not obviously contain the service name
3. the agent needs a durable tenant or artifact-set hint to confirm that a nearby deployment belongs to this service

The investigation should be able to continue even if this block is omitted:

1. derive region, AD, and time from ticket and alarm evidence
2. inspect ODO deployments in that incident slice
3. confirm association by host, backend set, load balancer, tenant, artifact details, or deployment-step timing

### `team.lumberjack`

- Teams can configure Lumberjack in one of two ways:

1. Explicit namespace mode
   - `tenant_name`
   - `[[team.lumberjack.namespaces]]`
   - each namespace object should include:
     - `namespace`
   - recommended optional fields:
     - `name`
     - `role`
     - `compartment`

2. Discovery-hint mode
   - `phonebook`
   - `project`
   - optional `tenant_name` if the team already knows it

- Discovery-hint mode is useful when the team wants the agent to derive the right logging namespaces from the configured service identity rather than hard-code them in the team file.

The skill should derive search regions and time windows from the ticket and metric evidence instead of hard-coding them in config.

### `team.splat`

Use this optional block when the team depends on splat tracing during request-failure investigations.

Suggested fields:

- `tenant_name`
- `notes`
- `[[team.splat.namespaces]]`
  - `name`
  - `namespace`

If omitted, the skill falls back to the global splat guidance in `SKILL.md`.

### `team.shepherd`

- `phonebook`: optional team phonebook id used for related service discovery
- `project`: Shepherd project name
- `[[team.shepherd.flocks]]`: one block per flock the team wants checked during incident analysis
  - `name`
  - `flock`

If this block is omitted, the skill should skip release analysis.

## Selection Rules

- If the user names the team, use that block.
- If the user gives only a ticket id, prefer the team whose Jira or OTS project matches.
- If the user gives a local repo path, prefer the team whose repository blocks contain that `local_repo_path`.
- If more than one team matches, ask for disambiguation before reading or searching the wrong service.
