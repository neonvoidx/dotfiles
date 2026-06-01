---
name: content-discovery
description: Use when onboarding OCI users to available packs, registry entries, PromptLib spaces, ORA skills, Skills Hub / AI Skills Registry, Codex Enterprise apps/connectors, or non-pack content sources after installing OCI starter packs.
metadata:
  owner: platform_org
  last_updated: 2026-05-20
---

# Content Discovery

Help users discover usable agent content and adjacent connector surfaces after `oci-dev-starter-pack` and `dev-starter` are installed in their own profile. Start with orientation, then search. Keep recommendations separate from inventory: the starter path recommends the baseline packs plus `aipack-core`; other OCI and team packs are discoverable until vetted. Use `oracle-ai-orientation` when the user needs support routes, source links, or failure-mode guidance rather than catalog inventory.

## First Response Shape

When invoked from `/onboard`, produce a compact map before offering discovery actions:

- `current setup` - profile, harness, scope, active baseline packs, support packs.
- `pack content` - rules, skills, workflows, agents, prompts, MCP servers, configs, extras.
- `tool surfaces` - pack-rendered MCP servers, Codex Enterprise apps/connectors, MCP Gateway when visible.
- `content catalogs` - registered packs, non-pack `content_paths`, PromptLib, ORA skills, Skills Hub / AI Skills Registry.
- `setup gaps` - missing params, missing env refs, missing PromptLib key, auth/session gaps.
- `next actions` - inspect, connect, refresh, pull, install, or sync; mutation-gated when required.

Do not dump raw JSON in the user-facing response. Summarize source, status, owner/contact, and the next command to run.

## Invocation Modes

- `source-tour` - load `references/source-guide.md`, explain the available source surfaces, and use only `/onboard` evidence; do not run live catalog, PromptLib, registry fetch, browser, install, inspect, pull, or sync commands.
- `topic-search` - search the relevant live surfaces for a user-named task, tool, team, service, or content type; run only the read commands listed in this skill unless a mutation gate is approved.
- `deep-discovery` - refresh or inspect local catalogs after the user approves the exact mutation command; report what changed in the cache or profile.
- `setup-gap` - map missing keys, auth/session failures, and connector visibility gaps to the owning surface; do not recommend new content until the current setup gap is named.

## References

Load [references/source-guide.md](references/source-guide.md) for `/onboard` source-tour mode and when the user asks what sources exist, where to start, or why a source is not handled by AIPack.

If the user asks where to get help, what to search next, how Oracle/OCI/Platform AI surfaces relate, or why setup failed, invoke `oracle-ai-orientation` and use its source map/failure map before expanding discovery.

## Evidence To Collect Safely

- Use target profile, harness, scope, status summary, refs summary, installed pack list, and topic when `/onboard` provides them.
- In `source-tour` mode, do not collect additional live evidence; use the supplied `/onboard` evidence and the curated source guide.
- Run `aipack status --profile <profile> --json` only when active pack/resource inventory is missing.
- Run `aipack profile refs <profile> --json` only when param/env requirements are missing.
- Run `aipack registry sources --json`, `aipack registry list --json`, or `aipack search --available --kind pack --json` only for a catalog/discovery request.
- Run `aipack prompt list`, `aipack prompt-lib list`, or `aipack prompt-lib search <query>` only for prompt or PromptLib discovery.
- Run `ora --version-cli` and `ora --help` before using ORA as a skills source. Run `ora skills --help` or `ora skills list` only when the local ORA version exposes a `skills` command; if it does not, report ORA as version-blocked and route to `#devplat-ai-support`.

When the user names a topic, search each relevant surface separately. Do not imply the catalogs are unified.

Never use `aipack profile show --json` for discovery output; it fully resolves environment-backed MCP values. If another tool output includes env values, discard the values and keep only key names and missing/present state.

## Source Classes

| Source | What To Say | Primary Commands |
|---|---|---|
| Active packs | Already loaded into the target profile after sync. | `aipack status --profile <profile> --json` |
| Registered packs | Installable or inspectable bundles with profiles, rules, skills, workflows, MCP, configs, prompts, or extras. | `aipack registry list --json`, `aipack search --available --kind pack --json` |
| Non-pack registry entries | Skills-only or content-slice sources exposed through `content_paths`; they may overlap with full packs. | `aipack registry list --json` |
| PromptLib | Oracle prompt spaces that can be listed, searched, refreshed, or pulled into a profile after approval. | `aipack prompt-lib list`, `aipack prompt-lib search <query>` |
| ORA skills | ORA-managed skills exposed by the live ORA CLI/catalog; some may be backed by another source. | `ora --version-cli`, `ora --help`, `ora skills --help`, `ora skills list` |
| Skills Hub / AI Skills Registry | Separate Oracle skill catalogs; use direct links from the bootstrap guide or user-provided URLs. | Browser or documented registry UI |
| Codex Enterprise apps/connectors | Workspace-approved connectors that add tools or context outside AIPack, adjacent to pack-shipped MCP servers. | `https://chatgpt.com/apps` and the Oracle-approved app catalog |
| Team-local repos | Team-owned pack or skill sources; require owner/contact review before install. | Registry metadata, repo README, or owner docs |
| Support and troubleshooting sources | Owner-maintained Confluence/internal docs plus Slack support channels for current failure signals. | `oracle-ai-orientation` source map and exact-error searches |

