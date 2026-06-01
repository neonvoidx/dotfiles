---
name: onboard
description: First-run onboarding - inspect the target profile, introduce the ecosystem, offer support packs, discover content, and collect diagnostics
metadata:
  owner: platform_org
  last_updated: 2026-05-20
---

# /onboard

Orient a user who installed `oci-dev-starter-pack` and `dev-starter` into their own default or named profile. Inspect first, explain what is present, introduce the ecosystem, offer support packs, collect diagnostics, and introduce content discovery.

## Scope

- Resolve the default profile, harness, and scope first; ask once before switching to a different target.
- Do not copy, switch to, or promote bundled `dev-readonly` / `dev-elevated` profiles unless the user explicitly asks for examples.
- Do not recommend unvetted OCI or team packs for install. Show them as discoverable content with owner/contact metadata.
- Do not create commits, write secrets, edit harness-managed output directly, or overwrite user configuration.
- Route detailed failures to existing skills: `aipack-system` for profile/sync/config, `installing-mcp-servers` for MCP install/startup, `oca-harness-setup` for OCA harness-specific issues, `content-discovery` for registry, PromptLib, ORA skills, Skills Hub, Codex Enterprise apps/connectors, or non-pack source exploration, and `oracle-ai-orientation` for Oracle/OCI/Platform source routing and common first-run failure patterns.

## Inputs

- Profile: optional. Default: sync-config `defaults.profile`, then `default`.
- Harness: optional. Default: sync-config `defaults.harnesses`.
- Scope: optional. Default: sync-config `defaults.scope`, then `global`.
- Deep discovery: optional local cache/index mutation. Default: no.
- Support packs: recommended `aipack-core`; optional `essentials` and `memory`.

## Output Shape

Use this structure for the user-facing response:

1. `TL;DR` - what this workflow is doing, the current state, and the single recommended next step.
2. `Your setup` - profile, harness, scope, active baseline packs, support packs.
3. `Needs attention` - aipack update, missing params/env refs, auth/session issues, harness/config-plane mismatches.
4. `Available surfaces` - pack layers, MCP/tool surfaces, and adjacent catalogs summarized in short groups.
5. `Optional follow-ups` - content discovery, tool/auth smoke test, or team-pack exploration.

Default to compact output: no more than 12 bullets unless the user asks for detail. Do not paste raw command JSON into the final response. Summarize counts, names, owners, missing keys, and next commands. Never include resolved env values.

## Mutation Gate

Stop and ask for explicit confirmation before these local mutations:

- `aipack pack install <pack> --add --profile <profile>`
- `aipack pack add <pack> --profile <profile>`
- `aipack registry fetch --deep`
- `aipack pack inspect <pack> --json`
- `aipack prompt-lib refresh`
- `aipack prompt-lib pull <space-id> --add --profile <profile>`
- `aipack profile set-param <profile> <key> <value>`
- `aipack config env set <key> <value>`
- `aipack sync --profile <profile> --harness <harness> --scope <scope>`
- `aipack sync --profile <profile> --harness <harness> --scope <scope> --force --yes`

Never ask the user to paste secrets into chat. For secret values, tell them to set the value locally with `aipack config env set <key> <value>` or their shell secret manager.

## Steps

### 1. Resolve Target Context

1. Run `aipack version`.
2. If `aipack version` fails, an `aipack` command reports an update notice, or a later command fails because a subcommand or flag is unknown, make `aipack update` the TL;DR recommended next step and stop normal onboarding until the user updates and reruns `/onboard`.
3. Before diagnostics, tell the user in one sentence: `/onboard` checks the active profile, confirms starter packs, finds setup gaps, and recommends the next action; it will not change files, install packs, set secrets, or sync unless they approve a `MUTATION`.
4. Run `aipack config defaults get profile`.
5. Run `aipack config defaults get harnesses`.
6. Run `aipack config defaults get scope`.
7. Run `aipack profile list`.
8. Explain the short target model before asking for overrides: profile selects packs/resources/params/MCP/tool exposure; harness selects the target client config; scope selects global or project render destination.
9. Ask whether to continue with the resolved defaults or use a named profile, harness, or scope. If the user does not override, set `<profile>`, `<harness>`, and `<scope>` to the resolved defaults.
10. If the user names target values, set `<profile>`, `<harness>`, and `<scope>` from the response; validate the profile by running `aipack status --profile <profile> --json` before continuing.
11. Run `aipack status --profile <profile> --json`.
12. Run `aipack profile refs <profile> --json`.
13. Run `aipack pack list --json`.
14. Record the target profile name, harness list, scope, installed packs, active pack list, and target resource counts.

### 2. Check Bootstrap Baseline

1. Confirm the target profile includes `oci-dev-starter-pack`.
2. Confirm the target profile includes `dev-starter`.
3. If either baseline pack is missing, label `MUTATION` and ask before running `aipack pack install <missing-pack> -w all --add --profile <profile>`.
4. If a baseline pack is installed but not active in the profile, label `MUTATION` and ask before running `aipack pack add <missing-pack> --profile <profile>`.
5. If the profile uses a bundled `dev-readonly` or `dev-elevated` name, continue inspection; do not switch profiles.

### 3. Explain The Target Ecosystem

1. Summarize the target profile as the user's composition surface.
2. Summarize pack layers: `oci-dev-starter-pack` as the OCI tooling/MCP baseline, `dev-starter` as shared operational skills/workflows/agents, optional support packs as debugging and collaboration infrastructure, and team packs as later team-specific context.
3. Summarize target resources by kind: rules, skills, workflows, agents, prompts, MCP servers, configs, and extras.
4. Explain that profiles control composition and tool exposure; packs are reusable content bundles.
5. Explain that bundled profiles are examples, not the preferred first-run editing surface.
6. Invoke `oracle-ai-orientation` in compact setup mode with the profile, harness, scope, status summary, refs summary, installed packs, and any setup gaps. Use it to pick relevant source surfaces; do not expand the final response beyond the Output Shape budget.

