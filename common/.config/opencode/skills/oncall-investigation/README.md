# On-Call Investigation

## Skill Overview

`On-Call Investigation` is a config-driven Codex skill for incident triage and RCA work. It helps Codex investigate non-`CHANGE` operational tickets by correlating ticket context, FAQ or doc links, metrics, canary signals, Lumberjack or splat logs, Shepherd releases, ODO activity, and local code.

The skill is designed for service teams that want a repeatable investigation workflow instead of ad hoc troubleshooting. Teams describe their incident surfaces in a TOML config, and the skill uses that config to decide where to read, what to validate first, and which evidence sources to query.

Brownbag recording: [AI on-call investigation skills](https://otube.oracle.com/media/AI+on-call+investigation+skills/1_vl3mlemg).

## How The Skill Works

At a high level, the skill follows this flow:

1. Load the team config and select the right `[[team]]` block.
2. Validate auth before querying tickets, OCI-backed tools, logging, or DevOps surfaces.
3. Read the incident ticket first and classify:
   - ticket intent: `investigation required` or `informational / data-only`
   - cut type: `human-cut`, `automation-cut`, or `unknown`
4. Resolve the authoritative ticket source from live incident metadata and related links, including Jira-to-OTS pivots when the incident chain points to OTS.
5. For eligible human-cut investigations, run best-effort FAQ/doc matching and historical ticket comparison.
6. Present a pre-execution investigation plan before broad evidence collection when working with a human user.
7. Collect evidence in a controlled order:
   - metrics and alarms
   - canary logs when applicable
   - Lumberjack, splat, or workflow logs
   - regional NOC cross-check after service-specific runtime evidence, using the workflow-defined NOC correlation window when a concrete investigation region has been derived
   - impact analysis from ticket and runtime evidence
   - ODO and Shepherd release activity
   - local code and repository context
8. Synthesize findings and challenge the hypothesis.
9. For complete investigations, write the investigation back to the ticket unless the user asks not to.
10. For blocked investigations, do not comment, label, transition status, or update companion fields by default. If the user explicitly asks for blocked writeback, post only blockers and next step, then add `ai-triage-blocked`.

The evidence-order summary above is intentionally opinionated:

- if a concrete investigation region is known, include the NOC cross-check in the plan using the workflow-defined NOC correlation window, but only run it after service-specific runtime evidence has been collected
- use the NOC cross-check as corroborating regional context, not as the primary source of truth for incident scope or root cause
- record both positive NOC overlaps and negative NOC results in the investigation outcome
- when a related NOC incident is cited as reference context in a complete final writeback, sync its exact NOC ticket id onto the incident ticket as a label when the ticket transport supports label mutation
- after complete final writeback, sync `ai-skill-triage` and the project-scoped `ai-triaged-by-<ticket-project-key>` label when the live ticket project reconciles cleanly against the selected team config
- do not sync normal triage, NOC, RCA, status, or companion-field updates while an investigation is blocked
- use the workflow-defined deployment correlation window for ODO and Shepherd release searches instead of the narrower first metric or log query window
- for request-path incidents, start the first replay in the system that emitted the strongest signal: splat for splat-backed or proxy-side signals, downstream service logs for downstream-emitted metrics or application errors, then pivot cross-system using stable request-id alignment

The skill loads deeper guidance progressively from:

- `SKILL.md`
- `references/workflow.md`
- `references/configuration.md`
- `references/metrics.md`
- `references/canary.md`
- `references/logging.md`
- `references/writeback.md`

## Skill Setup

### 1. Create a service-team config

Use `assets/service-team-config.template.toml` as the starting point. Store real team configs under `assets/service-teams/` or in a repo-local wrapper if your team keeps operational config elsewhere.

Each `[[team]]` block can define:

- ticket sources: Jira and/or OTS projects
- FAQ or documentation URLs
- code repositories and local repo paths
- alarm sources, metric fleets, dashboards, and host metrics
- canary settings
- optional SQLcl connection metadata for repeatable DB lookups, either as an existing saved alias or as bootstrapable saved-connection details
- Lumberjack and splat logging scopes
- ODO hints
- Shepherd project and flock mappings

### 2. Populate the team entry

At minimum, configure the incident sources your team actually uses:

- `team.tickets`
- `team.code.repositories`
- `team.observability.*`
- `team.sqlcl` when the service regularly needs SQLcl-backed database reads
- `team.lumberjack` and/or `team.splat` when log investigation is needed
- `team.shepherd` when release correlation matters

If your team has doc-based triage or service-request flows, add `[[team.faqs]]`.

### 3. Make sure auth is ready

The skill expects auth to be valid before it begins broad evidence collection.

Common auth requirements:

- a valid OCI CLI session for OCI-backed helpers and OTS-style reads
- a valid `OP_TOKEN` for logging, DevOps, or direct REST-backed investigation paths

Recommended MCP setup:

- Install and enable `DOPE_MCP` (`mcp-dope`) so the shared helper env file can configure `OP_TOKEN` for DevOps, logging, and direct REST-backed investigation paths.
- Install and enable `STLM_MCP` (`stlm-mcp`) for platform-resource investigation surfaces. It is the recommended MCP path for platform resources and includes OCI session token refresh support.
- Keep `stlm-mcp` and `mcp-dope` pointed at the same shared env file when possible, so `OP_TOKEN` and related helper settings are configured once.

For `oc1` OCI session auth, the workflow prefers `STLM_MCP` session refresh support when available and allows interactive browser authentication by default before declaring the investigation blocked. If required auth is still invalid after the supported refresh or authentication flow, the workflow pauses, reports the blocked surface, and asks the user to fix the unresolved blocker before continuing.

#### Codex MCP configuration flavor

For Codex, configure both MCPs in `~/.codex/config.toml` and point them at the same shared dotenv file when possible. The shared dotenv file should include the `OP_TOKEN` used by `mcp-dope`; `stlm-mcp` gets OCI session settings from its MCP env block.

```toml
[mcp_servers.stlm-mcp]
command = "uvx"
args = [
  "--index",
  "https://artifactory.oci.oraclecorp.com/api/pypi/global-release-pypi/simple/",
  "--env-file",
  "/ABSOLUTE/PATH/TO/YOUR/HOME/.env",
  "stlm_mcp@latest"
]
startup_timeout_sec = 300

[mcp_servers.stlm-mcp.env]
HOME = "/ABSOLUTE/PATH/TO/YOUR/HOME"
OCI_CONFIG_FILE = "/ABSOLUTE/PATH/TO/YOUR/HOME/.oci/config"
OCI_PROFILE = "oc1"
OCI_SESSION_AUTO_REFRESH = "true"
OCI_SESSION_AUTO_INTERACTIVE_AUTH = "true"
OCI_SESSION_AUTH_REGION = "us-ashburn-1"
OCI_SESSION_TENANCY_NAME = "bmc_operator_access"
OCI_SESSION_EXPIRATION_MINUTES = "60"
OCI_SESSION_REFRESH_TIMEOUT_SECONDS = "600"
LOG_DIRECTORY = "/ABSOLUTE/PATH/TO/YOUR/HOME/.codex/log"

[mcp_servers.mcp-dope]
command = "uvx"
args = [
  "--index",
  "https://artifactory.oci.oraclecorp.com/api/pypi/global-release-pypi/simple/",
  "--env-file",
  "/ABSOLUTE/PATH/TO/YOUR/HOME/.env",
  "devops_mcp@latest"
]
startup_timeout_sec = 300

[mcp_servers.mcp-dope.env]
HOME = "/ABSOLUTE/PATH/TO/YOUR/HOME"
LOG_DIRECTORY = "/ABSOLUTE/PATH/TO/YOUR/HOME/.codex/log"
```

Use dotenv format for the shared env file:

```dotenv
OP_TOKEN=
SSH_AUTH_SOCK=
```

Refresh `OP_TOKEN` into that file with the shared helper:

```bash
python3 skills/codex-bootstrap/scripts/refresh_auth.py op-token --env-file ~/.env
```

### 4. Keep local repos available when possible

If you want the skill to inspect code quickly, set `local_repo_path` in the team config to a real local checkout. The skill can still use remote repo metadata, but local search is faster and better for tracing symbols, metrics, and config names.

## How To Use The Skill

Use the skill when you want Codex to investigate a non-`CHANGE` incident using a known team config.

Recommended invocation pattern:

1. Tell Codex to use `On-Call Investigation`.
2. Provide the ticket, incident link, or investigation target.
3. Optionally provide the service-team config path or team name when you want to force a specific mapping.
4. Optionally provide known scope hints such as region, request id, canary name, or time window.

Typical inputs:

- Jira ticket URL or key
- OTS ticket URL or identifier
- alarm URL or alarm id
- request id, workflow id, or canary failure context
- team config path plus a short investigation goal

For human-driven investigations, the skill should stop after ticket intake and present the pre-execution plan before it runs broad metrics, logs, release, or code analysis.

After the current patch, the expected local-repo investigation sequence is:

1. team config selection
2. auth preflight
3. ticket intake
4. ticket intent and cut-type classification
5. source-of-truth resolution
6. FAQ/doc answer pass when eligible
7. historical ticket triage when eligible
8. pre-execution investigation plan
9. explicit approval for human-driven investigations
10. metrics and logs
11. regional NOC cross-check using the workflow-defined NOC correlation window when a concrete investigation region has been derived
12. impact analysis
13. ODO, deployments, and releases using the workflow-defined deployment correlation window
14. code and repo context
15. conclusion review and synthesis
16. ticket writeback for complete investigations only; blocked investigations do not mutate tickets by default

### Prompting Tips

The prompt does not need to be very detailed.

What you usually need:

- which skill to use
- the ticket or incident identifier

What the skill should infer on its own:

- mapping the ticket to the right configured team when the project, repo, or local path makes that unambiguous
- validating auth before broad evidence collection
- whether Jira or OTS is the authoritative ticket source
- whether to check metrics, logs, canary, releases, or code first
- whether complete writeback is part of the default workflow, and whether blocked writeback was explicitly requested

What is still helpful to mention when you know it:

- the team config path or team name when multiple teams could match, or when you want to force one specific config
- a request id, workflow id, canary name, region, or time window
- a specific area to prioritize first, such as splat or Shepherd
- whether you want complete writeback drafted only or actually posted
- whether you explicitly want a blocked-investigation writeback when required evidence is unavailable

## Dependencies

This skill depends on configuration, reference files, auth, ticket transports, and the evidence tools needed by the selected investigation path.

### Bundled files

- `SKILL.md`
- `references/workflow.md`
- `references/configuration.md`
- `references/metrics.md`
- `references/canary.md`
- `references/logging.md`
- `references/writeback.md`
- `assets/service-team-config.template.toml`
- `assets/service-teams/*.toml`
- `agents/openai.yaml`

### Core operational dependencies

- valid service-team TOML configuration
- `Jira Ticket` when Jira is the source ticket, source of truth, or writeback target
- `OTS Ticket` when OTS is the source ticket, source of truth, or writeback target
- OCI CLI session for OCI-backed ticket, ODO, Shepherd, or other reads
- `OP_TOKEN` when the investigation path requires logging, DevOps, or direct REST access
- `DOPE_MCP` (`mcp-dope`) installed and configured for `OP_TOKEN`
- `STLM_MCP` (`stlm-mcp`) installed for platform resources and OCI session refresh support
- metrics, logs, canary, ODO, Shepherd, SQLcl, and local-repo access only when the selected team config and incident path require those surfaces

## Example Prompts

```text
Use On-Call Investigation to investigate JIRA-12345.
```

```text
Use On-Call Investigation to investigate OTS-123456.
```

```text
Use On-Call Investigation to investigate JIRA-98765 and draft the writeback comment, but do not post it yet.
```

```text
Use On-Call Investigation to investigate this request failure. The opc-request-id is abcd1234.
```

```text
Use On-Call Investigation to investigate JIRA-54321. Prioritize splat first because I suspect a proxy-side failure.
```
