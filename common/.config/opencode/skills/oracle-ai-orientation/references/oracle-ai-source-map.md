---
name: oracle-ai-source-map
description: Source map for Oracle/OCI/Platform AI setup, support, discovery, runtime, tool access, and escalation paths
metadata:
  owner: platform_org
  last_updated: 2026-05-20
---

# Oracle AI Source Map

Use this map when an OCI user or agent needs orientation, source links, support channels, or the next place to search. Prefer owner-maintained sources over copied instructions.

## First-Run And AIPack

| Need | Start here | Use it for |
|---|---|---|
| OCI Platform bootstrap | [10-Minute AI Bootstrap for OCI Platform Engineers](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=20467814861) | Current Platform first-run command path and baseline-pack framing |
| AIPack install/troubleshooting | [aipack CLI: Installation & Troubleshooting](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19636421571) | CLI install, setup, update/sync vocabulary, registry fallback, known setup fixes |
| AIPack overview | [AIPack Jump Page](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=20216486635) | Entry point for AIPack docs |
| AIPack model | [aipack: How It Works](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19409661826) | Packs, profiles, sync, harness rendering |
| Team pack authoring | [aipack: Building Your Team Pack](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=20090898647) | Team-owned context and pack creation |
| Starter source | [OCICM / oci-packs](https://bitbucket.oci.oraclecorp.com/projects/OCICM/repos/oci-packs/browse) | Registry, `oci-dev-starter-pack`, source of pack content |
| Shared starter source | [TENLS / dev-starter-skills](https://bitbucket.oci.oraclecorp.com/projects/TENLS/repos/dev-starter-skills/browse) | Shared `dev-starter` content and starter workflows |

## Guardrails And Policy

| Need | Start here | Use it for |
|---|---|---|
| Engineering AI guardrails | [AI Best Practices and Guardrails for Engineer-Led Adoption](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=20421404083) | Human accountability, validation, PR/CM/release/incident boundaries |
| Corporate policy | [Corporate Architecture AI Policy Home](https://oracle.sharepoint.com/sites/corporatearchitecture/SitePages/Corporate-Architecture-AI-Policy-Home.aspx) | Policy, approval, restricted data, preferred/banned services |
| AI usage approvals | [AI and ML Usage and Approvals](https://oracle.sharepoint.com/sites/corporatearchitecture/SitePages/AI-and-ML-Usage-and-Approvals.aspx) | Approval routing and usage boundaries |
| AI for Engineering | [AI for Engineering](https://oracle.sharepoint.com/sites/ai-for-engineering) | Employee-facing engineering AI enablement |

## Runtime And Tool Access

| Need | Start here | Use it for |
|---|---|---|
| OCI AI developer docs | [AI for Developers](https://internal-docs.oraclecorp.com/iaas/landing_ai.htm) | Day-to-day OCI AI developer entry point |
| Codex setup | [Codex](https://internal-docs.oraclecorp.com/iaas/internalcontent/ai/getting-started-with-codex.htm), [OCA Codex CLI / Desktop / IDE instructions](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19169719016) | Codex/OCA runtime setup |
| MCP Gateway | [MCP Gateway](https://internal-docs.oraclecorp.com/iaas/internalcontent/ai/mcp-gateway.htm), [MCP Gateway Setup](https://internal-docs.oraclecorp.com/iaas/internalcontent/ai/mcp-setup.htm), [MCP Servers Available with Codex](https://internal-docs.oraclecorp.com/iaas/internalcontent/ai/mcp-servers-for-codex.htm) | Runtime-owned tool access and gateway troubleshooting |
| BYO gateway details | [Bring Your Own MCP For Dev Plat Gateway / MCP Gateway](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=20325026819) | Gateway extension path and ownership |
| ORA | [Oracle Runs Agents](https://internal-docs.oraclecorp.com/iaas/internalcontent/ai/ora-landing.htm), `ora --version-cli`, `ora --help` | ORA runtime/sandbox/operator path and ORA skills when the live CLI exposes `ora skills` |
| Agent Memory MCP | [Agent Memory MCP](https://internal-docs.oraclecorp.com/iaas/internalcontent/ai/agent-memory-mcp.htm) | Runtime memory/tooling surface, separate from pack content |
| SKS | [SKS Overview](https://internal-docs.oraclecorp.com/iaas/internalcontent/ai/sks-overview.htm) | Shared knowledge store context |

## Catalogs And Content Discovery

| Need | Start here | Use it for |
|---|---|---|
| Pack registry | `aipack registry list --json`, `aipack search --available --kind pack --json` | Installable packs and owner/contact metadata |
| Non-pack registry | `aipack registry list --json` entries with `content_paths` | Skill-only or content-slice sources |
| PromptLib | [Prompt Library](https://prompts.oracle.com), [AI ChatGPT Prompt Library](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=20197164379) | Prompts and PromptLib-backed pull/search |
| ORA skills | [Oracle Runs Agents](https://internal-docs.oraclecorp.com/iaas/internalcontent/ai/ora-landing.htm), `ora skills --help` | ORA-managed skill catalog/installer surface; verify backing source before treating as distinct content |
| AI Skills Registry | [AI Skills Registry User Guide](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19250903696) | Oracle skill catalog and registry UI |
| OCI Skills Hub | [OCI Skills Hub](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19534273766) | OCI skill hub/reference surface |
| AI tool catalog | [AI Developer Productivity Tools](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=15555233949), [AI Tool Catalog](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=15555234004), [Oracle AI Tools Reference](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=20324549585) | Discovery only; verify owner/maturity before adoption |

## Memory And Prior Context

| Need | Start here | Use it for |
|---|---|---|
| Local durable memory | Optional `memory` pack or configured memory-bank surface | Prior local setup issues, user preferences, project decisions, and known gotchas |
| Runtime memory | [Agent Memory MCP](https://internal-docs.oraclecorp.com/iaas/internalcontent/ai/agent-memory-mcp.htm) | Runtime-owned memory/context surface, separate from pack content |
| Support history | Slack search and Confluence page history | Recently discovered failures, owner answers, and fixes waiting to be documented |

Search memory with exact errors and commands. Treat memory as routing evidence, not authority, unless it points to a current source page, source repo, or reproducible diagnostic.

## Apps And Connectors

| Need | Start here | Use it for |
|---|---|---|
| Connect Enterprise apps | [chatgpt.com/apps](https://chatgpt.com/apps), [Connect Oracle Apps in ChatGPT Cloud Portal](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=20494382299) | Connecting Oracle-approved catalog apps |
| Apps in Codex | [Using ChatGPT Apps in Codex](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=20034815486) | Understanding how connected ChatGPT apps appear in Codex |
| App approval | [ChatGPT Apps Approval Process](https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19847084497) | Missing or unapproved connector path |

Treat Slack, Outlook, SharePoint, Oracle Central Confluence, OCI Jira, and similar Enterprise apps as adjacent connector surfaces. Do not try to install them with `aipack sync`.

## Support Channels

Use Slack for current support signals, ownership, and live incidents. Convert durable fixes into docs or pack content after verification.

| Channel | Use when |
|---|---|
| [#aipack-community](https://oracle.slack.com/archives/C0AMKPYD7K3) | AIPack install, profiles, packs, sync, registry, starter-pack support |
| [#help-codex](https://oracle-one.slack.com/archives/C0ARJM4AL30) | Codex Native / Enterprise app visibility / Codex runtime issues |
| [#oracle-code-assist-users](https://oracle.slack.com/archives/C06KDB1Q495) | Oracle Code Assist and OCA user support |
| [#devplat-ai-support](https://oracle.slack.com/archives/C0AN1P13YHF) | Dev Platform AI and MCP Gateway support |
| [#dev-mcp-skills](https://oracle-one.slack.com/archives/C09DQ8X2SEA) | MCP/skills development and gateway-adjacent questions |
| [#promptlib-int](https://oracle.slack.com/archives/C08QHSVJQ7R) | PromptLib integration and API key questions |
| [#oci-platform-ai-garage](https://oracle.slack.com/archives/C09D5MTQ013) | Platform AI adoption discussion and emerging patterns |
| [#foundational-platform-svcs-ai-adoption](https://oracle.slack.com/archives/C09EQ0947K2) | Platform services adoption threads and team-specific starter issues |

## Search Patterns

Confluence:

- Search exact page titles first when known.
- Search exact command plus symptom, for example `aipack sync old skills`, `AIPack no packs configured`, `Codex apps not showing`.
- Use source owners and last-updated dates when two pages disagree.

Slack:

- Search exact error text in the likely owner channel first.
- Search `<tool> <command> <symptom>` across support channels when no owner is obvious.
- Read the thread before summarizing; the first answer is often superseded later.
- Treat Slack as a pointer to current state, not the final source for policy or setup docs.

Registry/source repos:

- Inspect owner/contact/source before recommending install.
- Prefer `aipack pack inspect <pack> --json` only after user approval when invoked from `/onboard`.
- Use source README and `pack.json` to identify MCP, scripts, configs, and mutation surfaces.
- Check whether a catalog item from PromptLib, ORA skills, AI Skills Registry, or OCI Skills Hub points to a repo/path already present as a full pack before recommending a non-pack source.

## Verification Discipline

- Verify CLI flags with current `aipack --help` or source before publishing commands.
- Verify UI/app claims against the relevant owner docs or live app listing.
- Verify pack freshness from `~/.config/aipack/aipack.lock` and source when installed behavior looks stale.
- If a source is unavailable or access-denied, say which source was blocked and route to its owner channel.
