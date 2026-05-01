# OCA Canonical Codex Config

**SSOT page:** "Installing Codex CLI and Codex IDE with Oracle Code Assist"
- URL: https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19073368912
- Space: OCICODE, v84 (heavily maintained)

**Key requirements:**
- All model names must use `oca/` prefix (e.g. `oca/gpt-5.4`, not `gpt-5.4`)
- Top-level `model` must have prefix because VS Code ignores profile and uses it directly
- Web search key is `web_search = "live"` (not `web_search_request = true`)
- Trust level is scoped via `[projects."/Users/"]` in canonical (the pack uses top-level — intentional divergence)
- `/model` and `/review` slash commands don't work with OCA — if used, must re-download config
- API keys expire every 7 days

**Pack config:** `oci-dev-starter-pack/configs/codex/config.toml` — verify alignment against SSOT page before releases
