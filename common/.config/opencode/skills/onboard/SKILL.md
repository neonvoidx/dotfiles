---
name: onboard
description: '[Workflow] Interactive onboarding — install packs, set up MCP servers, sync a profile to a harness'
source_type: workflow
metadata:
    last_updated: 2026-04-01T00:00:00Z
    owner: platform_org
---

# /onboard

Set up aipack packs and MCP servers for a harness. Reads the active profile to determine what to install and configure — no team-specific knowledge hardcoded.

This workflow must not create commits. It must not write secrets.
Assume `oci-dev-starter-pack` is already installed and synced enough for `/onboard` to be available. Install only missing dependency packs from the selected profile.

## Inputs

- Profile: `dev-readonly` or `dev-elevated`. Default: `dev-readonly`.
- Scope: `global` (all projects) or `project` (current repo). Default: global.
- Primary harness: `codex`, `cline`, or `opencode`. Default: codex.
- Settings overwrite: whether to overwrite managed settings files from templates. Default: no (merge-only).

## Mutation gate

Before any step that overwrites, prunes, or replaces user configuration, stop and ask for explicit confirmation. Treat these as MUTATION steps:
- `aipack sync --force` (and `--yes` when used)
- Overwriting OpenCode settings files
- Editing existing profile files under `~/.config/aipack/`

## Steps

### 0. Clarifying questions

Ask:
1. Profile — `dev-readonly` or `dev-elevated`? Default `dev-readonly`.
2. Scope — global or project? Default `global`.
3. Primary harness — Codex, Cline, or OpenCode? Default `codex`.
4. Overwrite managed settings from templates? (If yes, this is a MUTATION approval.)

### 1. Verify prereqs

Check: `git`, `uv`/`uvx`. If missing, give install instructions and stop.

Additional prereqs (`node`, `npm`, `python3`) are checked per-server in step 4.

### 2. Prepare the selected profile

1. Check for `~/.config/aipack/profiles/<profile>.yaml`.
2. If the file is missing, label `MUTATION`, confirm, then copy `~/.config/aipack/packs/oci-dev-starter-pack/profiles/<profile>.yaml` to `~/.config/aipack/profiles/<profile>.yaml`.

### 3. Align sync-config defaults

1. Label `MUTATION` and confirm running `aipack profile set <profile>` to set `defaults.profile`.
2. Run `aipack profile set <profile>`.
3. Read `~/.config/aipack/sync-config.yaml` and inspect `defaults.scope` and `defaults.harnesses`.
4. If `defaults.scope` does not match the selected scope or `defaults.harnesses` does not equal `[<selected harness>]`, label `MUTATION` and confirm updating `~/.config/aipack/sync-config.yaml`.
5. After approval, set `defaults.scope: <selected scope>` and `defaults.harnesses: [<selected harness>]` in `~/.config/aipack/sync-config.yaml`.

### 4. Install missing dependency packs

1. Read `~/.config/aipack/profiles/<profile>.yaml` and list the declared pack names (excluding `oci-dev-starter-pack` itself — it is already installed).
2. Run `aipack pack list --json`.
3. For each declared pack missing from the installed-pack list, label `MUTATION` and confirm running `aipack pack install <pack-name>`.
4. After approval, run `aipack pack install <pack-name>` for each missing dependency pack.

### 5. Install MCP servers

Invoke the `installing-mcp-servers` skill:

1. Read the selected profile to determine which MCP servers are `enabled: true`
2. For each enabled server, read its MCP config JSON from the pack that owns it (`mcp/<server>.json`)
3. Check whether the server is already installed (binary/module at expected path, or uvx-resolvable)
4. For servers that need local install, read the per-server recipe and execute it
5. Verify each server starts successfully

If the user wants to skip MCP server installation (rules/skills only, no tool access), skip this step.

### 6. Preflight

Run `aipack doctor` to confirm paths and environment for the selected profile. Read-only.

```bash
aipack doctor --json --profile <profile>
```

Review the output. If any checks fail, address them before proceeding.

### 7. Sync dry-run

```bash
aipack sync --profile <profile> --harness <harness> --scope <scope> --dry-run
```

Confirm the planned writes target the selected harness and scope before any real sync.

### 8. Sync (merge mode)

If the dry-run output in step 7 was reviewed and approved, proceed. Otherwise, resolve issues and re-run the dry-run.

```bash
aipack sync --profile <profile> --harness <harness> --scope <scope>
```

### 9. Settings overwrite (opt-in)

Only if the user explicitly approved overwriting settings in step 0.

MUTATION: confirm the exact target file paths before running:

```bash
aipack sync --profile <profile> --harness <harness> --scope <scope> --force --yes
```

### 10. Verify

- `aipack doctor --profile <profile>` exits `0`
- The user's primary harness loads rules, skills, and MCP tools from the synced profile
- No destructive overwrite occurred without explicit confirmation
- No secrets were written

## Done when

- Required dependency packs are installed, MCP servers are available, and `aipack sync` has written the selected profile to the target harness.
