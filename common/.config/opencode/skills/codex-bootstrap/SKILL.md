---
name: codex-bootstrap
description: Bootstrap a local Codex setup from this shared starter repo. Use when an engineer needs an interactive onboarding flow that asks for local paths, required MCP settings, and only the overrides that differ from the shared Enterprise ChatGPT defaults, then generates or repairs a real local Codex config and verifies that shared path placeholders were resolved.
---

# Codex Bootstrap

Use this skill when an engineer is setting up Codex from this shared starter repo or repairing a local config after the repo moved.

Setup model:
- Keep the shared repo as the versioned source of truth for `AGENTS.md`, `workflows/`, `agents/`, `skills/`, and templates.
- Keep personal Codex runtime state in `~/.codex` by default unless the engineer explicitly wants another Codex home.
- Generate a local user config that points at the shared repo’s real paths.
- Install a rendered global `AGENTS.md` entrypoint in Codex home so the engineer’s Codex setup is complete even when Codex home is outside the shared repo.

## Quick Start

1. Prefer writing a local config outside the shared repo, usually `~/.codex/config.toml`.
2. Default Codex home to `~/.codex` unless the engineer wants a different location.
3. Ask only the necessary questions, one short question at a time:
   - repo root for this shared starter
   - whether they want a non-default Codex home
   - output config path
   - workspace parent
   - whether they want to add the local Maven repository to writable roots for sandboxed builds, defaulting the path to `~/.m2/repository`
   - whether they want to override the shared Enterprise ChatGPT model defaults, and only then the optional provider, model, and optional profile
   - whether to install the rendered global `AGENTS.md` entrypoint in Codex home
   - whether they want to opt out of the default-enabled `stlm-mcp`, `mcp-dope`, `chrome-devtools`, `sqlcl`, `mcp-atlassian-jira-sd`, `mcp-atlassian-jira-oci`, `centralconfluence`, `playwright`, `ots`, and `mcp_shepherd` integrations
   - for enabled `sqlcl`, ask whether bootstrap should use SQLcl connection metadata from an `On-Call Investigation` team config and, if yes, collect the team-config path and optional team name
   - whether they already have one shared `.env` file for enabled helper-backed MCP servers; if not, collect the desired path, offer starter generation there, and collect the shared `HOME` override and log directory when they want to change the defaults
   - whether they want to opt out of the default-enabled `codex-bootstrap`, `ots-ticket`, `jira-ticket`, `cm-review`, `create-module-knowledge-skills`, `internal-confluence-page`, `oncall-investigation`, `object-store`, `pr-description`, `scm-pr`, `bitbucket-pr`, `release-check`, and `authZ-permissions-yaml-generator` skills
   - when `bitbucket-pr` stays enabled, ask whether the engineer uses `zsh` or `bash`, then collect the shell init file path to use for sourcing that helper
   - for enabled `bitbucket-pr`, whether `BASE_URL` and `BITBUCKET_TOKEN` are already set up; if not, collect the Bitbucket host and create a local helper env file
   - for enabled `jira-ticket`, whether `JIRA_URL` and `JIRA_PERSONAL_TOKEN` are already set up in both Jira MCP env files (`~/.env` and `~/.env.jira-oci`); if not, collect the Jira OCI host and offer to create the Jira OCI MCP env helper
   - tell the engineer to source the generated Bitbucket helper from the selected shell init file so every shell session loads it
   - if either enabled skill still lacks configured auth, stop bootstrap with a clear rerun instruction instead of silently completing
4. Run the helper script in this skill to generate or update the config and install the global `AGENTS.md` entrypoint.
5. Verify the script linked enabled shared skills into `$CODEX_HOME/skills` and reports no unresolved path placeholders.
6. Summarize what was written, which skills and integrations were enabled, how `AGENTS.md` and skill links were installed, any PR auth helper files that were created, and any remaining follow-up.

## Undo

Use undo mode when the engineer wants to remove the local files that bootstrap generated without restoring older backups.

```bash
python3 skills/codex-bootstrap/scripts/bootstrap_codex.py \
  --codex-home "~/.codex" \
  --undo
```

Notes:
- Undo removes the generated local `config.toml`, global `AGENTS.md` target, generated MCP env helper files, the default Bitbucket auth helper, and the generated Jira OCI MCP env helper when it still has the bootstrap header.
- Undo does not restore backups.
- Undo leaves any `.bak.*` files in place so the engineer can inspect or restore them manually if needed.

