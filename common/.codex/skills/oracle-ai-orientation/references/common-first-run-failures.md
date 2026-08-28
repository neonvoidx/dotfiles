---
name: common-first-run-failures
description: Common AIPack, Codex/OCA, MCP, PromptLib, registry, and app/connector failures observed during OCI starter-pack onboarding
metadata:
  owner: platform_org
  last_updated: 2026-05-20
---

# Common First-Run Failures

Use this before sending a user to generic troubleshooting. Match the symptom, run the smallest read-only check, then route to the owning surface.

| Symptom | Likely cause | First check | First fix or route |
|---|---|---|---|
| `aipack` lacks a flag/subcommand or onboarding output contradicts docs | CLI binary is stale or a different binary wins `PATH` | `aipack version`, `which aipack` | Use `aipack update` for internal/script installs; use the install method's updater for brew or other package managers |
| Internal installer returns `502 notresolvable` for Artifactory | Stale terminal proxy routes internal Artifactory through a proxy | `env | grep -i proxy`, `curl -vI https://artifactory.oci.oraclecorp.com/api/storage/openshift-aipack-release-generic-local/` | Clear or correct proxy env for internal Oracle hosts, then rerun installer |
| `aipack update` cannot write beside `/usr/local/bin/aipack` | Brew-installed binary in root-owned location | `brew info aipack`, `ls -l $(which aipack)` | Use `brew upgrade aipack` or reinstall through the internal installer into a user-writable path |
| `aipack pack install oci-dev-starter-pack --add -w all` tries to open local `./oci-dev-starter-pack/pack.json` | Same-name current-directory path shadows the registry name | `test -e ./oci-dev-starter-pack && pwd` | Run from a neutral directory, remove the stale local path if safe, or use explicit `--url ... --path ...` |
| Registry fetch appears ignored or stale | Merged registry view is shadowed by an installed pack's bundled registry | `aipack registry sources`, inspect active lock/source | Verify explicit source cache/lockfile before assuming fetch failed |
| `--ref` on a registry short name does not test the intended branch | Registry/archive entry uses its recorded source; ref override may not affect archive/current install path | `aipack pack inspect <name>` and `~/.config/aipack/aipack.lock` | For branch testing use explicit `aipack pack install --url <repo> --ref <ref> --path <pack-dir> ...` |
| `aipack sync` says no packs configured | Pack installed but not added to active profile | `aipack status --profile <profile> --json`, `aipack pack list --json` | Install with `--add` or run `aipack pack add <pack> --profile <profile>` |
| User switched to a bundled profile and lost expected shared content | First-run content was added to `default`, but bundled profile has different composition | `aipack config defaults get profile`, `aipack status --profile <profile> --json` | Keep first-run on the active profile; add both baseline packs to that profile before profile-specific tuning |
| Pack update/sync happened but old skills/settings still load | Confusion between CLI update, pack update, registry fetch, sync, and session reload | Compare `aipack update`, `aipack pack update`, `aipack registry fetch`, `aipack sync` usage | Update the installed pack, sync, then start a fresh assistant session |
| PromptLib commands fail immediately | Missing `AIPACK_PROMPTLIB_API_KEY` | Value-free check for key presence | Create a VIEW_ONLY key in Prompt Library and set it with `aipack config env set AIPACK_PROMPTLIB_API_KEY <key>` |
| MCP server starts but has zero or unusable tools | Auth, profile allowlist, env refs, or wrong runtime plane; not usually reinstall | `aipack mcp inspect-tools <server> --profile <profile>` and server recipe Auth section | Use `installing-mcp-servers` triage; fix auth/profile before reinstalling |
| Codex shows gateway/tools that AIPack did not render, or AIPack-rendered tools are missing | Managed Codex, ORA, Enterprise apps, MCP Gateway, and AIPack render planes differ | `codex mcp list`, `aipack mcp inspect-tools --profile <profile>`, runtime config-plane reference | Route to `oca-harness-setup`; do not duplicate gateway config in the pack |
| ChatGPT apps/connectors do not appear in Codex | Enterprise app catalog sync/session state, not AIPack profile sync | Check `https://chatgpt.com/apps`, Codex `/apps`, and current Enterprise docs | Reopen/restart Codex session; route persistent app sync issues to `#help-codex` |
| DOPE MCP auth fails with operator-token error | Stale env-file content or `SSH_AUTH_SOCK` forcing wrong auth path | Check env-file path from MCP JSON and value-free presence of `SSH_AUTH_SOCK` | Remove stale `SSH_AUTH_SOCK` from the DOPE env file, refresh token if needed, restart MCP/harness |
| Jira/Jira-SD works in one context but not another | Separate PATs/hosts/profile write mode or stale env | Check `JIRA_PAT` vs `JIRA_SD_PAT` presence, profile params, server recipe | Set the right PAT locally and restart the harness/MCP server |
| Confluence auth fails or browser SSO loops | Web-session cookie expired or wrong `mcp-atlassian` build | Check server recipe and Codex log excerpt | Refresh browser session using the Confluence recipe; do not switch to PAT unless recipe/source supports it |
| Bitbucket clone or registry fetch fails | VPN, SSH key, or port 7999 issue | `ssh -T git@bitbucket.oci.oraclecorp.com -p 7999` | Register/unlock SSH key, use `ssh://...:7999/...`, or use Artifactory archive path when source access is not needed |
| `aipack pack validate oci-dev-starter-pack` fails outside repo | Validate expects a filesystem path, not installed-pack lookup | `pwd`, `ls oci-dev-starter-pack/pack.json` | Run from repo root with `aipack pack validate oci-dev-starter-pack` or pass an absolute pack path |

## Read-Only Triage Bundle

Use these commands as a compact evidence packet. Do not include resolved secret values in the user-facing output.

```bash
aipack version
aipack config defaults get profile
aipack config defaults get harnesses
aipack config defaults get scope
aipack status --profile <profile> --json
aipack profile refs <profile> --json
aipack doctor --profile <profile> --json
aipack sync --profile <profile> --harness <harness> --scope <scope> --dry-run
```

For one failing MCP server:

```bash
aipack mcp inspect-tools <server> --profile <profile>
rg -n "MCP server stderr|Traceback|No such file or directory|AttributeError|failed" ~/.codex/log/codex-tui.log -S | tail -n 80
```

## Escalation Rule

Escalate with a short evidence packet: command, exact error, profile/harness/scope, pack version or lockfile source, runtime plane, and the docs/channels already checked. Do not ask a support channel to debug "it does not work" without that packet.
