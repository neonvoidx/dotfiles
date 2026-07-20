---
name: mfo-region-build-status
description: Inspect DevOps MFO or region-build flock dependency status for a specific region, project, flock, and phonebookId. Use when Codex needs to determine which region-build phases are satisfied, unsatisfied, or optional; identify whether a flock has published the required capabilities; recursively trace missing capability producers; discover related infrastructure or application flocks from the dependency graph; or explain which upstream project or flock is blocking publication.
---

# MFO Region Build Status

Use this skill for read-only DevOps region-build or MFO capability investigations. Start from one flock page, scan every visible phase, summarize satisfied, unsatisfied, and optional capability dependencies, then recursively trace unsatisfied capabilities through producer flocks until the chain reaches a published capability, a terminal blocker, or an orchestration error.

## Required Inputs

Collect or confirm these inputs before starting:

- `region`
- `project`
- `flock`
- `phonebookId`

If the user gives only a region-build URL, extract the same values from the page before continuing.

## Fast Path

1. Build the flock’s region-build entry URL for the requested `region` and `flock`.
2. Prefer the Devplat MCP Gateway Bo Peep target when it is available:
   - Load the gateway target with `devplat_mcp_gateway__use` using target `mfo-bo-peep`.
   - Use only the tool names and `inputSchema` returned by the gateway. Do not infer tool names, arguments, or response shapes from examples, local source, or prior sessions.
   - If `devplat_mcp_gateway__use`, the Devplat MCP Gateway plugin, or the `mfo-bo-peep` target is not available in the current Codex session, report that Bo Peep MCP is not installed or available. Recommend installing/configuring it with the [MCP Gateway - Customer Setup Guide](https://confluence.oraclecorp.com/confluence/display/aipioneers/MCP+Gateway+-+Customer+Setup+Guide), then continue to the direct proxy fallback below.
   - Use read-only Bo Peep tools only. If the gateway reports missing Bo Peep config, missing or expired Operator JWT, or an unavailable local gateway, report that blocker and continue to the direct proxy fallback below.
3. Fall back to the authenticated `bo-peep` proxy API when the current Codex environment can reuse an approved Operator JWT or authenticated DevOps session:
   - `GET https://devops.oci.oraclecorp.com/api/bo-peep/v0/regions/<region>`
   - `GET https://devops.oci.oraclecorp.com/api/bo-peep/v0/regions/<region>/flocks?limit=2000`, following `opc-next-page`
4. Locate the requested `project`, `flock`, and `phonebookId` in the regional flock payload. Keep full regional data in memory only; persist only the final report or minimal evidence snippets.
5. Scan all reportable phases for that flock. By default, ignore `ohe_vibe*` phases because they are not needed for the operator MFO status view. Include them only if the user explicitly asks for those phases.
6. For each phase, record:
   - phase name, change type, and status or last pass state
   - capabilities the phase publishes or will publish when successful
   - satisfied capabilities
   - pending required capabilities
   - pending optional capabilities
7. For each pending required capability, identify the producer project and flock from gateway or API evidence when available; otherwise open `Producers` in the browser fallback.
8. Continue recursively through the producer chain until you hit one of these stop conditions:
   - the capability is already published
   - the producer flock failed before publishing the required capability
   - the producer flock is still in progress before publishing the required capability
   - the producer flock is not triggered
   - the producer is blocked by another upstream capability
   - auth or page visibility prevents inspection
   - the graph contains a cycle
   - the same capability reports multiple producers
9. Normalize captured gateway, API, or page data with `scripts/normalize_region_build_snapshot.py`.
10. Build the structured report with `scripts/trace_region_build_dependencies.py`.

## Auth Model

- The skill is read-only and does not own credentials.
- Prefer the `mfo-bo-peep` gateway path when an operator JWT and Bo Peep gateway configuration are already available. The gateway's current supported Bo Peep auth provider is `OP_TOKEN`, with endpoint `https://devops.oci.oraclecorp.com/api/bo-peep`.
- Do not run credential-refresh or gateway configuration mutation commands from this skill, including `mcpgw refresh-jwt`, `mcpgw config BoPeep`, or `mcpgw config ... --from-env`. If the gateway reports missing or expired auth/config, tell the user exactly which local command the gateway skill requires them to run.
- For the direct proxy fallback, use an existing approved `OP_TOKEN` or authenticated DevOps web session. `OP_TOKEN` can be refreshed with the shared `codex-bootstrap` helper when the environment already permits that flow.
- For browser fallback, use the user's active DevOps SSO session only when browser-backed extraction is approved and needed.

## Workflow Rules

- Prefer a gateway-first mixed approach. Use the `mfo-bo-peep` Devplat MCP Gateway target first when it is reachable, configured, read-only, and authenticated.
- For DevOps MFO pages, use the direct `devops.oci.oraclecorp.com/api/bo-peep/v0` proxy as the first fallback over direct backend hosts such as `event.oci.oraclecorp.com`, because the proxy works with the DevOps web authentication boundary and avoids DNS issues in some shell environments.
- Fall back to browser-backed inspection when the dependency popups, producer details, or capability publication state are only exposed in the UI.
- When the Devplat MCP Gateway plugin or `mfo-bo-peep` target is not installed or visible, recommend the [MCP Gateway - Customer Setup Guide](https://confluence.oraclecorp.com/confluence/display/aipioneers/MCP+Gateway+-+Customer+Setup+Guide) and explain that Bo Peep requires local Devplat MCP Gateway setup plus Bo Peep config/auth. Do not run those setup, credential, or config commands from this skill.
- When the gateway is unavailable, do not treat that as an MFO result. Record the gateway/auth blocker and continue to the direct proxy or browser fallback.
- When an authenticated browser session is approved for reuse, extract only the minimal scoped session material needed for the DevOps request. Do not copy the full browser cookie database or persist broad regional datasets.
- Treat a capability with multiple producers as an orchestration error. Report it explicitly instead of guessing which producer is authoritative.
- When inspecting a producer, first check whether it has published the exact required capability. If not, stop immediately on producer `failed` or `in progress` states before tracing deeper upstream dependencies.
- Discover related infrastructure and application flocks from the dependency graph. Do not require the caller to provide both flock names up front.
- Keep the report read-only. Do not mutate DevOps, Shepherd, or phonebook state.
- Use absolute URLs in notes and evidence references whenever available.

## Scripts

Use the bundled scripts to keep the investigation deterministic once the raw page data is captured.

- `scripts/normalize_region_build_snapshot.py`
  Normalize a single page snapshot or a partially assembled graph into the canonical schema used by the tracer.
- `scripts/trace_region_build_dependencies.py`
  Walk the normalized dependency graph, classify terminal blocker reasons, and emit either JSON or a compact text report.
- `scripts/region_build_common.py`
  Shared normalization and report helpers used by both entrypoint scripts.

Typical flow:

```bash
python3 skills/mfo-region-build-status/scripts/normalize_region_build_snapshot.py raw-snapshot.json > normalized.json
python3 skills/mfo-region-build-status/scripts/trace_region_build_dependencies.py \
  --input normalized.json \
  --project service-registry \
  --flock tenancy-creator \
  --region af-nairobi-1 \
  --report-format text
```

Run the built-in deterministic checks with:

```bash
python3 skills/mfo-region-build-status/scripts/trace_region_build_dependencies.py --self-test
```

## Output Contract

Always produce a structured dependency report with:

- requested inputs
- checked-at timestamp
- entry URL
- evidence URLs visited
- overall status for the starting flock
- per-phase summaries for all reportable phases, excluding `ohe_vibe*` by default
- phase status, change type, capabilities published or planned by the phase, pending required capabilities, and pending optional capabilities
- blocked phase list
- aggregate satisfied, unsatisfied, and optional capability lists
- current blocking capability or capabilities
- producer table for each pending required capability, including producer, producer status, upstream blockers, and next place to inspect
- readable dependency chain from target flock to upstream producer blockers
- producer trace for each blocker
- terminal blocker reason:
  - `published`
  - `producer failed`
  - `producer in progress`
  - `not triggered`
  - `upstream capability missing`
  - `producer blocked`
  - `auth/visibility blocked`
  - `cycle detected`
  - `orchestration error`
- discovered related flocks
- next flock or project to inspect when the recursive walk cannot complete from currently captured data

## Guardrails

- Do not claim a capability is published unless the producer-side evidence or normalized snapshot explicitly shows it.
- Do not collapse `optional` capabilities into the blocker list.
- Do not infer producer roles from naming alone. If infra or app labeling is not explicit, report the related flock without inventing a role.
- Do not stop at the first unsatisfied capability when a phase has multiple blockers.
- Do not report “all clear” if any phase still has unsatisfied capabilities or unresolved producer traces.
- If auth or the UI blocks the next recursive hop, return a blocked-but-structured report instead of a partial narrative guess.

## Read Next

- `references/workflow.md`
  Read for the step-by-step capture and recursive tracing workflow.
- `references/ui-map.md`
  Read for the page terminology, known UI controls, normalized schema mapping, and operator-facing conventions.