## Safety Rules

- Do not write personal absolute paths into tracked repo files unless the user explicitly asks.
- Prefer generating a user-local config from `config.example.toml` instead of editing the template in place.
- Prefer installing a rendered `~/.codex/AGENTS.md` copy that expands repo-relative routing paths to absolute repo paths so skill and action routing still works outside the shared repo workspace.
- Install enabled shared skills as symlinks under `$CODEX_HOME/skills` that point back to the shared repo. Do not copy skill directories; copies drift when the repo skills are updated.
- Do not tell AIPack users to run bootstrap as a mandatory post-install step.
- If the target config already exists, back it up before overwriting.
- If a skill target already exists in `$CODEX_HOME/skills`, back it up under `$CODEX_HOME/skill-backups` before replacing it with the repo symlink.
- In undo mode, remove only the generated local files and repo-backed skill symlinks; do not auto-restore backups.
- Default `stlm-mcp`, `mcp-dope`, `chrome-devtools`, `sqlcl`, `mcp-atlassian-jira-sd`, `mcp-atlassian-jira-oci`, `centralconfluence`, `playwright`, `ots`, `mcp_shepherd`, `codex-bootstrap`, `ots-ticket`, `jira-ticket`, `cm-review`, `create-module-knowledge-skills`, `internal-confluence-page`, `oncall-investigation`, `object-store`, `pr-description`, `scm-pr`, `bitbucket-pr`, `release-check`, and `authZ-permissions-yaml-generator` to enabled unless the engineer explicitly opts out.
- When `stlm-mcp` or `mcp-dope` stays enabled, collect one shared `.env` path for both MCPs and offer the shared `HOME` override and log directory when the engineer wants to change the defaults.
- Ask whether the engineer already has a shared env file for enabled helper-backed MCPs before offering generation.
- For `stlm-mcp`, make sure the generated helper or existing dotenv contains `OCI_CONFIG_FILE` and `OCI_PROFILE`.
- If they do not, offer to generate a starter dotenv helper from the repo template at the chosen path.
- If `bitbucket-pr` stays enabled, ask whether `BASE_URL` and `BITBUCKET_TOKEN` are already available and create a local helper env file when they are not.
- If `jira-ticket` stays enabled, ask whether `JIRA_URL` and `JIRA_PERSONAL_TOKEN` are already available in both Jira MCP env files (`~/.env` and `~/.env.jira-oci`) and offer to create the Jira OCI MCP env helper when Jira OCI is not configured.
- When a Bitbucket helper file is used, tell the engineer to source it from the selected shell init file.
- Jira Ticket reads the shared Jira MCP dotenv files directly and does not need shell startup sourcing.
- If `bitbucket-pr` or `jira-ticket` stays enabled, require configured auth before bootstrap succeeds. A starter helper file alone is not enough; the engineer must populate it or otherwise export the required variables, then rerun bootstrap.
- Prefer the shared `skills/codex-bootstrap/scripts/refresh_auth.py` helper for `OP_TOKEN` refreshes and OCI session validation/repair so shared docs and skills stay aligned.

## Workflow

### 1. Collect the minimum required inputs

Ask one short question at a time until you have:
- repo root
- whether Codex home should stay at the default `~/.codex`
- output config path
- workspace parent
- whether the engineer wants the local Maven repository writable root for sandboxed builds
- whether the engineer wants to override the shared Enterprise ChatGPT defaults
- provider, model, and optional profile only when they opt into an override
- whether to install the rendered global `AGENTS.md` entrypoint
- enabled skills, defaulting to all shared skills on
- whether `bitbucket-pr` auth is already set up and, if not, the Bitbucket host plus helper env path
- whether `jira-ticket` auth is already set up and, if not, the Jira OCI host plus whether to generate the Jira OCI MCP env helper
- whether the engineer uses `zsh` or `bash` for shell startup and which init file should source the Bitbucket auth helper when Bitbucket stays enabled
- enabled MCP servers, defaulting to the full packaged set of `stlm-mcp`, `mcp-dope`, `chrome-devtools`, `sqlcl`, `mcp-atlassian-jira-sd`, `mcp-atlassian-jira-oci`, `centralconfluence`, `playwright`, `ots`, and `mcp_shepherd`
- whether the engineer already has one shared `.env` file for enabled helper-backed MCPs; if not, the desired path, whether to generate a starter env helper there, plus the shared `HOME` override and log directory when they want to change the defaults
- when SQLcl connection metadata should come from an On-Call Investigation team config, the config path and, if needed, the specific team name whose `team.sqlcl` block should be used

