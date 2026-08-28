---
name: ots-ticket
description: Inspect Oracle Ticketing Platform tickets and related resources from an OCI CLI session-backed profile. Use when Codex needs to fetch ticket details, comments, activity history, project metadata, TQL search results, dashboards, subQueries, linked tickets, attachment resources, post ticket comments to ticketing-platform.us-chicago-1.oci.oraclecloud.com, or mutate ticket labels.
---

# OTS Ticket

## Overview

This skill is for Oracle Ticketing Platform work against `https://ticketing-platform.us-chicago-1.oci.oraclecloud.com/`. It packages a small helper script so Codex can reuse the same OCI session-backed auth flow instead of rebuilding raw requests each time.

Most commands are read-only. The supported write actions are:

- `comment-create`, which posts a ticket comment
- `status-transition`, which changes ticket status through the same `oci raw-request` transport used by the rest of the helper
- `labels-add`, `labels-remove`, and `labels-set`, which mutate ticket labels through the same `PUT` update flow
- `resolution-details-update`, which updates the short `Root cause description`, `Resolution description`, and `Status update` fields shown in the OTS Resolution Details section

## Quick Start

1. Confirm the OCI CLI session profile before calling the API.

```bash
oci --profile oc1 session validate --local
```

- If the session is expired, refresh it first:

```bash
oci --profile oc1 session refresh
```

2. Use the bundled helper for common reads:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py ticket ORGMGMT-01-12837582
python3 skills/ots-ticket/scripts/ots_ticket_api.py comments ORGMGMT-01-12837582 --limit 10
python3 skills/ots-ticket/scripts/ots_ticket_api.py comment-create ORGMGMT-01-12837582 --text "Investigated the latest 500s; backend dependency recovered and I am monitoring."
python3 skills/ots-ticket/scripts/ots_ticket_api.py status-transition ORGMGMT-01-12837582 --status "In Progress" --dry-run
python3 skills/ots-ticket/scripts/ots_ticket_api.py labels-add ORGMGMT-01-12837582 --labels needs-triage,ops-review --dry-run
python3 skills/ots-ticket/scripts/ots_ticket_api.py resolution-details-update ORGMGMT-01-12837582 --root-cause-description "Short root cause" --resolution-description "Short remediation" --status-update "Short current status" --dry-run
python3 skills/ots-ticket/scripts/ots_ticket_api.py labels-remove ORGMGMT-01-12837582 --labels stale-label --dry-run
python3 skills/ots-ticket/scripts/ots_ticket_api.py labels-set ORGMGMT-01-12837582 --labels sev3,autocut --dry-run
python3 skills/ots-ticket/scripts/ots_ticket_api.py activities ORGMGMT-01-12837582 --limit 10
python3 skills/ots-ticket/scripts/ots_ticket_api.py tql "(project = 'ORGMGMT' AND severity=2) AND operational scope != 'Central Ops'" --limit 60
```

## Workflow

### 1. Validate auth first

- Default to the `oc1` profile unless the user names another OCI CLI profile.
- The helper checks `oci session validate --local` before every request.
- When validation fails with an expired session, stop and ask the user to refresh the session instead of retrying blind API calls.

### 2. Read the core ticket context

- Start with the ticket payload:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py ticket <ticket-id>
```

- Then fetch nearby context:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py comments <ticket-id> --limit 20
python3 skills/ots-ticket/scripts/ots_ticket_api.py activities <ticket-id-or-ocid> --limit 20 --sort-order DESC
python3 skills/ots-ticket/scripts/ots_ticket_api.py linked-tickets <ticket-id>
```

- The `activities` command accepts either a human ticket id such as `ORGMGMT-01-12837582` or a ticket OCID.

### 3. Follow related resources when needed

- Use `project` for project metadata:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py project ORGMGMT
```

- Use `request` when the ticket payload exposes a relative path or absolute URL for a related resource, especially for attachment fetches or resource links that are not covered by a dedicated subcommand.
- For attachment downloads, pass the discovered path or URL and save it with `--download`:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py request "<attachment path or url>" --download /tmp/attachment.bin
```

### 4. Post a ticket comment when the user explicitly asks

- Keep comment posting intentional and evidence-based.
- If a caller workflow skill defines the comment format, follow that workflow skill and use this skill only for posting.
- The helper supports three input modes:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py comment-create <ticket-id> --text "Short update"
python3 skills/ots-ticket/scripts/ots_ticket_api.py comment-create <ticket-id> --text-file /tmp/comment.md
cat /tmp/comment.md | python3 skills/ots-ticket/scripts/ots_ticket_api.py comment-create <ticket-id> --stdin
```

