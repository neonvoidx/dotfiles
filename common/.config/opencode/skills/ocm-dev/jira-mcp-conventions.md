# Jira MCP Conventions

## Two servers, two instances

| MCP Server | Jira Instance | Use for |
|------------|--------------|---------|
| `atlassian` (`mcp__atlassian__jira_*`) | `jira.oci.oraclecorp.com` | Engineering work: OCICM stories/bugs/tasks, cross-org tickets |
| `atlassian-sd` (`mcp__atlassian-sd__jira_*`) | `jira-sd.mc1.oracleiaas.com` | Jira Service desk: Service Incidents (OCMSD, OCB), Change Management (CHANGE) |

The two servers cannot reach each other's data. An `atlassian` query for OCMSD tickets returns nothing — not an error, just empty results.

## Routing decision

- Oncall incident tickets in Jira-SD (OCMSD, OCB) → `atlassian-sd`
- Change Management ticket in Jira-SD (CHANGE project) → `atlassian-sd`
- Engineering work, sprint tasks in Jira (OCICM) → `atlassian`
- Sprint/board queries → check which instance hosts the board

If `atlassian-sd` is disabled in the harness, OTS queries silently return nothing. Warmup both servers before triage work.

## Comment retrieval

`jira_get_issue` may omit comments when called with only `comment_limit`. To reliably fetch comments, include `fields=comment` or `fields=*all` in addition to `comment_limit`.

Without explicit fields, the agent can incorrectly conclude an issue has no comments.

## Change Management queries

When searching for CMs in the CHANGE project, use `issuetype = "Change Request"` — not "Change" or "Change Management". See `cm-operations.md` for field mappings.
