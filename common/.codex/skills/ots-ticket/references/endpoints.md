# OTS Endpoint Reference

## Base URI

- `https://ticketing-platform.us-chicago-1.oci.oraclecloud.com/`

## Auth Pattern

- Prefer an OCI CLI session-backed profile such as `oc1`.
- Validate before every request:

```bash
oci --profile oc1 session validate --local
```

- Refresh expired sessions before retrying:

```bash
oci --profile oc1 session refresh
```

## Bundled Helper

- Script path: `skills/ots-ticket/scripts/ots_ticket_api.py`
- Default profile: `oc1`
- Default JSON API version: `20180828`
- Default search API version: `20230531`
- Status transitions use the same `oci raw-request --auth security_token` flow as other JSON calls

## Supported Endpoints

### Ticket details

- Path: `20180828/tickets/{ticketId}`
- Example:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py ticket ORGMGMT-01-12837582
```

### Project details

- Path: `20180828/projects/{project}`
- Example:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py project ORGMGMT
```

### Comments

- Path: `20180828/tickets/{ticketId}/comments?limit={n}`
- Example:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py comments ORGMGMT-01-12837582 --limit 10
```

### Comment creation

- Path: `20180828/tickets/{ticketId}/comments`
- Method: `POST`
- Known minimal request body:

```json
{"text":"Investigated the latest 500s; backend dependency recovered and I am monitoring."}
```

- Examples:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py comment-create ORGMGMT-01-12837582 --text "Investigated the latest 500s; backend dependency recovered and I am monitoring."
python3 skills/ots-ticket/scripts/ots_ticket_api.py comment-create ORGMGMT-01-12837582 --text-file /tmp/comment.md
cat /tmp/comment.md | python3 skills/ots-ticket/scripts/ots_ticket_api.py comment-create ORGMGMT-01-12837582 --stdin
python3 skills/ots-ticket/scripts/ots_ticket_api.py comment-create ORGMGMT-01-12837582 --text "Preview only" --dry-run
```

- Notes:
- `text` is the required field.
- Posting with only `text` creates an internal comment by default in this environment.
- Follow with a `comments --limit 5` read if you want a lightweight verification step.

### Activity history

- Path: `20180828/tickets/{ticketIdOrOcid}/activityHistory?limit={n}&sortOrder=DESC`
- The API accepts either the user-facing ticket id or the ticket OCID.
- Examples:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py activities ORGMGMT-01-12837582 --limit 10
python3 skills/ots-ticket/scripts/ots_ticket_api.py activities ocid1.ticketingticket.oc1.us-chicago-1.01.amaaaaaaaftirpaatcddsaolzgm6ytazhs2pldq7goene2wbvmhewgnsy2ka --limit 1
```

### Linked tickets

- Expected path: `20180828/tickets/{ticketId}/linkTickets`
- Example:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py linked-tickets ORGMGMT-01-12837582
```

### TQL search

- Path: `20230531/tickets?tql={expression}&limit={n}`
- Example:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py tql "(project = 'ORGMGMT' AND severity=2) AND operational scope != 'Central Ops'" --limit 60
```

### Dashboards

- Path: `20180828/dashboards?page=1`
- Example:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py dashboards --page 1
```

### Subqueries

- Path: `20230531/subQueries?limit=5`
- Example:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py subqueries --limit 5
```

### Status transition

- Path: `20180828/tickets/{ticketId}`
- Method: `PUT`
- Required request body fields:
  - `title`
  - `issueType`
  - `projectKey`
  - `severity`
  - `status`
- Helper behavior:
  - fetches the current ticket first
  - preserves the existing required fields
  - carries forward `description`, normalized label names, and `projectFields`
  - skips the write entirely when the ticket is already in the requested status
- Examples:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py status-transition ORGMGMT-01-12837582 --status "In Progress" --dry-run
python3 skills/ots-ticket/scripts/ots_ticket_api.py status-transition ORGMGMT-01-12837582 --status "In Progress"
```

- Equivalent raw request shape:

```json
{
  "title": "<existing title>",
  "issueType": "<existing issue type>",
  "projectKey": "<existing project key>",
  "severity": 3,
  "status": "In Progress",
  "labels": [],
  "projectFields": []
}
```

### Label mutation

- Path: `20180828/tickets/{ticketId}`
- Method: `PUT`
- Helper behavior:
  - fetches the current ticket first
  - preserves the existing required fields and current status
  - computes the resolved label set for add, remove, or set semantics
  - sends the full update body with the resolved `labels`
- Examples:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py labels-add ORGMGMT-01-12837582 --labels needs-triage,ops-review --dry-run
python3 skills/ots-ticket/scripts/ots_ticket_api.py labels-remove ORGMGMT-01-12837582 --labels stale-label
python3 skills/ots-ticket/scripts/ots_ticket_api.py labels-set ORGMGMT-01-12837582 --labels sev3,autocut
python3 skills/ots-ticket/scripts/ots_ticket_api.py labels-set ORGMGMT-01-12837582 --labels ""
```

- Equivalent raw request shape after resolution:

```json
{
  "title": "<existing title>",
  "issueType": "<existing issue type>",
  "projectKey": "<existing project key>",
  "severity": 3,
  "status": "<existing status>",
  "labels": ["needs-triage", "ops-review"],
  "projectFields": []
}
```

### Resolution details update

- Path: `20180828/tickets/{ticketId}`
- Method: `PUT`
- Helper behavior:
  - fetches the current ticket first
  - preserves the existing required fields, status, labels, `projectFields`, and description
  - preserves current resolution-detail values for any summary fields you do not override
  - updates any combination of:
    - `rootCauseDescription`
    - `resolutionDescription`
    - `statusUpdate`
- Examples:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py resolution-details-update ORGMGMT-01-12837582 --root-cause-description "Brief root cause" --resolution-description "Brief remediation" --status-update "Brief current status" --dry-run
python3 skills/ots-ticket/scripts/ots_ticket_api.py resolution-details-update ORGMGMT-01-12837582 --status-update "Monitoring recovery while detailed findings stay in the comment"
```

- Equivalent raw request shape after resolution:

```json
{
  "title": "<existing title>",
  "issueType": "<existing issue type>",
  "projectKey": "<existing project key>",
  "severity": 3,
  "status": "<existing status>",
  "labels": ["needs-triage", "ops-review"],
  "projectFields": [],
  "rootCauseDescription": "Brief root cause",
  "resolutionDescription": "Brief remediation",
  "statusUpdate": "Brief current status"
}
```

## Generic Request Mode

Use `request` when the ticket payload exposes:

- an attachment path
- an absolute download URL
- a related-resource path not covered by the dedicated subcommands

Examples:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py request "20180828/tickets/ORGMGMT-01-12837582/someRelatedPath"
python3 skills/ots-ticket/scripts/ots_ticket_api.py request "/20180828/tickets/ORGMGMT-01-12837582/comments" --query limit=50
python3 skills/ots-ticket/scripts/ots_ticket_api.py request "https://ticketing-platform.us-chicago-1.oci.oraclecloud.com/20180828/tickets/ORGMGMT-01-12837582/comments?limit=5"
python3 skills/ots-ticket/scripts/ots_ticket_api.py request "<attachment path or url>" --download /tmp/attachment.bin
```

## Notes

- `request --download` is the safest way to fetch attachments because attachment endpoints can vary by payload shape.
- For JSON reads, the helper prints only the `data` payload by default. Use `--envelope` to include headers and status.
- `comment-create`, `status-transition`, the explicit label-mutation commands, and `resolution-details-update` are the supported write actions in this skill right now.
