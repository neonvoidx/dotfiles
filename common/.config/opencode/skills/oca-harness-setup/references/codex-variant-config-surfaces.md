# Codex Variant Config Surfaces

## Config Surface (shared across all three variants)

All three Codex variants share a single config file:

| Platform | Path |
|---|---|
| macOS/Linux | `~/.codex/config.toml` |
| Windows | `%USERPROFILE%\.codex\config.toml` |

Skills, AGENTS.override.md, and .codex/config.toml paths are identical regardless of variant. The aipack Codex harness already covers all three with zero code changes.

## Behavioral Differences (not config surface)

| Aspect | CLI | Desktop App | IDE (VS Code ext) |
|---|---|---|---|
| Profile switching | `codex -p <profile>` at runtime | `/model` command in app | Not supported — edit config.toml + restart VS Code |
| `/review` command | May not work with OCA | Works | Does not work with OCA |
| `/model` command | Works (but breaks OCA config) | Works | Does not work with OCA |
| Windows | Requires WSL | Native | Native |

## Auth

- Auth file: `~/.codex/auth.json`
- API keys from apex.oraclecorp.com, expire every 7 days
- CLI login: `echo <key> | codex login --with-api-key`
- IDE: gear icon > "Sign in with ChatGPT" > "Use API Key"

## OCA Model ID Inconsistency

Confluence sources conflict. OCICODE page `19073368912` (v89) shows `oca/`-prefixed IDs, while AICODE page `19169719016` (v49) publishes a bundled config with bare IDs. For this pack, treat [`configs/codex/config.toml`](../../../../configs/codex/config.toml) as the operational source of truth and do not rewrite model IDs unless updating from the latest official bundled config artifact.

## Sources

- AICODE page 19169719016 (instructions, v49)
- AICODE page 19161798188 (troubleshooting, v17)
- OCICODE page 19073368912 (install/config, v89)
