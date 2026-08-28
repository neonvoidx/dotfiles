# On-Call Investigation Configuration

This skill expects a TOML config that can describe one or more service teams.

The config file should live with the service team's docs, wrapper skill, or repo-local automation materials.

## Design Goals

- One shared file can support multiple service teams.
- Tickets, code sources, observability sources, log scopes, and release scopes stay together.
- Investigation time windows and regions come from ticket plus metrics evidence, not from hard-coded defaults.
- Prefer one shared config file with multiple `[[team]]` blocks over many one-off files.

## Recommended Shape

Use one `[[team]]` block per service team.

```toml
[[team]]
name = "Identity Control Plane"
description = "Primary on-call surface for the identity control plane"

[team.tickets]
jira_projects = ["IDCP"]
ots_projects = ["IDCP"]

[[team.faqs]]
name = "Identity login FAQ"
url = "https://confluence.example/display/IDCP/Identity+Login+FAQ"

[[team.faqs]]
name = "Auth troubleshooting guide"
url = "https://internal.example/docs/idcp-auth-troubleshooting"

[[team.code.repositories]]
name = "control-plane"
role = "control-plane"
bitbucket_repo = "https://bitbucket.example/projects/IDCP/repos/control-plane"
scm_repo = "ocid1.devopsrepository.oc1..exampleuniqueID"
local_repo_path = "/Users/example/work/control-plane"

[[team.observability.alarm_sources]]
name = "5xx alarm scope"
kind = "phonebook_project"
phonebook = "idcp"
project = "IdentityControlPlane"

[[team.observability.metric_fleets]]
name = "control-plane-api"
role = "control-plane"
project = "IdentityControlPlane"
fleet = "idcp-control-plane-api"

[[team.observability.metric_fleets]]
name = "synthetic-canary"
role = "canary"
project = "test-service"
fleet = "canary-run-results"

[team.canary]
phonebook = "idcp"
service_project = "spm-receiver"

[[team.observability.host_metric_fleets]]
name = "overlay-hosts"
role = "host"
project = "hostmetrics"
fleet = "idcp.overlay"

[[team.observability.metric_sources]]
kind = "grafana_dashboard"
name = "Control plane dashboard"
dashboard_uid = "RTpwIkbNz"
dashboard_id = 12345

[team.odo]
phonebook = "idcp"
notes = "Use ODO correlation for backend-capacity and host-local incidents"

[[team.odo.hints]]
name = "control-plane"
role = "control-plane"
application_aliases = ["idcp-control-plane", "idcp-control-plane-system-updater"]
application_alias_patterns = ["poes-updater-*"]

[team.sqlcl]
connection_name = "Idcp-phx-sqlcl"
# Optional bootstrap fields for teams that want Codex bootstrap to create or
# refresh the saved SQLcl alias:
# connect_string = "//localhost:10803/s_idcp_control_plane.r2"
# username = "idcpRO[Readonlyuser]"
# password_env_var = "IDCP_SQLCL_PASSWORD"
# password_env_file = "~/.env"
# tunnel_command = "ssh -L 10803:service-host:1521 bastion.example.com"

[team.lumberjack]
tenant_name = "idcp"

[[team.lumberjack.namespaces]]
compartment = "ocid1.compartment.oc1..exampleuniqueID"
namespace = "idcp/service"

[[team.lumberjack.namespaces]]
compartment = "ocid1.compartment.oc1..exampleuniqueID"
namespace = "idcp/audit"

[team.splat]
tenant_name = "splat"

[[team.splat.namespaces]]
name = "splat-proxy"
namespace = "splat-proxy-overlay"

[team.shepherd]
phonebook = "idcp"
project = "identity-control-plane"

[[team.shepherd.flocks]]
name = "prod-main"
flock = "prod-main"

[[team.shepherd.flocks]]
name = "prod-canary"
flock = "prod-canary"
```

## Field Notes

### `team.tickets`

- `jira_projects`: Jira project keys that should be treated as valid incident sources for this team.
- `ots_projects`: OTS project keys that should be treated as valid incident sources for this team.
- You can set either list or both.
- If both are set for the same project key, use the canonical ticket relationship for source-of-truth precedence:
  - if the ticket includes a `Master OTS` reference or OTS ticket id/link, OTS is source of truth
  - otherwise, Jira is source of truth, regardless of cut type
- If OTS is selected as source of truth and cannot be read, stop and request auth/session fix; do not fall back to Jira for authoritative fields.
- After complete final writeback, the live ticket project key reconciled against these lists is also used for the project-scoped label `ai-triaged-by-<ticket-project-key>`, such as `ai-triaged-by-AC`, `ai-triaged-by-AAT`, or `ai-triaged-by-ORGMGMT`.

### `team.faqs`

- Use one `[[team.faqs]]` entry per FAQ or documentation URL the team wants triage to consult.
- Required fields per entry:
  - `name`
  - `url`
