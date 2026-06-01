# SCM PR Troubleshooting

## Session issues

- `NotAuthenticated` usually means the profile session is expired or the command omitted the expected auth mode.
- Confirm that the target profile exists in `~/.oci/config` and whether it uses `security_token_file`. If it does, use `--auth security_token` on DevOps calls.
- For session-backed profiles, `python3 skills/codex-bootstrap/scripts/refresh_auth.py oci-session --profile <profile> --region <session-region>` is the preferred repair path.
- In terminal-only environments, the login URL may need to be opened manually while the CLI waits on `localhost`.

## Repository and PR resolution issues

- OCI DevOps PR APIs require a repository OCID and pull-request OCID; UI PR numbers are not sufficient.
- If repository or project listing is noisy, work from a known repository OCID or a repo-local config file that stores it, then confirm with `oci devops repository get`.
- Quote hyphenated JMESPath fields such as `"source-branch"`, `"display-name"`, and `"destination-branch"` in OCI CLI `--query` expressions.
- If multiple PRs exist for the same branch, explicitly choose the intended PR before posting replies.

## PR creation issues

- Push the branch before creating a PR if it is not already available on `origin`.
- Check for an existing PR on the source branch before creating a new one to avoid duplicates.
- If `git push` fails with `Permission denied (publickey)`, inspect any dedicated SCM SSH agent your environment uses before debugging DevOps permissions more broadly.

## Reply issues

- Use `parent-id` for threaded responses.
- Dry-run generated reply payloads before posting.
- Prefix AI-authored replies consistently with the agreed label.
- Do not infer that label from generic Codex config defaults alone.
- If runtime identity is not explicit and no required prefix was provided, ask the engineer once before posting.
