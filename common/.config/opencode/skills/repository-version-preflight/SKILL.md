---
name: repository-version-preflight
description: Use when a Codex skill declares a remote SKILL.md source and needs to warn whether the active local skill version is stale or unverifiable before continuing.
---

# Repository Version Preflight

Use this support skill when another skill declares a `Repository version source` with `remote_file_url`.

## Procedure

1. Read the active skill version from the caller's local `SKILL.md`.
2. Read `remote_file_url` from the caller's `Repository version source` block.
3. Read the remote `SKILL.md` directly:
   ```bash
   curl -sS -L \
     -H "Authorization: Bearer $BITBUCKET_TOKEN" \
     -H "Accept: text/plain" \
     "$remote_file_url"
   ```
4. Parse the remote `Current skill version`.
5. Compare active and remote versions using semantic-version order.
6. Return a preflight status:
   - `current` when active version is greater than or equal to remote version
   - `stale` when remote version is newer
   - `unverified` when the check cannot read or parse the remote skill

## Rules

- The preflight is warning-only and must not block the caller's workflow or writeback.
- Do not use env vars, separate config files, service repositories, incident-linked repositories, team-configured code repositories, or ticket-linked Bitbucket repositories as the version source.
- Do not create a local git checkout or scratch git directory.
- Treat missing `BITBUCKET_TOKEN`, login HTML, non-SKILL content, missing `Current skill version`, auth failure, DNS failure, and unreadable responses as `unverified`.
- Carry the status, active version, remote version when known, `remote_file_url`, and blocker when known into user-facing summaries and writeback warnings.