- During triage, this block is best-effort:
  - for `human-cut` tickets, the workflow may read all configured FAQ URLs
  - if FAQ/docs clearly answer the ticket question, the workflow prepares a `Reference FAQs (Non-RCA)` draft and posts it only with explicit user authorization or in a clearly approved unattended automation mode
  - if URLs are inaccessible or irrelevant, the workflow continues without failing
- This block is optional. If omitted, FAQ/doc answer checks are skipped.
- Existing `team.runbooks` usage remains unchanged; `team.faqs` is additive.

### `team.code`

- Use one `[[team.code.repositories]]` block per codebase or component.
- Supported fields:
  - `name`
  - `role`
  - `bitbucket_repo`
  - `scm_repo`
  - `local_repo_path`
- A repository block may include Bitbucket, SCM, local clone info, or any combination of them.
- Prefer absolute `local_repo_path` values so the skill can search deterministically.

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
- `canary_names`
- `notes`

Use this block when the incident ticket includes fired canary metrics and the workflow should:

1. read the fired metric name from the ticket
2. use the corresponding `role = "canary"` entry in `team.observability.metric_fleets` as the alarm-metric context
3. use the configured `service_project` as the actual canary-service context when resolving ownership or runtime candidates
4. if `canary_names` is configured, narrow the candidate runtime canaries to that explicit list before broader discovery
5. match the fired metric name to the runtime canary name
6. fetch the raw canary run logs for the matching run before switching to broader service logs

The canary block is only for canary-service lookup and raw run-log retrieval. Keep the corresponding `role = "canary"` entry in `team.observability.metric_fleets` as the single source of truth for the fired canary alarm metrics, including shared telemetry patterns such as `test-service` / `canary-run-results`.

- `service_project` is the canary-service context, not the runtime canary name.
- `canary_names`, when present, should list the known runtime canary names that the fired metric is expected to map to.

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

### `team.object_store`

Use this optional block when the service repeatedly needs Object Storage lookups during investigations or follow-up validation.

Suggested fields:

- `default_compartment_name`
- `default_tenancy_name`
- optional `tenancy_names_by_realm`
- optional `notes`

Keep only durable storage defaults here, such as the default tenancy or compartment and any stable realm-specific tenancy overrides. Do not encode one-off object names, temporary prefixes, or incident-specific timestamps in config.

### `team.sqlcl`

Use this optional block when the service repeatedly needs SQLcl-backed database lookups and the team wants to document a stable local SQLcl alias. Add the bootstrap fields only when the team also wants Codex bootstrap to create or refresh that saved connection for the engineer.

Suggested fields:

- `connection_name`
- optional `connect_string`
- optional `username`
- optional `password_env_var`
- optional `password_env_file`
- optional `tunnel_command`
- optional `notes`

Guidance:

- `connection_name` names the saved SQLcl alias engineers should use locally.
- Define only `connection_name` when the team already has a standard saved alias and bootstrap does not need to create it.
- Define `connect_string`, `username`, and `password_env_var` together when bootstrap should create or refresh the saved alias named by `connection_name`.
- Keep only durable connection metadata here. Do not commit the password.
- `password_env_var` should name the local environment variable that holds the password, for example `ACCOUNTS_SQLCL_PASSWORD`.
- `password_env_file`, when present, should point to a local dotenv or shell-export file such as `~/.env`. If omitted, bootstrap should fall back to `~/.env`.
- Relative `password_env_file` paths should be resolved from the team-config file location so repo-local wrappers can keep a colocated helper file when needed.
- `tunnel_command` is a human/operator hint for making the local listener reachable. Use it for the actual SSH port-forward or wrapper command engineers should run locally before connecting. Treat it as documentation or a local-helper seed, not as secret material.
- The saved connection is local machine state. Team config should describe how to create it, not replace the engineer's responsibility for keeping the local tunnel or listener alive.

### `team.lumberjack`

- Teams can configure Lumberjack in one of two ways:

1. Explicit namespace mode
   - `tenant_name`
   - optional `tenant_names_by_environment`
   - `[[team.lumberjack.namespaces]]`
   - each namespace object should include:
     - `namespace`
   - recommended optional fields:
     - `name`
     - `role`
     - `compartment`
     - `environment`
     - `region`
     - `log_group`

2. Discovery-hint mode
   - `phonebook`
   - `project`
   - optional `tenant_name` if the team already knows it

