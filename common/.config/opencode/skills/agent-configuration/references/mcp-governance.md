# MCP governance (least privilege)

## Non-negotiables

- Default-deny MCP tools globally.
- Route enterprise operations through purpose-built ops agents (e.g., per-service agents with scoped tool access).
- Inventory-backed changes only (don't guess tool names).

## Enforced truth

Your harness config file is the single source of truth for MCP governance:
- Which servers exist and are enabled
- Global allow/deny map (wildcard deny + explicit enables)

Use your harness's introspection commands to verify the active config matches your expectations.

## Tool inventory snapshots

Maintain convenience snapshots to support least-privilege auditing:
- Current allowlists per MCP server
- Full tool inventories per server
- Diff reports (available vs enabled)

These are evidence for audits, not authoritative policy. The enforced config is truth.

## Paid / metered tools

- Identify metered API calls in your inventory and document budget guardrails.
- Default: low-volume ok. Bursts require explicit approval.
- Explicit approval required before issuing high-volume calls (concurrent or scripted).

## Change process (adding a tool or server)

1) Identify tool(s) from the upstream inventory.
2) Decide ownership: which ops agent (or which scope) owns this tool?
3) Scope: enable for the owning agent first; keep global deny in place.
4) Guardrails: prefer read-only; keep write tools disabled unless there is an immediate need.
5) Verify via a minimal read-only smoke test using the owning agent.
6) Record the delta as an inventory update (allowlist snapshot + link to source).

## Domain specifics live in domain skills

This skill is harness/framework-agnostic.

- Org-specific MCP servers belong under your domain-specific skill (e.g., vendor tooling, internal services). Do not assume tool name prefixes; use the inventory + allowlists as the source of truth.
- Domain-specific routing conventions belong in domain skills distributed via your org's packs.

## Drift control

- Quarterly: reconcile local allowlists vs upstream inventories; remove dead tools.