## Overlap Guard

Before recommending, installing, or adding a discovered item:

1. Identify its backing source: full pack name/repo/path, non-pack repo/path, PromptLib space/id, ORA catalog/source, Skills Registry/Hub id, app connector, or unknown.
2. If the same repo/path has a full pack in the registered pack registry, prefer the full pack and mark the non-pack or catalog item as a duplicate surface.
3. Treat PromptLib, ORA skills, Skills Hub, and AI Skills Registry as correlation surfaces unless they expose a distinct backing repo or installable artifact with owner/contact metadata.
4. Do not add or recommend a non-pack registry source from a catalog listing alone. Find the backing git source first, then check whether it is already a full pack.
5. Include overlap notes in the output when the same team, domain, or repo appears in multiple surfaces.

## Apps And MCP Servers

AIPack installs pack content and renders MCP server config for local harnesses. Codex Enterprise apps/connectors are connected through the ChatGPT app catalog instead; they are not installed, synced, or rendered by this pack.

When users need Slack, Outlook, SharePoint, or another approved enterprise connector, route them to `https://chatgpt.com/apps` and have them connect the Oracle-approved app from the catalog. If a connector is missing or unavailable, treat it as an Enterprise workspace/app-catalog issue, not an MCP install failure.

After the user connects an app, tell them to restart or reopen the Enterprise Codex/ChatGPT session before expecting the connector tools to appear. Local harness sync will not make Enterprise apps appear.

## Topic Search

Use this routing when the user gives an interest area:

| User Need | Search First | Then |
|---|---|---|
| "I need a pack for my team/service" | `aipack search <terms> --kind pack --json` | Inspect owner/contact and install only after approval |
| "I need a skill/workflow for a task" | `aipack search <terms> --json` | Check active/full-pack results before non-pack and catalog surfaces |
| "I need prompts/examples" | `aipack prompt list`, `aipack prompt-lib search <query>` | Refresh PromptLib only after approval |
| "I need Slack/Outlook/SharePoint context" | Codex Enterprise app catalog | Connect the Oracle-approved app; do not install an MCP server unless no approved connector exists |
| "I need internal OCI tools" | Active MCP inventory and starter-pack server recipes | Use `installing-mcp-servers` for setup/auth failures |
| "I need authoritative internal docs" | `oci-kb`, PromptLib, registry search | Report provenance and freshness separately |
| "I need ORA skills" | `ora --version-cli`, `ora --help`, then `ora skills --help` if exposed | Report version-blocked ORA separately from missing AIPack content |
| "I am stuck / what should I search next?" | `oracle-ai-orientation` source map and common failure map | Search exact error in the owner docs/channel before recommending new content |

## PromptLib Auth

If `aipack prompt-lib list` or `aipack prompt-lib search <query>` fails for auth, tell the user to create a VIEW_ONLY API key in Prompt Library (`prompts.oracle.com` -> Profile -> Preferences -> API Keys) and set it locally:

```bash
aipack config env set AIPACK_PROMPTLIB_API_KEY <key>
```

Use a WRITE key only for publishing PromptLib content. Never ask the user to paste a PromptLib key into chat.

## Mutation Gates

When invoked from `/onboard`, inherit its mutation gate. Outside `/onboard`, stop and ask before running any command that mutates local caches, profiles, env config, connected apps, or pulled content:

- `aipack registry fetch --deep`
- `aipack pack inspect <pack> --json`
- `aipack prompt-lib refresh`
- `aipack prompt-lib pull <space-id> --add --profile <profile>`
- `aipack pack install <pack> --add --profile <profile>`
- `aipack pack add <pack> --profile <profile>`
- `aipack config env set <key> <value>`

## Output Contract

Return a concise discovery map:

- `installed` - active in the target profile.
- `recommended` - vetted setup support such as `aipack-core`.
- `discoverable` - available in a registry or catalog but not starter-recommended.
- `inspect first` - plausible match that needs owner/source review.
- `unsupported here` - belongs to another delivery surface or is not pack-shaped.

For every item, include source surface, owner/contact when available, installed status, and overlap notes when the same domain appears in multiple catalogs.