- Use `--dry-run` to preview the resolved POST request without sending it:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py comment-create <ticket-id> --text "Short update" --dry-run
```

- In this environment, posting with only `text` creates an internal comment by default.
- After posting, verify success by fetching recent comments:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py comments <ticket-id> --limit 5
```

### 5. Transition ticket status when the user explicitly asks

- The helper uses a raw `PUT` to the ticket resource instead of shelling out to `oci-ops`.
- It first fetches the current ticket, preserves the required update fields, and then changes only the requested `status`.
- Preview first when the transition is sensitive:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py status-transition <ticket-id> --status "In Progress" --dry-run
```

- Run it for real only after you have confirmed the target status:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py status-transition <ticket-id> --status "In Progress"
```

- Verify the result with a follow-up read:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py ticket <ticket-id>
python3 skills/ots-ticket/scripts/ots_ticket_api.py activities <ticket-id> --limit 5
```

### 6. Mutate ticket labels when the user explicitly asks

- The helper uses the same raw `PUT` to the ticket resource, preserving the required ticket fields while replacing `labels` with the resolved set.
- Supported commands:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py labels-add <ticket-id> --labels needs-triage,ops-review --dry-run
python3 skills/ots-ticket/scripts/ots_ticket_api.py labels-remove <ticket-id> --labels stale-label --dry-run
python3 skills/ots-ticket/scripts/ots_ticket_api.py labels-set <ticket-id> --labels sev3,autocut --dry-run
```

- `labels-add` appends only labels that are not already present.
- `labels-remove` removes only labels that currently exist.
- `labels-set` replaces the label set exactly; passing an empty `--labels` value clears all labels.
- Prefer `--dry-run` first when the target ticket is sensitive or the label list was generated indirectly.

### 7. Update resolution details as part of default OTS writeback

- In the on-call investigation workflow, this is the default OTS companion step after the full ticket comment is ready.
- Keep the full investigation in the ticket comment. Use the Resolution Details fields only for concise summaries that help responders scan the ticket quickly.
- The helper preserves the current required ticket fields, description, labels, and any existing resolution-detail values you do not override.
- Supported fields:
  - `--root-cause-description`
  - `--resolution-description`
  - `--status-update`
- Preview first when the ticket is sensitive:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py resolution-details-update ORGMGMT-01-12837582 --root-cause-description "Dependency timeout in ap-seoul-1 worker path" --resolution-description "Mitigated after worker retry and follow-up investigation is in the comment" --status-update "Monitoring recovery while owner follows up" --dry-run
```

- Run it for real only after you have confirmed the short summaries:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py resolution-details-update ORGMGMT-01-12837582 --root-cause-description "Dependency timeout in ap-seoul-1 worker path" --resolution-description "Mitigated after worker retry and follow-up investigation is in the comment" --status-update "Monitoring recovery while owner follows up"
```

- Verify with a follow-up read:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py ticket ORGMGMT-01-12837582
```

### 8. Search and browse broader ticket queues

- TQL ticket search:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py tql "<tql expression>" --limit 60
```

- Dashboards and subqueries:

```bash
python3 skills/ots-ticket/scripts/ots_ticket_api.py dashboards --page 1
python3 skills/ots-ticket/scripts/ots_ticket_api.py subqueries --limit 5
```

## Command Notes

- The helper uses `oci raw-request --auth security_token` for JSON reads and comment creation because that flow is already proven to work with this service.
- Status transitions use the same raw-request transport with a `PUT` to the ticket endpoint.
- Binary download mode reads the profile's `security_token_file` and sends it as a bearer token so attachments can be saved to disk.
- Limit writes to `comment-create`, `status-transition`, the explicit label-mutation commands, and `resolution-details-update`. If a user asks to mutate any other ticket field, stop and confirm the exact API and intent before adding more write behavior.

## References

- Read `references/endpoints.md` for the versioned endpoint map, TQL examples, and request patterns.
