---
name: content-discovery-source-guide
description: Curated source guide for OCI starter-pack content discovery surfaces, connector catalogs, and authoritative setup references
metadata:
  owner: platform_org
  last_updated: 2026-06-01
---

# Content Discovery Source Guide

Use this as a curated starting map. Prefer these landing pages and catalogs over ad hoc search results, then verify current ownership and install instructions from the source before recommending installation.

## Starter Path

| Surface | What It Is | Start Here | AIPack Role |
|---|---|---|---|
| OCI Platform bootstrap | First-run path for OCI Platform engineers installing starter packs into their own profile | [10-Minute AI Bootstrap for OCI Platform Engineers](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=20467814861) | Baseline install and profile composition |
| AIPack overview | AIPack entry point and related docs | [AIPack Jump Page](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=20216486635) | Pack distribution, profile composition, sync |
| OCA/Codex setup | Oracle Code Assist Codex runtime setup | [OCA Codex CLI / Desktop / IDE instructions](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19169719016) | Adjacent runtime setup; AIPack renders content after runtime exists |

## Pack And Registry Sources

| Surface | What It Is | Start Here | Failure Owner |
|---|---|---|---|
| Active profile packs | Content already composed into the target profile | `aipack status --profile <profile> --json` | AIPack profile/sync |
| Registered packs | Installable pack bundles with rules, skills, workflows, MCP, configs, prompts, or extras | `aipack registry list --json`, `aipack search --available --kind pack --json` | AIPack registry owner or pack owner |
| Non-pack registry entries | Skill-only or content-slice sources exposed through `content_paths`; exclude sources already exposed as full packs | `aipack registry list --json` entries with `content_paths` | Source repo owner |
| Team-local packs | Team-owned packs not vetted by starter onboarding | Registry metadata, owner/contact, repo README | Team pack owner |

## Skills And Prompt Sources

