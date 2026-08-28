# Tool Map

## URL Parsing

Use `scripts/parse_release_link.py` when the input is a Shepherd release URL.

The common release path shape is:

```text
/shepherd/projects/<project>/flocks/<flock>/releases/<release_id>
```

Fallback regex:

```regex
/shepherd/projects/(?P<project>[^/]+)/flocks/(?P<flock>[^/]+)/releases/(?P<release_id>[0-9a-fA-F-]{36})
```

The parser focuses on these stable identifiers:

- `project`
- `flock`
- `release_id`
- `phase` when a deeper execution-target path includes it
- `execution_target_id` when present in the path
- `release_target_id` when present in the path or query string

The common release path alone gives only:

- `project`
- `flock`
- `release_id`

The common release path does not give:

- `phase`
- `execution_target_id`
- `release_target_id`
- target name
- target region

Resolve any missing target-level identifiers from Shepherd data.

Ignore UI-only parameters such as `tabId`; they are not part of the stable identifier set.

## Shepherd Data Sources

Use these in order:

1. `get_shepherd_release`
   - Use for release status, change type, change class, current phase, artifacts, created or started timestamps, and top-level counts.
2. `get_shepherd_release_phases`
   - Use for ordered phase names, approval data, phase status, and phase timestamps.
3. `get_shepherd_release_changes`
   - Use for release-scoped resource changes, optionally filtered by `phase_name`.
   - Prefer one call per relevant phase so the change list stays auditable and does not collapse multiple rollout waves together.
4. Detailed phase or execution-target view
   - Prefer the Shepherd helper that returns `phases[] -> execution_targets[]` because it usually includes `releaseTargetId`, `name`, `region`, `actions`, `errors`, and alarm metadata in one response.
   - If that helper is unavailable, use `get_shepherd_phase_execution_targets` for each phase and then enrich with per-target errors or state calls.
5. `get_shepherd_execution_target_errors`
   - Use for exact target failure records and timestamps.
6. `get_shepherd_release_target_logs`
   - Use for a single target's release log stream.
7. `get_shepherd_release_all_target_logs`
   - Use when many targets fail and you need a broad scan.
8. `get_shepherd_execution_target_state`
   - Use to identify the cached or final state ids for a target.
9. `get_shepherd_execution_target_state_body`
   - Use for deployed ODO state, exec or canary statuses, artifact versions, and validation evidence.
10. `list_shepherd_execution_target_states`
   - Use when you need state history, especially to confirm the latest fresh or final state.
11. `get_shepherd_releases`
   - Use to find the prior successful release for the same flock when selecting a diff baseline.

## Identifier Resolution Checklist

For every target you analyze, record:

- `project`
- `flock`
- `release_id`
- `phase`
- target name
- target region
- `execution_target_id`
- `releaseTargetId`
- current target status

If a target-level call returns only one of `execution_target_id` or `releaseTargetId`, keep both identifiers visible in your notes and recover the missing one from the detailed phase view before moving on.

## Auth Preflight

Validate auth before treating missing or unauthorized data as release evidence:

- validate OCI session-backed auth before CLI or direct Shepherd or DevOps API calls
- validate `OP_TOKEN` before direct DevOps or Lumberjack replay paths
- if auth is invalid and cannot be refreshed non-interactively, stop and report the auth blocker clearly

## Region and Target Naming

- Prefer the explicit `region` field from Shepherd over parsing it from the target name.
- Keep the human target name exactly as shown by Shepherd, such as `us-seattle-1-beta`.
- When a later Lumberjack search needs the canonical short region, use the region form expected by that API, such as `r1` instead of `us-seattle-1`, when runtime evidence shows that mapping is required.

## Lumberjack Escalation

Only escalate after Shepherd evidence stops answering the question.

Useful tools:

1. `get_compartments_by_phonebook`
   - Use to find the likely service-owned compartments from a phonebook.
2. `get_logging_namespaces`
   - Use to discover the real namespace inventory for the region and tenant instead of guessing from naming patterns.
   - Common Shepherd namespace inventory observed during release investigations includes tenant `shepherd` with namespaces such as `shepherd-executor`, `shepherd-regional`, and `shepherd-worker`.
   - Treat those as discovery hints only. Confirm them at runtime with `get_logging_namespaces` instead of assuming they will exist or be readable in every region or account context.
3. `search_logs`
   - Search exact identifiers first:
     - work request id
     - workflow id
     - tenancy ocid
     - order id
     - request id
     - host
     - target name
4. direct DevOps Ibex replay
   - Use when `search_logs` can discover namespace inventory but cannot actually read the downstream namespace.
   - Retry the same exact window and identifiers with exported `OP_TOKEN`, or with browser-authenticated replay if portal access is available.

If exact-id search is empty, keep the same time window and scan nearby service or workflow namespaces before widening the window.
If exact-id search returns `NotAuthorizedOrNotFound`, verify the query shape with a control query against a namespace you know is readable. Treat a successful control query plus blocked downstream namespace as a visibility boundary, not as evidence that the downstream service emitted nothing.
If discovered Shepherd namespaces such as `shepherd-executor`, `shepherd-regional`, or `shepherd-worker` return `NotAuthorizedOrNotFound` while a control namespace works, report that as a log-visibility boundary rather than concluding Shepherd emitted no logs.
