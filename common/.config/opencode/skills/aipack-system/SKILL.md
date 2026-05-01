---
name: aipack-system
description: Use when syncing, configuring, troubleshooting, or managing aipack packs — including sync-config, profiles, harness behaviors, and the delivery pipeline
metadata:
  owner: shrug-labs
  last_updated: 2026-04-05
---

# aipack System Reference

Operational knowledge for the aipack pack management system.

## The SSOT Principle

```
Pack source (SSOT) → aipack sync → Harness locations (managed output)
```

**NEVER manually create, edit, or delete files in harness locations.**
Harness locations (`~/.claude/rules/`, `~/.claude/skills/`, `~/.claude/commands/`, `.mcp.json`, etc.) are managed output. The SSOT is the pack source at `~/.config/aipack/packs/<pack>/`.

This is a specific case of the generated-vs-authored principle: edit the input, not the output.

## Sync Procedure

Every time you modify pack content:

1. **Edit** content in pack source (`~/.config/aipack/packs/<pack>/`)
2. **Verify sync defaults:** `cat ~/.config/aipack/sync-config.yaml`
   - Check `defaults.profile` — which profile will be used?
   - Check `defaults.harnesses` — which harnesses will be synced?
   - Check `defaults.scope` — global (default) or project?
3. **Verify active profile:** `cat ~/.config/aipack/profiles/<profile>.yaml`
   - Which packs are enabled? (`enabled: true/false/null`)
   - Which content is included/excluded per vector?
   - Are the changes you made in a pack that's actually enabled?
4. **Dry-run:** `aipack sync --dry-run` — preview what would change. **Confirm new content appears in the plan.**
5. **Sync:** `aipack sync`
   - **MUTATION:** a real sync writes managed harness files outside the conversation. Get explicit `yes` before the non-dry-run command.
6. **Restart** harness client if needed (see below)

Content vectors (rules, skills, workflows, agents, prompts, profiles, registries) are auto-discovered from their standard directories. You don't need to register new files in `pack.json` unless you want to filter which IDs are included. An explicit non-empty array in the manifest acts as a filter — only listed IDs sync.

## Restart Requirements

After syncing, the harness client may need a restart for changes to take effect.

**General principle:**
- Always-on content (rules, settings, MCP config, permissions) is typically loaded at session/client start → **restart needed**
- On-demand content (skills, workflows/commands) may be picked up without restart → **depends on harness**

**When in doubt: restart the harness client after syncing.**

## Profile Mechanics

Profiles are agent profiles — curated compositions of packs that define what the agent knows and can do. They control what content from which packs gets synced.

### Enabling/disabling packs

```yaml
packs:
  - name: pack-name
    enabled: true     # Force enabled
    enabled: false    # Force disabled
    enabled: null     # Pack default (usually enabled)
```

### Filtering content per vector

```yaml
packs:
  - name: pack-name
    rules:
      include: null          # null/omitted = include all (normal pack) or nothing (quiet pack)
      include: []            # empty array = include all (backward compat; same as null for normal packs)
      include: ["rule-name"] # specific rules only
      exclude: ["rule-name"] # all except these
    skills:
      include: null
      exclude: null
    workflows:
      include: null
      exclude: null
    agents:
      include: null
      exclude: null
```

### Profile simplification

When a pack entry should include all content, omit the vector sections entirely:

```yaml
- name: my-pack
  enabled: true
  mcp:
    some-server:
      enabled: true
```

- Omitting `rules:`, `skills:`, etc. means "include everything" for normal packs, "include nothing" for quiet packs.
- `include: []` (empty list) is treated as "include all" for backward compatibility — it does NOT mean "include nothing." This is a common misunderstanding.
- Quiet packs (`quiet: true` on the pack entry) flip the default: omitted or empty selectors resolve to nothing. Only an explicit non-empty `include` list activates content.
- Only add `include:`/`exclude:` sections when you need to filter specific items.

### Settings

Any pack with harness config files (`configs/` in the manifest) contributes base settings automatically — no `settings.enabled: true` required. Multiple packs' settings are deep-merged in profile order (first pack wins at leaf conflicts, warning emitted). Set `settings.enabled: false` on a pack entry to opt a pack out.

Harness settings files are composed from three sources during sync:

