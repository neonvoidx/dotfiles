# CM Review Configuration

Use a shared TOML config when multiple service teams want `CM Review` to validate manual or hybrid CMs against team-specific runbooks.

The default design goal is simple:

- identify which service the CM belongs to
- tell the skill where that service's runbooks live

Only add more structure when repo search becomes ambiguous.

Prefer one shared config file with multiple `[[team]]` blocks over many one-off files.

## Recommended Shape

```toml
[[team]]
name = "Example Service"
description = "Service-specific CM review"

[team.match]
jira_projects = ["CHANGE"]
service_owner_values = ["Example Service"]
service_names = ["Example Service"]
ticket_labels = ["example-service"]
keywords = ["example", "example api", "example control plane"]

[team.runbooks]
bitbucket_repo = "https://bitbucket.example/projects/EXAMPLE/repos/runbooks/browse"
local_repo_path = "/absolute/path/to/local/runbooks"
preferred_source = "local_repo"
```

## Field Notes

### `team.match`

Use these fields to help the skill decide that the CM belongs to this service team.

Supported fields:

- `jira_projects`
- `service_owner_values`
- `service_names`
- `ticket_labels`
- `keywords`

Use multiple signals when possible. A CM ticket may live in a shared project such as `CHANGE`, so project key alone is often not enough.

For CM review, `jira_projects` is the normal ticket-routing field.

Prefer `service_owner_values` when the CM ticket has a stable `service owner` field. It is usually the strongest team-resolution signal for CM review.

### `team.runbooks`

This block tells the skill where to resolve runbooks.

Suggested fields:

- `bitbucket_repo`
- `local_repo_path`
- `preferred_source`

Supported `preferred_source` values:

- `local_repo`
- `bitbucket`
- `runbook_service`
- `mixed`

In the default model, this is enough. The skill should:

1. resolve the `[[team]]` block
2. classify the ticket into `release-backed`, `runbook-backed`, or `hybrid`
3. identify the likely runbook source and search terms from ticket/config evidence before approval, without fetching the runbook
4. present the likely runbook source, search terms, and ambiguity in the pre-execution plan
5. after approval, search the runbook source, select the best runbook match, and use it to validate implementation, validation, and rollback

## Optional Advanced Overrides

Use the blocks below only when the runbook repo is too noisy or ambiguous.

### `team.runbooks.documents`

Use one document block per durable runbook the team wants the skill to prefer.

Supported fields:

- `name`
- `relative_path`
- `search_terms`
- `notes`

Use exact `relative_path` when the team already knows the canonical runbook. Use `search_terms` when one class may map to several similarly named runbooks.

### `team.change_classes`

Use one block per CM class the team wants to support when repo search alone does not give consistent results.

Supported fields:

- `kind`
- `summary_keywords`
- `runbook_documents`
- `required_ticket_fields`
- `required_targets`
- `required_validation`
- `required_rollback`
- `disallow_generic_rollback`
- `notes`

Treat these as review anchors, not strict string-match requirements. The CM can satisfy a requirement with equivalent wording when the intent is clear.

Use these advanced overrides only when needed:

- the repo contains many similar runbooks
- several teams share the same runbook repo
- one CM class needs a canonical runbook
- one team has stricter validation or rollback expectations than the generic skill