### 4. Offer Support Packs

1. If `aipack-core` is not active in the profile, explain that it fills the setup/debug gap with `aipack-system`, `agent-configuration`, `pack-content-craft`, and pack validation rules.
2. If `aipack-core` is installed but not active, label `MUTATION` and ask before running `aipack pack add aipack-core --profile <profile>`.
3. If `aipack-core` is not installed, label `MUTATION` and ask before running `aipack pack install aipack-core --add --profile <profile>`.
4. Offer `essentials` as an optional engineering-workflow pack; do not install unless the user explicitly approves `aipack pack install essentials --add --profile <profile>` or `aipack pack add essentials --profile <profile>`.
5. Offer `memory` as an optional persistence/knowledge-routing pack; do not install unless the user explicitly approves `aipack pack install memory --add --profile <profile>` or `aipack pack add memory --profile <profile>`.
6. If any support pack add/install runs, set `<profile_changed>` to `true`.
7. Defer sync dry-run and real sync to Step 8 so all approved profile changes are reviewed together.

### 5. Run Setup Diagnostics

1. Run `aipack setup <profile>`.
2. If `<profile_changed>` is `true`, run `aipack profile refs <profile> --json`; otherwise reuse the refs collected in Step 1.
3. Run `aipack doctor --profile <profile> --json`.
4. Classify setup and doctor output using `skills/installing-mcp-servers/references/mcp-startup-triage.md` for MCP failures.
5. For `missing-param`, report the exact `aipack profile set-param <profile> <key> <value>` command and require confirmation before running it.
6. For `missing-env`, report the key name and local command shape `aipack config env set <key> <value>`; do not collect the value in chat.
7. For `pack-profile-sync`, invoke `aipack-system` when available; otherwise keep using `aipack status --profile <profile>`, `aipack profile refs <profile>`, `aipack setup <profile>`, `aipack doctor --profile <profile>`, `aipack sync --profile <profile> --harness <harness> --scope <scope> --dry-run`, and `aipack trace`.
8. For `harness-loading`, invoke `oca-harness-setup` with the profile, harness, scope, and failing target path.
9. For `runtime-config-plane`, invoke `oca-harness-setup` and load `references/runtime-config-planes.md`; compare aipack-rendered config with runtime-managed config before changing pack or profile content.
10. For unknown or cross-surface failures, invoke `oracle-ai-orientation` and load `references/common-first-run-failures.md` before asking the user to troubleshoot manually.

### 6. Route MCP Failures

1. Skip this step when setup and doctor found no MCP failure and the user did not request an MCP smoke test.
2. Run `aipack mcp inspect-tools --profile <profile>` to list static inventory.
3. For each failing server, run `aipack mcp inspect-tools <server> --profile <profile>`.
4. If `<harness>` is `codex`, `all`, or a list containing `codex`, run `rg -n "MCP server stderr|Traceback|No such file or directory|AttributeError|failed" ~/.codex/log/codex-tui.log -S`.
5. Invoke `installing-mcp-servers` with the target context, setup/doctor snippets, named-server probe result, and redacted log excerpt.

### 7. Introduce Content Discovery

1. Invoke `content-discovery` in `source-tour` mode with profile, harness, scope, status summary, refs summary, installed pack list, and any user-provided topic.
2. Require `content-discovery` to load `references/source-guide.md` for the source tour without running live registry, PromptLib, or browser catalog commands.
3. If the user asks where to get help, how Oracle/OCI/Platform AI surfaces fit together, or what to search when a failure is not locally explained, invoke `oracle-ai-orientation` with `references/oracle-ai-source-map.md`.
4. If the user asks for topic search, catalog search, source links, or deep discovery, follow `content-discovery` for commands and mutation gates.
5. Do not install, inspect, refresh, pull, or connect anything until the user approves the exact action.

### 8. Sync Readiness

1. Run `aipack sync --profile <profile> --harness <harness> --scope <scope> --dry-run`.
2. Review planned writes, warnings, duplicate-resource conflicts, unresolved refs, and harness targets.
3. If the dry-run is clean and the user wants the changes applied, label `MUTATION` and ask before running `aipack sync --profile <profile> --harness <harness> --scope <scope>`.
4. Use `aipack sync --profile <profile> --harness <harness> --scope <scope> --force --yes` only after naming the exact files that would be overwritten and receiving explicit approval.
5. After sync, tell the user which harnesses need restart because sync wrote rules, settings, MCP config, or harness config.

### 9. Final Output

1. Start with `TL;DR`: one sentence for what `/onboard` did and one `Recommended next step`.
2. If AIPack is out of date or a command/flag is unavailable, make `aipack update` the only recommended next step.
3. Report target profile, harnesses, scope, active baseline packs, and support-pack decisions in at most 4 bullets.
4. Report missing params/env vars without secret values.
5. Report MCP status only for servers that need attention; do not list every ready server unless the user asks.
6. Report the source tour and any requested discovery results as grouped source surfaces, not a full catalog dump.
7. Give at most 2 optional follow-up prompts after the single recommended next step.

## Done When

- The user understands their target profile and pack layers.
- Missing setup values and MCP failures have concrete next checks or routed skills.
- Support-pack install/add choices have been offered without forcing bundled profiles.
- Registry, PromptLib, ORA skills, Skills Hub, Codex Enterprise apps/connectors, and non-pack registry sources have been introduced as distinct discovery surfaces.
- Oracle/OCI/Platform AI source routing and common first-run failure paths are available to the agent without dumping them into the default output.
