# Bitbucket PR Troubleshooting

## Auth issues

- `BASE_URL` must point to the Bitbucket host.
- `BITBUCKET_TOKEN` must be present and accepted as a Bearer token.
- If the PR URL redirects to `/login` in an unauthenticated request, switch to the REST API with the token instead of relying on the HTML page.

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
