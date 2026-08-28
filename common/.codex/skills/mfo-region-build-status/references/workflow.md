# MFO Region-Build Workflow

Use this workflow after the skill triggers.

## Goal

Determine whether the requested region-build flock is ready, blocked, or not triggered, then explain exactly which capabilities are satisfied, which are still missing, and which producer flock or upstream capability is currently responsible for the block.

## Inputs

Require:

- `region`
- `project`
- `flock`
- `phonebookId`

Optional:

- exact region-build flock URL
- preferred phase name when the user wants to narrow a very large flock page

## Evidence Order

1. Start with the flock’s region-build URL so the requested target is explicit.
2. Prefer the Devplat MCP Gateway `mfo-bo-peep` target for regional flock data when it is available, read-only, and authenticated.
3. If the gateway loader, plugin, or `mfo-bo-peep` target is missing, recommend the linked setup guide and continue to fallback unless the user explicitly requested MCP-only.
4. Fall back to the authenticated DevOps `bo-peep` proxy API when the gateway is unavailable or does not expose the needed read tool.
5. Record every reportable phase and its capability dependency state. Hide `ohe_vibe*` phases unless the user explicitly asks for them.
6. For each pending required capability, identify the producer from gateway/API evidence or the UI `Producers` fallback.
7. Inspect the producer flock status and repeat the same phase and capability review.
8. Stop only when the dependency chain reaches a terminal result or an error boundary.

## Step-By-Step

### 1. Open the flock page

Use a region-build URL in this shape when constructing the entry point:

```text
https://devops.oci.oraclecorp.com/region-build/regions/<region>/flocks?flocksFilter=flockName%20%3D%20<flock>
```

If the page is already provided, reuse it rather than rebuilding it.

### 2. Try the Bo Peep gateway path

When the Devplat MCP Gateway is available, load the Bo Peep target first:

```text
devplat_mcp_gateway__use target=mfo-bo-peep
```

Use only the tool names and `inputSchema` returned by the gateway. Select read-only tools that return region, flock, phase, capability, or producer data. Do not infer tool names or arguments from old sessions, examples, or local source.

The gateway path expects already-configured Bo Peep auth:

- `MCP_BO_PEEP_AUTH_PROVIDER=OP_TOKEN`
- `MCP_BO_PEEP_ENDPOINT=https://devops.oci.oraclecorp.com/api/bo-peep`
- `MCP_BO_PEEP_ENABLE_WRITES=0` for read-only behavior

If the gateway reports missing Bo Peep config, missing or expired Operator JWT, or unavailable local gateway, record that as a data-source fallback reason and continue to the direct proxy path. Do not run `mcpgw refresh-jwt`, `mcpgw config BoPeep`, or config mutation commands from this skill; tell the user which local command is required if the gateway cannot recover without them.

