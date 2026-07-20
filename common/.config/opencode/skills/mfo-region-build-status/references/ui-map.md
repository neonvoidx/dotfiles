# MFO Region-Build UI Map

This reference captures the current operator-facing concepts for the region-build workflow described by the user-provided Nairobi example.

## Entry Page

Example:

```text
https://devops.oci.oraclecorp.com/region-build/regions/af-nairobi-1/flocks?flocksFilter=flockName%20%3D%20tenancy-creator
```

Meaning:

- `region`: `af-nairobi-1`
- `flock`: `tenancy-creator`
- project context is provided separately by the operator, for example `service-registry`
- phonebook context is provided separately by the operator, for example `Itm`

## Known Controls

### Phase rows

The flock page can show multiple phases. The skill must scan all visible phases by default.

Known example:

- `vibe-af-nairobi-1`

### Capability dependencies

Each relevant phase has a `capability dependencies` control. Opening it reveals capability buckets:

- `Satisfied`
- `Unsatisfied`
- `Optional`

Treat these buckets as the primary dependency truth for the phase.

### Capability producer lookup

Each unsatisfied capability exposes:

- `Consumers`
- `Producers`

Use `Producers` to find the upstream project or flock that should publish the capability.

If `Producers` expands to multiple candidate producers for the same capability, classify that as an orchestration problem rather than a valid dependency chain.

## Canonical Schema Mapping

Map captured page data into the canonical graph fields used by the scripts:

- page URL -> `page_url`
- region -> `region`
- project -> `project`
- flock -> `flock`
- phonebook id -> `phonebook_id`
- phase name -> `phases[].name`
- phase change type -> `phases[].change_type`
- phase state badge if available -> `phases[].state`
- satisfied capabilities -> `phases[].satisfied_capabilities`
- unsatisfied capabilities -> `phases[].unsatisfied_capabilities`
- optional capabilities -> `phases[].optional_capabilities`
- phase produced or planned capabilities -> `phases[].produced_capabilities`
- producer lookup result -> `producer_capabilities.<capability>.producers`
- producer lookup failure state -> `producer_capabilities.<capability>.lookup_state`
- capabilities already published by the producer -> `produced_capabilities`
- capabilities the producer still intends to publish after upstream blockers clear -> `pending_published_capabilities`

## Bo Peep Gateway Mapping

Use the Devplat MCP Gateway first when the `mfo-bo-peep` target is available:

```text
devplat_mcp_gateway__use target=mfo-bo-peep
```

Gateway-backed tools are loaded lazily. Use only the tool names and `inputSchema` returned by the gateway response. Do not infer concrete tool names, arguments, or response shapes from examples, local source, or prior sessions.

Map gateway-returned region-build data into the canonical graph fields below. If a returned tool already exposes region, flock, phase, capability, or producer objects, normalize those objects directly. If the gateway target is unavailable, lacks the needed read-only tool, or reports an auth/config boundary, preserve the reason as evidence and use the direct proxy mapping.

Expected read-only gateway auth/config assumptions:

- auth provider: `OP_TOKEN`
- endpoint: `https://devops.oci.oraclecorp.com/api/bo-peep`
- writes disabled: `MCP_BO_PEEP_ENABLE_WRITES=0`

## Bo Peep Proxy Mapping

Use the DevOps proxy when authenticated web session material is available:

```text
https://devops.oci.oraclecorp.com/api/bo-peep/v0/regions/<region>
https://devops.oci.oraclecorp.com/api/bo-peep/v0/regions/<region>/flocks?limit=2000
```

Follow `opc-next-page` for regional flock pagination. Map response fields as follows:

- `publicRegionName` -> `region`
- `projectName` -> `project`
- `flockName` -> `flock`
- `phonebookId` -> `phonebook_id`
- `flockStatus` -> report metadata `flock_status`
- `flockCompletionStatus` -> report metadata `completion_status`
- `infrastructureVersionSet` -> report metadata `infrastructure_version_set`
- `applicationVersionSet` -> report metadata `application_version_set`
- `phases[].phaseName` -> `phases[].name`
- `phases[].changeType` -> `phases[].change_type`
- `phases[].lastPass.state` -> `phases[].last_pass_state`
- `phases[].capabilitiesProduced` -> `phases[].produced_capabilities`
- `phases[].capabilitiesConsumed[]` where `satisfied=true` -> `phases[].satisfied_capabilities`
- `phases[].capabilitiesConsumed[]` where `required=true` and `satisfied=false` -> `phases[].unsatisfied_capabilities`
- `phases[].capabilitiesConsumed[]` where `required=false` and `satisfied=false` -> `phases[].optional_capabilities`

Hide `ohe_vibe*` phases in the default operator report. Include them only for explicit diagnostics.

## Lookup State Values

Use these values consistently:

- `resolved`
- `auth_blocked`
- `visibility_blocked`
- `not_found`
- `unknown`

## Status Conventions

Use these branch outcomes in reports:

- `published`
- `producer failed`
- `producer in progress`
- `not triggered`
- `upstream capability missing`
- `producer blocked`
- `auth/visibility blocked`
- `cycle detected`
- `orchestration error`

## API Discovery Hints

Prefer gateway-returned Bo Peep data when the `mfo-bo-peep` target is available and authenticated. Use the `bo-peep` proxy endpoints as the direct HTTP fallback, and keep the browser fallback path available for popup-only producer details, missing producer lookups, or page structure drift.
