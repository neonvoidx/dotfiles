# Access Warmups — Detail

Extracted from: `rules/ocm-access-warmups.md`

## Scope

- Warmups validate authentication/connectivity across: Atlassian (Confluence + Jira), Bitbucket, DevOps/DOPE, OCI CLI.
- Warmups are not an authorization review. They only prove *you can read*.

## Requirements (inputs)

- Required:
  - which access surface(s) you need to warm up
  - which harness/tooling you will use (MCP tools vs local CLI)
- Optional:
  - a low-sensitivity target for the warmup (preferred): list/search calls over fetching specific PRs/issues/resources

## Sequencing guidance

- If you need more than one warmup, run warmups **serially** (do not parallelize).
  - Rationale: reduces "auth stampede" failures where multiple tools prompt at once.
- When warming up Atlassian, follow the workflow ordering (Confluence then Jira).

## Outputs

- Each warmup must produce:
  - a clear pass/fail outcome
  - the minimal non-sensitive output needed to prove success
  - a short statement of what access surface is now "warm"

## Evidence

When you need evidence of access readiness (local-only; never commit):

- Store it under a gitignored local directory (for example: `.generated/evidence/access-warmups/<YYYY-MM-DD>/`).
- Keep evidence minimal and sanitized (shape proof only).

## Failure modes

- **HTTP 401/403 (auth/permission).**
  - Recovery: re-run the warmup and complete any interactive sign-in; verify required env vars/config exist; confirm you are in the expected account/realm.

- **DOPE: "Could not get operator token" (Error Code: -1).**
  - Cause: expired OP_TOKEN. This cannot be resolved by the agent — it requires operator intervention.
  - Recovery: ask the operator to refresh their operator token. The process requires YubiKey PIN input:
    1. `reload-ssh` (operator alias to reload SSH agent)
    2. `ssh operator-access-token.svc.ad1.r2 generate --mode jwt` (generates new JWT; requires YubiKey PIN)
    3. Update OP_TOKEN in the DOPE env file
  - After refresh, re-run the DOPE warmup call.

- **Atlassian: stale session cache (repeated auth prompts or silent failures after TTL).**
  - Cause: `mcp-atlassian` stores Playwright browser session state in `~/.atlassian/` as JSON files (one per URL, named by SHA-256 hash). TTL is 6 hours.
  - Recovery:
    1. `rm ~/.atlassian/*.json` — forces fresh Playwright login on next MCP server startup
    2. Re-run the Atlassian warmup to establish a new session
  - To identify which file maps to which URL: `python3 -c "from hashlib import sha256; print(sha256(b'<url>').hexdigest())"`

- **Tool/server not enabled in the harness.**
  - Recovery: follow the relevant setup doc and re-run the warmup.

- **Warmup output includes sensitive identifiers.**
  - Recovery: switch the warmup query to a less sensitive target; sanitize stored evidence.

## References

- Execution baselines: `skills/ocm-dev/execution-baselines-detail.md`
- Sync/profile setup: `readme.md`