- Discovery-hint mode is useful when the team wants the agent to derive the right logging namespaces from the configured service identity rather than hard-code them in the team file.
- `tenant_name` should represent the default or primary production tenant when one exists.
- `tenant_names_by_environment`, when present, should map environment labels such as `prod`, `preprod`, or `pintlab2` to the known Lumberjack tenant names for that environment.
- Use `[[team.lumberjack.namespaces]]` to keep every durable namespace family the service uses, including multiple families inside the same region when different environments emit to different namespaces.
- If one physical namespace contains multiple durable log streams such as API and worker logs, keep separate `[[team.lumberjack.namespaces]]` blocks with the same `namespace` value and distinct `name`, `role`, and `log_group` values so the investigation can apply the correct log-group filter without guessing.
- When the same region has multiple namespace families, annotate each namespace block with `environment` and, when useful, `region` so the investigation can filter to the right candidates before searching.
- In `team.lumberjack.namespaces.region`, store the logging backend's expected region key for that namespace family. This may be an internal key such as `r1` rather than the public region name such as `us-seattle-1`.
- In `team.lumberjack.namespaces.log_group`, store the durable Lumberjack `logGroup` value that identifies the intended stream inside that namespace, such as `api_application_log` or `worker_application_log`.
- For alarm-backed investigations, the agent should derive the environment label from alarm evidence first, especially:
  - fleet name
  - alarm display name
  - alarm compartment
- After deriving the environment label, the agent should prefer `tenant_names_by_environment[environment]` over the default `tenant_name`, then verify that the resolved logging namespace or compartment matches the alarm-backed service scope before searching logs.
- If multiple namespace blocks match the same role, prefer the ones whose `environment`, `region`, and `log_group` fields match the incident first, then fall back to broader namespace discovery only when those scoped candidates do not validate.
- Include `dev` mappings when the service emits dev alarm fleets under a different Lumberjack tenant than production.

The skill should derive search regions and time windows from the ticket and metric evidence instead of hard-coding them in config. Keep NOC and deployment correlation-window rules in `workflow.md`. When the metric/alarm region and the logging backend region key differ, use the metric/alarm evidence to identify the incident scope, then normalize to the namespace family's configured logging `region` value before issuing Lumberjack searches.

### `team.splat`

Use this optional block when the team depends on splat tracing during request-failure investigations.

For teams that regularly trace through splat, include explicit splat tenant and namespace hints in the service-team config so request tracing does not stall on environment-specific defaults.

Suggested fields:

- `tenant_name`
- `tenant_names_by_environment`
- `notes`
- `[[team.splat.namespaces]]`
  - `name`
  - `namespace`
  - optional `environment`
  - optional `region`
- `[[team.splat.service_operations]]`
  - `name`
  - exact `service_operation_id` or wildcard `service_operation_pattern`
  - optional `downstream_target`
  - optional `notes`

Recommended usage:

- Use `tenant_names_by_environment` when splat tenant resolution differs across prod, preprod, dev, or lab environments.
- Annotate `team.splat.namespaces` with `environment` and `region` when the same team traces through different proxy families or region-specific namespaces.
- Register durable `service_operations` when the same `#ServiceOperationId` values recur often enough that rediscovering them during each incident wastes time.
- Prefer a stable service-facing `name` plus the exact `service_operation_id` seen in logs when one operation is the useful routing unit.
- Use `service_operation_pattern` for stable SPLAT-owned families such as `accounts.*` when the team owns a prefix rather than one exact operation id.
- If the first SPLAT mining pass usually starts from a service-family wildcard such as `WHERE "#ServiceOperationId" = '*submapping*'`, register that stable family with `service_operation_pattern` so the search hint is explicit in config instead of rediscovered during each incident.
- Prefer exact `service_operation_id` over `service_operation_pattern` when both are practical, and use patterns mainly for readable grouping and fast downstream pivots.
- If `downstream_target` is known, include it so the investigation can pivot faster from proxy evidence into the correct downstream service logs, dashboards, or repository.

If omitted, the investigation should fall back to the default splat guidance in `logging.md`.

### `team.shepherd`

- `phonebook`: optional team phonebook id used for related service discovery
- `project`: default Shepherd project name for the team's flocks
- `[[team.shepherd.flocks]]`: one block per flock the team wants checked during incident analysis
  - `name`
  - `flock`
  - optional `project`: per-flock Shepherd project override when one service spans multiple Shepherd projects

If a flock omits `project`, inherit `team.shepherd.project`. Use the flock-level override only when a minority of flocks live under a different Shepherd project than the team's default.

If this block is omitted, the skill should skip release analysis.

## Multi-Team Example

```toml
[[team]]
name = "Accounts"
[team.tickets]
jira_projects = ["ACT"]
ots_projects = ["ACT"]
[[team.code.repositories]]
name = "accounts-service"
local_repo_path = "/Users/example/work/accounts-service"

[[team]]
name = "Billing"
[team.tickets]
jira_projects = ["BILL"]
[[team.code.repositories]]
name = "billing-service"
local_repo_path = "/Users/example/work/billing-service"
```

## Selection Rules

- If the user names the team, use that block.
- If the user gives only a ticket id, prefer the team whose Jira or OTS project matches.
- If the user gives a local repo path, prefer the team whose repository blocks contain that `local_repo_path`.
- If more than one team matches, ask for disambiguation before reading or searching the wrong service.