1. **Base templates** (from contributing packs) — the user's non-managed harness preferences. Templates must never redeclare managed keys.
2. **Computed managed keys** — MCP server configs, permissions, content paths, agent definitions. Entirely determined by aipack processing pack content and profile resolution. These overwrite any matching keys from templates.
3. **Harness/user edits on disk** — preserved between syncs for keys not managed by aipack.

If a template redeclares a managed key, the managed value silently overwrites it during sync — the user's preference is dropped with no warning.

Plugin files (`configs.harness_plugins`) are pure copies. Same-filename plugins from different packs produce an error.

### Toggling after sync

To change what's active without editing pack source:
1. Edit the profile YAML at `~/.config/aipack/profiles/<name>.yaml`
2. Adjust `enabled`, `include`, or `exclude` as needed
3. Re-sync: `aipack sync`
4. Restart harness client if needed

### MCP per-server config

```yaml
packs:
  - name: pack-name
    mcp:
      server-name:
        enabled: true           # Enable/disable this MCP server
        allowed_tools: []       # Empty = use pack defaults
        disabled_tools: []      # Specific tools to block
```

## Common Commands

| Command | Purpose |
|---------|---------|
| `aipack sync --dry-run` | Preview what would change |
| `aipack sync` | Apply pack content (default: global scope) |
| `aipack sync --scope project` | Apply to current project directory |
| `aipack sync --force --yes` | Overwrite all managed files, even conflicts |
| `aipack doctor` | Validate pack structure and config |
| `aipack save` | Reverse: save harness content back to pack source |
| `aipack clean --dry-run` | Preview what clean would remove |
| `aipack clean --yes` | Remove managed files (default: global scope) |
| `aipack clean --scope project --yes` | Remove project-level managed files |
| `aipack clean --ledger --yes` | Clean + remove ledger state |
| `aipack render` | Render pack content to standalone output directory |
| `aipack pack create <name>` | Scaffold a new pack directory with pack.json |
| `aipack pack install <name-or-url>` | Install a pack from registry, URL, or local path |
| `aipack pack update --all` | Update all installed packs from their origins |

### Scope and targeting

- `--scope global` (default) — writes to `~/` prefixed locations (user-level config)
- `--scope project` — writes to current project directory
- `--harness <name>` — target specific harness (claudecode, opencode, codex, cline)
- `--profile <name>` — use specific profile (overrides sync-config default)
- `--profile-path <path>` — use a profile file outside config directory

### Scope duplication hazard

Do NOT sync both `--scope global` and `--scope project` for the same project. Claude Code loads rules from both `~/.claude/rules/` (global) and `<project>/.claude/rules/` (project) — identical content in both means double token cost and duplicate system prompt entries.

Pick one scope per project. For workspace-meta repos, use global only.

### Bundled content (`--with` / `-w`)

Core content (rules, skills, workflows, agents, prompts, MCP, configs) is always installed. Packs can also bundle profiles, registries, and extras — these are gated by `--with`:

- `-w all` — accept all bundled content
- `-w profiles` / `-w p` — apply bundled profiles
- `-w registries` / `-w r` — merge bundled registry entries
- `-w extras` / `-w e` — keep bundled extras (scripts, data files)

Remote installs without `--with` preview bundled content then strip it. Local installs accept everything by default.

### OpenCode settings vs plugin files

- In pack manifests, `configs.harness_settings.opencode` maps to `opencode.json`.
- `configs.harness_plugins.opencode` maps to `oh-my-opencode.json`.
- For OpenCode, `--skip-settings` skips `opencode.json` but does **not** skip `oh-my-opencode.json`.

## Harness Write Targets

Each harness writes content to different locations:

| Vector | Claude Code | OpenCode | Codex | Cline |
|--------|-------------|----------|-------|-------|
| Rules | `.claude/rules/` | `.opencode/rules/` | `AGENTS.override.md` | `.clinerules/` |
| Skills | `.claude/skills/` | `.opencode/skills/` | `.agents/skills/` | `.agents/skills/` |
| Agents | `.claude/agents/` | `.opencode/agents/` | Native TOML | `.agents/skills/` |
| Workflows | `.claude/commands/` | `.opencode/commands/` | `.agents/skills/` | `.clinerules/workflows/` |
| MCP | `.mcp.json` | `opencode.json` | `config.toml` | Global VS Code storage |
| Settings | `settings.local.json` | `opencode.json` | `config.toml` | N/A |