If `devplat_mcp_gateway__use`, the Devplat MCP Gateway plugin, or the `mfo-bo-peep` target is not available in the current Codex session, record that Bo Peep MCP is not installed or available. Recommend installing/configuring Devplat MCP Gateway using the [MCP Gateway - Customer Setup Guide](https://confluence.oraclecorp.com/confluence/display/aipioneers/MCP+Gateway+-+Customer+Setup+Guide), then continue to the direct proxy path unless the user explicitly requested MCP-only.

Use this distinction when reporting MCP fallback reasons:

- Missing plugin, missing gateway loader, or missing `mfo-bo-peep` target: recommend the setup guide.
- Gateway down, Docker/Colima unavailable, missing Bo Peep config, missing/expired auth, or Bo Peep request failures: report the local remediation command or prerequisite, but do not recommend reinstalling unless the gateway skill says the plugin itself is missing.

### 3. Try the authenticated proxy API path

When gateway data is unavailable and DevOps web or Operator JWT auth is available, use these proxy endpoints:

```text
https://devops.oci.oraclecorp.com/api/bo-peep/v0/regions/<region>
https://devops.oci.oraclecorp.com/api/bo-peep/v0/regions/<region>/flocks?limit=2000
```

Follow `opc-next-page` until the requested `project`, `flock`, and `phonebookId` are found or pagination ends.

Notes:

- Query the proxy through `devops.oci.oraclecorp.com`; direct backend hosts may not resolve from the shell.
- Use an existing approved `OP_TOKEN` as a bearer token when available, or an already-approved authenticated DevOps web session. The skill does not own credentials.
- Keep broad regional payloads in memory only. Persist the final report and minimal evidence, not the full regional dataset.
- API phase payloads usually include `capabilitiesConsumed` and `capabilitiesProduced`. Normalize `capabilitiesConsumed` into satisfied, pending required, and pending optional lists.

### 4. Scan all reportable phases

For the target flock:

- read every reportable phase
- hide `ohe_vibe*` phases by default
- record any phase state badges or readiness hints
- open `capability dependencies` for each phase that is blocked, ambiguous, or otherwise relevant

Always capture:

- phase name
- change type, such as `Application` or `Infrastructure`
- phase status or last pass state
- capabilities the phase publishes or will publish when successful
- `satisfied`
- pending required capabilities
- pending optional capabilities

If a flock has no unsatisfied capabilities in any phase, classify it as ready unless the page explicitly says the flock is not triggered.

### 5. Record producer lookups

For each unsatisfied capability:

- use gateway or API producer evidence first when the captured graph contains it
- open `Producers` only when gateway/API evidence cannot identify a producer
- record the producing project and flock
- capture the producer page URL if one is linked or derivable

If `Producers` returns:

- zero producers: report the lookup as incomplete or auth-blocked unless the UI explicitly explains the reason
- more than one producer: stop and classify it as `orchestration error`

### 6. Inspect the producer flock

Repeat the same phase scan on the producer flock page:

- capture satisfied, unsatisfied, and optional capabilities
- capture any producer-side publication evidence
- capture whether the producer flock is failed, in progress, or not triggered

If the producer clearly shows the required capability as already published, close that branch as `published`.

If the producer has not published the required capability and the producer flock is failed, close that branch as `producer failed`.

If the producer has not published the required capability and the producer flock is still in progress, building, running, queued, or otherwise actively executing, close that branch as `producer in progress`.

If the producer is waiting on another capability, recurse into that capability’s producers.

### 7. Keep the recursion bounded

Track visited capability edges and flock nodes.

Stop the branch when you hit:

- `published`
- `producer failed`
- `producer in progress`
- `not triggered`
- `upstream capability missing`
- `producer blocked`
- `auth/visibility blocked`
- `cycle detected`
- `orchestration error`

Use `cycle detected` when the same capability or flock repeats in the active recursion stack.

### 8. Normalize before reporting

Normalize snapshots into the canonical graph schema before tracing:

```bash
python3 skills/mfo-region-build-status/scripts/normalize_region_build_snapshot.py raw.json > normalized.json
```

The normalizer accepts:

- a single page snapshot
- a partially assembled `nodes` graph
- gateway-returned Bo Peep data after mapping it into the canonical schema
- a `bo-peep` regional flock object that includes `phases[].capabilitiesConsumed` and `phases[].capabilitiesProduced`
- mixed field names such as `phonebookId` and `phonebook_id`

### 9. Generate the structured report

Use the tracer once the graph contains the starting flock and as many upstream producer snapshots as you were able to capture:

```bash
python3 skills/mfo-region-build-status/scripts/trace_region_build_dependencies.py \
  --input normalized.json \
  --project <project> \
  --flock <flock> \
  --region <region> \
  --report-format text
```

The text report should include:

- a target summary with region, project, flock, phonebookId, URL, and checked-at timestamp
- overall flock status and version-set publication information when available
- a phase table with status, published or planned capabilities, pending required capabilities, and pending optional capabilities
- a pending capability producer table with producer, producer status, upstream blockers, and next inspect target
- a readable dependency chain from the target flock to upstream blockers

If the graph is incomplete, keep the report structured and surface the next flock or project to inspect.

## Report Checklist

Include:

- requested inputs
- entry URL
- evidence URLs
- overall status
- every phase reviewed
- blocker capabilities
- producer chain for each blocker
- terminal reason for each branch
- discovered related flocks
- next target to inspect when the branch cannot complete

## Failure Handling

- If the UI popup does not load, report `auth/visibility blocked` for that branch.
- If the producer view is empty and there is no authoritative explanation, do not guess. Carry the branch as blocked.
- If the page structure changes, preserve the raw capture, describe which control failed, and continue with whatever evidence is still trustworthy.
