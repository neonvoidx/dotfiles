---
name: jira-ticket
description: Read and write Jira-SD or Jira OCI tickets using the shared Atlassian MCP env files or explicit CLI overrides. Use when Codex needs to build JQL from filters such as project, severity, ticket key, time window, or sorting; search Jira; read issue details with custom fields; inspect comments and activity history; add and reply to issue comments; or mutate Jira labels.
---

# Jira Ticket

Use this skill for Jira issue search, ticket inspection, changelog review, comment posting, status transitions, label updates, and short investigation-summary field updates.

The bundled API helper loads Jira auth from the same dotenv files used by the Jira MCPs:

Expected variables:
- Jira-SD: `~/.env`
- Jira OCI: `~/.env.jira-oci`
- Required keys in the selected file: `JIRA_URL` and `JIRA_PERSONAL_TOKEN`
- Backward-compatible token fallback: `JIRA_TOKEN`

Override the selected file with `JIRA_SD_ENV_FILE`, `JIRA_OCI_ENV_FILE`, `JIRA_TICKET_ENV_FILE`, or `--env-file` when needed.

If the selected Jira instance is missing URL or token values, stop and ask the user to populate the env file before making live Jira calls.

## Quick Start

Build JQL from structured inputs:

```bash
python3 skills/jira-ticket/scripts/jql_builder.py \
  --project TENLS \
  --severity 2,3 \
  --ticket-key TENLS-12345 \
  --created-since -7d \
  --sort-field created \
  --sort-order DESC
```

Search with that JQL:

```bash
python3 skills/jira-ticket/scripts/jira_ticket_api.py search \
  --jql 'project = "TENLS" AND Severity in ("2","3") ORDER BY created DESC' \
  --max-results 50
```

Use Jira OCI explicitly when the ticket lives there:

```bash
python3 skills/jira-ticket/scripts/jira_ticket_api.py --jira-instance oci ticket PROJECT-123
```

Read one ticket with all fields plus a field-id map:

```bash
python3 skills/jira-ticket/scripts/jira_ticket_api.py ticket TENLS-12345
```

Read comments and activity history:

```bash
python3 skills/jira-ticket/scripts/jira_ticket_api.py comments TENLS-12345
python3 skills/jira-ticket/scripts/jira_ticket_api.py activities TENLS-12345
python3 skills/jira-ticket/scripts/jira_ticket_api.py bundle TENLS-12345
```

Post a comment or create a reply-style comment:

```bash
python3 skills/jira-ticket/scripts/jira_ticket_api.py comment-add TENLS-12345 --text "Investigating the latest failure signature."
python3 skills/jira-ticket/scripts/jira_ticket_api.py comment-reply TENLS-12345 --comment-id 10001 --text "I confirmed this is the same root cause." --dry-run
python3 skills/jira-ticket/scripts/jira_ticket_api.py transition-status TENLS-12345 --target-status "In Progress" --dry-run
python3 skills/jira-ticket/scripts/jira_ticket_api.py labels-add TENLS-12345 --labels needs-triage,ops-review --dry-run
python3 skills/jira-ticket/scripts/jira_ticket_api.py resolution-details-update TENLS-12345 --root-cause-description "Short root cause" --resolution-description "Short remediation" --status-update "Short current status" --dry-run
python3 skills/jira-ticket/scripts/jira_ticket_api.py labels-remove TENLS-12345 --labels stale-label --dry-run
python3 skills/jira-ticket/scripts/jira_ticket_api.py labels-set TENLS-12345 --labels sev3,autocut --dry-run
```

## Workflow

### 1. Build the JQL intentionally

- Prefer `jql_builder.py` when the user describes filters in plain language.
- Supported filters include:
  - project
  - severity
  - ticket key
  - created or updated time windows
  - status
  - assignee
  - reporter
  - labels
  - arbitrary raw conditions
  - sorting
- If the user already gives exact JQL, pass it directly to `search`.

### 2. Read full ticket context

- Start with:

```bash
python3 skills/jira-ticket/scripts/jira_ticket_api.py ticket <ticket-key>
```

- The `ticket` command requests `*all` fields by default, resolves Jira field ids, and adds:
  - `_field_map`: field id to Jira field name
  - `_named_fields`: issue fields re-keyed by readable Jira field name when possible

### 3. Read comments and activity history

- Use:

```bash
python3 skills/jira-ticket/scripts/jira_ticket_api.py comments <ticket-key>
python3 skills/jira-ticket/scripts/jira_ticket_api.py activities <ticket-key>
```

- `activities` returns changelog histories from Jira issue expansion.
- `bundle` is the fastest way to return issue details, comments, and changelog together.

### 4. Post comments carefully

- Use `comment-add` for a normal new comment.
- Use `comment-reply` when the user wants to reply to an existing comment.
- If a caller workflow skill defines the comment format, follow that workflow skill and use this skill only for posting.
- Jira issue comments are not truly threaded in the standard issue API. The helper implements reply behavior by posting a new issue comment that references the target comment id and author.
- Prefer `--dry-run` first when drafting or validating a comment body.

### 5. Keep writes explicit

- Only post comments when the user clearly asks to do it.
- Use `transition-status` when a caller workflow explicitly needs a Jira status move, such as moving an open incident to `In Progress` after posting an investigation update.
- `transition-status` resolves the available Jira workflow transitions first and matches by target status name, so it is safer than assuming a fixed transition id.
- Use `labels-add`, `labels-remove`, and `labels-set` when the user explicitly wants Jira labels changed.
- Jira label mutations now preflight the issue `editmeta` first and refuse to write when the issue or `labels` field is not editable.
- Prefer `--dry-run` before a label mutation when the target issue is sensitive or the requested labels are generated dynamically.
- Use `resolution-details-update` when a caller workflow needs to keep the full investigation in the Jira comment while also updating the short companion fields `Root Cause Description`, `Resolution Description`, and `Status Update`.
- `resolution-details-update` preflights Jira `editmeta` for the requested fields and refuses to write when a field is not editable on the current issue.
- Prefer `--dry-run` before a resolution-details update when the ticket is sensitive or the summaries were generated from a larger RCA comment.
- After posting, fetch recent comments to confirm the update if the user wants verification.