Global scope prefixes with `~/` (e.g., `~/.claude/rules/`). Project scope writes to the project directory.

## Pack Manifest (pack.json)

```json
{
  "schema_version": 1,
  "name": "pack-name",
  "version": "YYYY.MM.DD",
  "root": "."
}
```

Content vectors are auto-discovered from standard directories. Explicit arrays act as filters:

```json
{
  "rules": ["rule-one", "rule-two"],
  "skills": ["deploy"],
  "profiles": ["dev", "lean"],
  "registries": ["team-tools"],
  "extras": ["scripts/run-server.sh", "data"],
  "mcp": { "servers": { ... } },
  "configs": { "harness_settings": { ... } }
}
```

All content fields use bare IDs (e.g., `"profiles": ["dev"]` corresponds to `profiles/dev.yaml`). Extras are the exception — they use relative paths because they can reference files outside standard directories.

`default_allowed_tools` in pack.json only scopes MCP servers that the pack itself defines in its `mcp.servers` section. It cannot restrict tools on servers defined by another pack. Cross-pack tool scoping belongs in the profile's per-server `allowed_tools` entries.

## Configuration Locations

| File | Purpose |
|------|---------|
| `~/.config/aipack/sync-config.yaml` | Sync defaults (profile, harness, scope) + installed packs metadata |
| `~/.config/aipack/profiles/<name>.yaml` | Profile: which packs/content to sync |
| `~/.config/aipack/packs/<name>/pack.json` | Pack manifest |
| `~/.config/aipack/packs/<name>/` | Pack content source (SSOT) |
| `~/.config/aipack/registries/` | Cached remote registry sources |
| `~/.config/aipack/ledger/` | Sync state — file digests, provenance |

## Pack Installation

| Command | Purpose |
|---------|---------|
| `aipack registry fetch` | Fetch and cache remote registry sources |
| `aipack pack install <name>` | Install pack by registry name |
| `aipack pack install --url <url>` | Install from a git URL |
| `aipack pack install <path>` | Install from a local directory (symlink by default) |
| `aipack pack install -m` | Install all missing packs from the active profile |
| `aipack pack delete <name>` | Remove installed pack |
| `aipack pack enable <name>` | Register pack in active profile |
| `aipack pack disable <name>` | Remove pack from active profile |

### Profile params after install

When switching to a new profile, carry over `params` from any previous profile — otherwise MCP servers with `{params.*}` references will be skipped with unresolved param warnings.

### Content collisions

When two packs ship content with the same ID (e.g., both have `rules/anti-slop.md`), sync fails unless the later pack declares it as an override in the profile: `overrides.rules: ["anti-slop"]`.

## Personal Pack MCP Override

When a team pack's MCP server is broken (e.g., `uvx`-based server failing due to registry timeouts), override it from a personal pack without modifying the team pack:

1. Install the MCP server locally (e.g., venv at `~/.local/share/mcp-servers/<name>/`)
2. Create `~/.config/aipack/packs/<personal>/mcp/<server>.json` pointing to the local binary
3. In the active profile, disable the team pack's server: `packs[<team-pack>].mcp.<server>.enabled: false`
4. The personal pack provides the server instead — no collision, no override key needed

This works because profiles control which pack provides each MCP server. Disabling in one pack and enabling in another is clean composition, not a hack.

## Discipline (Observed Anti-Patterns)

These are behavioral failures observed in real sessions. Each one wasted significant time.

| Anti-pattern | Correction |
|---|---|
| Running aipack operations without invoking aipack-system skill first | Always invoke this skill before any aipack CLI work. |
| Ignoring sync-config values you already read | If you read a config file, extract the operational implications before acting. |
| Hand-editing generated artifacts (registry cache, harness locations) | Check whether the artifact is generated or authored. Generated → find and modify the SSOT input. |
| Proposing CLI flags without checking `--help` | Verify CLI capabilities before proposing commands. `aipack <cmd> --help` takes 2 seconds. |

## Content Lifecycle

```
Observed failure → Draft in personal pack → Battle-test → Promote to team pack
```

1. Notice agent misbehavior or knowledge gap
2. Draft content in personal pack (using pack-content-craft methodology)
3. Sync and test — does it change behavior? (TDD loop)
4. After proving value, promote to team pack via PR
5. Team pack content flows to all team members via their profiles and sync
