# Bitbucket PR Troubleshooting

## Auth issues

- Resolve auth from the process environment first, then repository `.env`, `$CODEX_HOME/bitbucket-pr.env` or `~/.codex/bitbucket-pr.env`, then `~/.env`.
- As a compatibility fallback, parse exact assignment lines from shell init files such as `~/.zshenv` or `~/.zshrc`; do not source shell init files.
- `BASE_URL` must point to the Bitbucket host. If it is absent, use `BITBUCKET_BASE_URL` as an alias.
- `BITBUCKET_TOKEN` must be present and accepted as a Bearer token. If it is absent, use `BITBUCKET_BEARER` as an alias.
- If the PR URL redirects to `/login` in an unauthenticated request, switch to the REST API with the token instead of relying on the HTML page. Do not open a browser or Chrome for Bitbucket PR operations unless the user explicitly asks for browser-based troubleshooting.

## Comment retrieval issues

- If `GET /pull-requests/<PR_ID>/comments` returns HTTP 400, use the PR activities feed instead:
  - `/rest/api/1.0/projects/<KEY>/repos/<SLUG>/pull-requests/<PR_ID>/activities?limit=1000`
- Review threads are exposed through `COMMENTED` activities, with nested replies under `comment.comments`.

## Threading issues

- When you post a reply with `parent.id`, Bitbucket may attach it under the root thread while flattening nested placement.
- Re-fetch the activities feed after posting instead of assuming the reply landed exactly where requested.
- If the thread structure changed while you were drafting, reload the thread before posting again.

## Transparency issues

- Prefix AI-authored replies with the agreed label.
- Do not infer that label from generic Codex config defaults alone.
- If you do not know the exact runtime model variant and no required prefix was provided, ask the engineer once before posting.
