---
name: oracle-ai-orientation
description: Use when orienting OCI users to AI work at Oracle/OCI/Platform, troubleshooting first-run setup, or deciding where to search next across AIPack, Codex/OCA, MCP Gateway, PromptLib, Confluence, Slack, apps/connectors, and team packs.
metadata:
  owner: platform_org
  last_updated: 2026-05-20
---

# Oracle AI Orientation

Orient OCI/Platform users and their agents to the right Oracle AI surface, failure class, and next source. This skill does not install packs, set secrets, sync harnesses, or mutate connected apps by itself.

## References

| Reference | Use when |
|---|---|
| [oracle-ai-source-map.md](references/oracle-ai-source-map.md) | The user asks what exists, where to get help, which docs/channels matter, or where an unknown issue should be searched next |
| [common-first-run-failures.md](references/common-first-run-failures.md) | AIPack, Codex/OCA, MCP, PromptLib, app/connector, registry, or bootstrap setup behaves unexpectedly |

## First Actions

1. Start from current evidence: profile, harness, scope, command, exact error text, visible tool/app/MCP state, and what changed recently.
2. If invoked from `/onboard`, keep the user-facing output compact and load only the reference sections needed for observed gaps.
3. Classify the issue into one lane before recommending action.
4. Use owner-maintained docs and source repos for durable instructions; use Slack for current support signals and owners.
5. When a fact affects a decision, cite the source surface and say whether it was verified from source/docs, inferred from diagnostics, or reported by a support channel.

## Lane Classifier

| Lane | Typical signal | First route |
|---|---|---|
| Engineering guardrails | PR, CM, release, incident, security, customer impact, compliance | AI Best Practices / policy sources; require human ownership and evidence |
| AIPack setup | `aipack` command, pack/profile/sync/registry/update behavior | `aipack version`, `aipack status --profile <profile> --json`, `aipack profile refs <profile> --json`, `aipack doctor --profile <profile> --json` |
| Pack content discovery | "What skills/packs/prompts exist?" | `content-discovery`, registry commands, PromptLib, Skills Hub, source map |
| Runtime/harness | Codex/OCA/ORA/OpenCode loading mismatch | `oca-harness-setup` and runtime config-plane reference |
| Tool access/MCP | Jira, Confluence, Bitbucket, DOPE, OCI, OTS, gateway tools | `installing-mcp-servers`, named-server probe, MCP Gateway docs |
| Enterprise apps/connectors | Slack, Outlook, SharePoint, ChatGPT app catalog, `/apps` | ChatGPT apps docs and `https://chatgpt.com/apps`; treat as Enterprise app catalog, not AIPack sync |
| Prompt sources | PromptLib auth/search/pull/publish | PromptLib docs and `AIPACK_PROMPTLIB_API_KEY` setup |
| Memory/prior context | User references a prior run, recurring failure, local convention, or known issue | Search active memory surfaces when available; verify any fix against docs/source before treating it as durable |
| Team context | Service runbooks, on-call flows, team repos, team pack choice | Registry owner/contact, team Confluence, team Slack, service owner |
| Unknown | User is stuck or asks "what is this doing?" | Load source map, search exact error, then pick one next source and one next command |

## Troubleshooting Contract

- Never ask the user to self-diagnose before checking the pack references and the relevant owner-maintained docs.
- Do not treat "installed" as "ready": confirm profile membership, setup values, rendered harness config, runtime loading, auth, and fresh-session state separately.
- Do not run broad live probes during first-run onboarding. Probe the named failing server, app, command, or source.
- Do not print secret values. Preserve key names, missing/present state, command shape, and redacted error text only.
- Do not recommend unvetted team packs for install. Present them as discoverable and inspect owner/contact/source before adoption.
- Do not duplicate MCP Gateway or Enterprise app wiring in AIPack. Route missing gateway/apps to their runtime/catalog owners.

## Search Playbooks

For an unknown setup issue:

1. Search local pack references first: this skill, `content-discovery`, `installing-mcp-servers`, `oca-harness-setup`.
2. Search active memory surfaces when they are available, using the exact error or command; treat memory as a clue until it points to docs, source, or live evidence.
3. Search exact error text in Confluence and Slack.
4. Search by command and pack name, for example `aipack sync old settings`, `oci-dev-starter-pack no packs configured`, `Codex apps not showing`.
5. Search the owning channel from the source map or registry metadata before posting a new question.
6. If the answer comes from Slack, look for a durable doc/source link before treating it as final guidance.

For an unknown capability request:

1. Decide whether the user needs a runtime/tool, a pack/skill/workflow, a prompt, a connector app, or team-specific context.
2. Search the matching catalog only; do not imply AIPack, PromptLib, Skills Registry, apps, and MCP Gateway are unified.
3. Report overlap explicitly when the same domain appears in multiple sources.
4. Recommend install/connect/pull only after source, owner, maturity, auth, and mutation surface are clear.

## Output Contract

Return:

- `TL;DR` - current lane, what is likely happening, and the single next check.
- `Evidence` - exact command/error/source surface used, value-free.
- `Where to look next` - 1-3 authoritative docs, source repos, or channels.
- `Action` - exact read-only command or mutation-gated command shape.
- `Escalate when` - the owner channel or doc path when the agent cannot verify locally.

## Verify

- The answer names the owning lane before recommending a fix.
- First-run output stays compact unless the user asks for details.
- Unknowns route to Confluence, Slack, registry metadata, source repos, or owner docs instead of becoming guesses.
- No secret value, env-file content, or resolved `profile show --json` output is included.
