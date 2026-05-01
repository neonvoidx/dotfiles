# OCM AI

OCM has a strong habit of shipping high-quality hackathon prototypes and turning the best ideas into maintainable engineering.

This facet is about:
- how OCM uses AI effectively (harness-first, governance-first)
- capturing team patterns (what works repeatedly)
- and building a path to public contribution (shared configs, usage guidance, standard setting).

## When to use
- You’re shaping or reviewing OCM AI work (agents, MCP, tool governance, safe automation patterns) and want the “why” plus the default posture.
- You need pointers to the canonical OCM/OCI governance anchors to keep AI-enabled workflows safe and maintainable.

## When not to use
- You need detailed harness setup steps for your specific environment. Use the harness configuration index referenced below.
- You’re doing general OCI MCP governance work that isn’t OCM-specific. Prefer the oracle/mcp repo or aipack-core `aipack-system` skill.

## What to load
- Harness configuration patterns and sync behavior → aipack-core `aipack-system` skill
- OCI AI/MCP governance anchors → the oracle/mcp repo

## North Star AI targets (why this facet exists)
From the OCM North Star 2026 roadmap:
- **FY28:** *AI-prompt based chat as Migration Assistant on Console* (Q2FY28)
- **FY29+:** *AI Powered Migration Automation* (Q4FY29)

This skill facet captures the foundations being built *now* (MCP servers, tool governance, safe automation patterns) so those roadmap items can be delivered safely.

## Foundations: OCI/OCM via MCP (oracle/mcp)

Repo: https://github.com/oracle/mcp (Oracle OSS MCP servers)

### “Migration Assistant” default posture (read-only)
For any assistant-like workflows (Console chat, triage copilots, runbook helpers):
- default to **read-only** OCI MCP tools
- route OCI interactions via `@oci-ops` (never broad global tool access)
- prefer “plan + explain + ask” over “do”

Recommended read-mostly MCP servers/tools (examples):
- resource discovery: `oci-resource-search-mcp-server`
- migration tracking: `oci-migration-mcp-server`
- tenancy scoping: `oci-identity-mcp-server`
- infra inventory: `oci-compute-mcp-server`, `oci-networking-mcp-server`, `oci-object-storage-mcp-server`
- observability: `oci-logging-mcp-server`, `oci-monitoring-mcp-server`
- cost context: `oci-usage-mcp-server`

### “AI Powered Automation” escalation (mutating, tightly gated)
When a workflow must *change* OCI state, keep it narrow:
- enable only the **specific mutating tools** required for that workflow
- require explicit confirmation at every destructive boundary (create/update/delete/terminate)
- keep an audit trail (command/tool + parameters + rationale)

High-risk tools to keep disabled unless explicitly needed:
- `oci-api-mcp-server` (arbitrary `run_oci_command` = effectively “OCI CLI as a tool”)
- compute/networking create/delete/terminate actions

## Playbook
- `migrationAssistantPlaybook.md`

## Confluence anchors (OCM AI / agent initiatives)
- MCP server expansion plan (OCM+OCB): https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=18943784416
- Starfix agent workflows (Cline + Jira/DevOps MCP): https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=17742149606
- Ops stabilization plan (includes AI adoption): https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=18120506580
- Ops stabilization tracker: https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=18269296927