Good defaults are:
- repo root: current repo root
- Codex home: `~/.codex`
- global `AGENTS.md` target: `<codex home>/AGENTS.md`
- workspace parent: parent directory of the current repo
- Maven repository: `~/.m2/repository` when sandboxed builds need it
- log directory: `<codex home>/log`
- Bitbucket helper env file: `<codex home>/bitbucket-pr.env`
- Jira-SD MCP/Jira Ticket env file: `<home>/.env`
- Jira OCI MCP/Jira Ticket env file: `<home>/.env.jira-oci`
- zsh init file for Bitbucket auth helper: `~/.zshenv`
- bash init file for Bitbucket auth helper: `~/.bashrc`
- Jira-SD base URL: `https://jira-sd.mc1.oracleiaas.com`
- Jira OCI base URL: `https://jira.oci.oraclecorp.com`
- MCP helper env file for `stlm-mcp` and `mcp-dope`: `<codex home>/mcp.env`
- default `stlm-mcp` MCP env OCI settings: `OCI_CONFIG_FILE=<home>/.oci/config`, `OCI_PROFILE=oc1`, and OCI session auto-refresh settings
- shared `HOME` for packaged MCPs: current user home directory
- Atlassian MCP dotenv files: `<home>/.env` for Jira-SD and `<home>/.env.jira-oci` for Jira OCI
- README-derived starter keys for the shared `mcp-dope` template helper used by both `stlm-mcp` and `mcp-dope`: `OP_TOKEN` and `SSH_AUTH_SOCK`
- model provider: blank by default
- provider default model: `gpt-5.5`
- default profile: `gpt-5-5`

### 2. Generate the config

Use the bundled script. Prefer explicit arguments when you already collected the values in chat.

If helper-backed MCPs stay enabled and you are not using `--prompt`, provide one shared `--env-file` plus `--home-dir` and `--log-directory` explicitly. `stlm-mcp` and `mcp-dope` must point at the same dotenv file. `stlm-mcp` also needs `HOME`, `OCI_CONFIG_FILE`, `OCI_PROFILE`, OCI session auto-refresh settings, and `LOG_DIRECTORY` in the MCP env block.

All packaged MCPs are enabled by default in non-prompt mode. Disable any the engineer does not use with `--disable-mcp <name>`.

When you want bootstrap to create starter MCP env helpers in non-prompt mode, pass `--generate-mcp-env <server-name>` once per enabled MCP whose file should be generated. If multiple enabled MCPs share the same env path, bootstrap writes one file from `mcp-dope.env.template`; `stlm-mcp` gets its OCI config/profile settings from the MCP env block.

Pass `--m2-repository "<path>"` when you want sandboxed builds to reuse a writable local Maven cache.

When `bitbucket-pr` still needs local auth/bootstrap help, pass the matching flags so the script can generate the helper file:
- `--bitbucket-auth-state needs-setup --bitbucket-base-url "<host>" --bitbucket-env-file "<path>"`

When `jira-ticket` still needs local auth/bootstrap help, pass the matching flags so the script can generate the helper file:
- `--jira-auth-state needs-setup --jira-oci-base-url "<jira-oci-host>" --generate-jira-oci-mcp-env`

When the engineer wants bootstrap to use SQLcl connection metadata from an On-Call Investigation team config, pass:
- `--sqlcl-team-config "<path-to-team-config>" --sqlcl-team-name "<team-name>"`

If that `team.sqlcl` block includes `connect_string`, `username`, and `password_env_var`, bootstrap reads the password from the named variable in the current environment first, then in the configured `password_env_file` (default `~/.env`), and creates or refreshes the saved SQLcl alias. If the block includes only `connection_name`, bootstrap treats it as an existing saved SQLcl connection and just records the alias plus any tunnel notes.

When Bitbucket or Jira auth is missing for an enabled skill, bootstrap writes the requested helper file and exits non-zero until the required variables are populated and available. Bitbucket helpers should be sourced from the selected shell init file; Jira MCP env files are read directly by the Jira MCPs and the Jira Ticket script.