| Surface | What It Is | Start Here | Notes |
|---|---|---|---|
| Prompt Library | Oracle prompt spaces that can be searched or pulled into a profile | [Prompt Library](https://prompts.oracle.com), [AI ChatGPT Prompt Library](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=20197164379) | Requires `AIPACK_PROMPTLIB_API_KEY` for `aipack prompt-lib` commands |
| ORA skills | ORA-managed skill catalog/installer surface for ORA runtimes | [Oracle Runs Agents](https://internal-docs.oraclecorp.com/iaas/internalcontent/ai/ora-landing.htm), `ora --version-cli`, `ora --help` | Verify the live ORA version exposes `ora skills`; ORA-owned installs are not AIPack profile sync |
| AI Skills Registry | Oracle skill catalog/user guide | [AI Skills Registry User Guide](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19250903696) | Separate catalog; not automatically installed by AIPack |
| OCI Skills Hub | OCI skill hub/reference surface | [OCI Skills Hub](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19534273766) | Verify current install path before recommending |

## Catalog Model

Use this model when explaining how discovery surfaces relate:

- `catalog/governance`: PromptLib, Skills Hub / AI Skills Registry, Codex plugin marketplace, team registries, and owner docs.
- `install/distribution`: native PromptLib skill installs, ORA installs, Codex/Claude plugins, app connector catalogs, MCP Gateway, and AIPack pack installs.
- `local composition/update`: AIPack profiles, pack registries, lockfile state, `content_paths`, sync, and update checks.

AIPack is not the Oracle marketplace. It is the local composition and sync layer for packs, MCP config, prompts, workflows, rules, and multi-harness profiles. Native catalogs and plugin/app surfaces remain first-class when they are the owning install path.

## Overlap And Dedupe Rules

- Prefer a full registered pack when the same repo/path also appears as a skill-only source or catalog item.
- Treat PromptLib, ORA skills, AI Skills Registry, and OCI Skills Hub as correlation surfaces until they expose a backing repo, artifact, owner, and install path.
- Do not add a non-pack registry entry from a catalog listing alone. Find the backing git source first, then check `registry.yaml` for an existing full pack.
- Report overlap as part of discovery output: `canonical source`, `also seen in`, and `recommended action`.

## Tool And Connector Surfaces

| Surface | What It Is | Start Here | AIPack Role |
|---|---|---|---|
| Pack-shipped MCP servers | Local harness MCP config rendered from this pack | `skills/installing-mcp-servers/*.md` recipes | AIPack renders config; recipes handle setup/auth |
| MCP Gateway | Runtime-managed tool access plane | [MCP Gateway - Customer Setup Guide](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19620167709), [Bring Your Own MCP For Dev Plat Gateway / MCP Gateway](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=20325026819) | Do not duplicate gateway wiring in this pack |
| Codex Enterprise apps/connectors | Workspace-approved connectors such as Slack, Outlook, SharePoint, and other catalog apps | [Connect Oracle Apps in ChatGPT Cloud Portal](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=20494382299), [Using ChatGPT Apps in Codex](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=20034815486), [ChatGPT Apps Approval Process](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19847084497), [chatgpt.com/apps](https://chatgpt.com/apps) | Adjacent to AIPack; connect through Enterprise catalog, not `aipack sync` |

## Access Prerequisites

- Internal Confluence links require Oracle SSO and the right space permissions; if a link returns denied or missing, ask the user for an owner-approved alternate link instead of searching broadly.
- PromptLib CLI commands require a VIEW_ONLY key from [Prompt Library](https://prompts.oracle.com) under Profile -> Preferences -> API Keys; set it locally with `aipack config env set AIPACK_PROMPTLIB_API_KEY <key>`.
- ORA skills require a local ORA version that exposes the `skills` command. If `ora skills --help` reports the version does not support skills/sandbox, update ORA or ask in [#devplat-ai-support](https://oracle.slack.com/archives/C0AN1P13YHF).
- Codex Enterprise apps/connectors require the Oracle Enterprise workspace and catalog approval; connect apps at [chatgpt.com/apps](https://chatgpt.com/apps), then restart or reopen the Enterprise Codex/ChatGPT session.
- Deep pack discovery may require `aipack registry fetch --deep`; run it only after the user approves the exact mutation.

## Support And Troubleshooting

Use `skills/oracle-ai-orientation/references/oracle-ai-source-map.md` when the user asks where to get help, how the Oracle/OCI/Platform AI ecosystem fits together, or what to search after a setup failure.

Primary support channels:

- [#aipack-community](https://oracle.slack.com/archives/C0AMKPYD7K3) for AIPack install, profile, pack, sync, and registry support.
- [#help-codex](https://oracle-one.slack.com/archives/C0ARJM4AL30) for Codex runtime and Enterprise app visibility issues.
- [#oracle-code-assist-users](https://oracle.slack.com/archives/C06KDB1Q495) for Oracle Code Assist / OCA user support.
- [#devplat-ai-support](https://oracle.slack.com/archives/C0AN1P13YHF) for Dev Platform AI and MCP Gateway support.
- [#dev-mcp-skills](https://oracle-one.slack.com/archives/C09DQ8X2SEA) for MCP/skills development questions.
- [#promptlib-int](https://oracle.slack.com/archives/C08QHSVJQ7R) for PromptLib integration and API key questions.

Search exact error text in the likely owner channel before posting a new question. If the answer comes from Slack, look for a durable Confluence, internal-docs, source-repo, or pack reference before treating it as final guidance.

## MCP Server Recipes

Use local recipes first because they pair this pack's MCP JSON with the current package source and auth model:

- `skills/installing-mcp-servers/jira.md`
- `skills/installing-mcp-servers/jira-sd.md`
- `skills/installing-mcp-servers/confluence.md`
- `skills/installing-mcp-servers/bitbucket.md`
- `skills/installing-mcp-servers/dope.md`
- `skills/installing-mcp-servers/oci-mcp.md`
- `skills/installing-mcp-servers/oci-kb.md`
- `skills/installing-mcp-servers/ots.md`
- `skills/installing-mcp-servers/oci-ops.md`

If a recipe and external page conflict, trust the pack recipe for this pack's rendered command and trust the external page for current credential issuance or service ownership. Report the conflict instead of merging the instructions.