```bash
python3 skills/codex-bootstrap/scripts/bootstrap_codex.py \
  --repo-root "<repo-root>" \
  --codex-home "<codex-home>" \
  --output "<config-path>" \
  --workspace-parent "<workspace-parent>" \
  --m2-repository "<path-to-your-m2-repository>" \
  --model-provider "<provider>" \
  --model "<model>" \
  --profile "<profile>" \
  --agents-mode copy \
  --bitbucket-auth-state needs-setup \
  --bitbucket-base-url "<bitbucket-host>" \
  --bitbucket-env-file "<path-to-bitbucket-env-helper>" \
  --jira-auth-state needs-setup \
  --jira-oci-base-url "<jira-oci-host>" \
  --generate-jira-oci-mcp-env \
  --env-file "<path-to-shared-mcp-env>" \
  --generate-mcp-env stlm-mcp \
  --generate-mcp-env mcp-dope \
  --sqlcl-team-config "<path-to-team-config>" \
  --sqlcl-team-name "<team-name>" \
  --home-dir "<home-dir>" \
  --log-directory "<log-directory>"
```

Disable anything the engineer does not use:

```bash
python3 skills/codex-bootstrap/scripts/bootstrap_codex.py \
  --output "~/.codex/config.toml" \
  --agents-mode copy \
  --disable-mcp sqlcl \
  --disable-mcp mcp-atlassian-jira-sd \
  --disable-mcp mcp-atlassian-jira-oci \
  --disable-mcp mcp_shepherd \
  --disable-skill bitbucket-pr
```

Trim the setup down to only the browser MCP:

```bash
python3 skills/codex-bootstrap/scripts/bootstrap_codex.py \
  --output "~/.codex/config.toml" \
  --agents-mode copy \
  --disable-mcp stlm-mcp \
  --disable-mcp mcp-dope \
  --disable-mcp sqlcl \
  --disable-mcp mcp-atlassian-jira-sd \
  --disable-mcp mcp-atlassian-jira-oci \
  --disable-mcp centralconfluence \
  --disable-mcp playwright \
  --disable-mcp ots \
  --disable-mcp mcp_shepherd
```

If the engineer wants a terminal-driven interview instead of chat-driven collection, use prompt mode:

```bash
python3 skills/codex-bootstrap/scripts/bootstrap_codex.py --prompt
```

Use `--allow-repo-write` only when the engineer explicitly wants a machine-specific config inside the shared repo.

### 3. Verify placeholder cleanup

- Read the script output.
- If it reports unresolved path placeholders, stop and fix them before finishing.
- Call out any remaining non-path template placeholders only when the engineer chose to leave those values blank.
- When validating the shared bootstrap workflow itself, prefer `skills/codex-bootstrap/scripts/verify_bootstrap.sh`; it uses disposable temp homes and cleans them up automatically.

### 4. Explain the result

Report:
- config path written
- backup path if one was created
- rendered global `AGENTS.md` target
- enabled skills
- shared skill links installed under `$CODEX_HOME/skills`
- enabled MCP servers
- any prerequisite notes for `chrome-devtools`, `sqlcl`, `mcp-atlassian-jira-sd`, `mcp-atlassian-jira-oci`, `centralconfluence`, `ots`, or `mcp_shepherd`
- any SQLcl saved connection that bootstrap configured from team metadata
- any generated Bitbucket PR helper files
- any generated Jira OCI MCP env helper files
- the shell init sourcing lines the engineer should add for those helper files
- any generated MCP env helper files
- any disabled optional integrations
- any remaining manual steps

## Notes

- The helper script resolves shared repo references for:
  - rendered global `AGENTS.md` installation into Codex home
  - `skills/*/SKILL.md`
  - generated local `agents/*.toml` derived from shared `agents/*.md`
  - writable roots
  - optional local Maven repository access for sandboxed builds
  - shared helper-backed MCP `.env` files plus shared `HOME` and log directories
  - packaged Chrome DevTools MCP settings
  - starter MCP env helper generation when requested
  - optional Bitbucket PR env helper generation
  - optional Jira OCI MCP env helper generation
  - trusted repo example paths
- The shared starter expects local absolute paths inside the generated user config. Keep those paths user-local, not committed.
- The intended steady state is:
  - shared repo: versioned source of truth
  - Codex home: personal config, logs, auth, and global `AGENTS.md` entrypoint
