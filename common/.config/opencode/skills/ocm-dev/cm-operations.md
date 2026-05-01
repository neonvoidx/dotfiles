# CM operations (manual)

When Sheepy/Seeks templates aren't available or time pressure requires a manual CM, follow this process. For automated CM creation via Sheepy, see `ocm-runbooks/shared/how-tos/create-cm.md`.

## CHANGE project structure

CMs live in the `CHANGE` project on `jira-sd.mc1.oracleiaas.com` as `Change Request` issue type.

### Field mappings

| Field ID | Label | Content |
|---|---|---|
| `customfield_10308` | Deployment Plan | Commit link, release type, realm/release link table |
| `customfield_10401` | Validation | Post-deployment verification steps |
| `customfield_10409` | Implementation Plan / Rollback | Rollback commit link and procedure |
| `customfield_11705` | Executive Summary | Why this change, business context |
| `customfield_14403` | Brief Description | One-line change detail |
| `customfield_15700` | Change Location(s) | Multi-select of `OCx-region-name` values |
| `customfield_16400` | Test Results | Dev/alpha release links, test evidence |
| `customfield_19214` | Implementation Method | Manual, Semi-Automated, or Automated |
| `customfield_25301` | Change Category | Feature, Break-Fix, Security Patches, etc. |
| `customfield_26400` | Shepherd URL | Primary shepherd release link |

### MCP tool routing

| Action | MCP tool | Server |
|---|---|---|
| Read/search CM tickets | `mcp__atlassian-sd__jira_*` | jira-sd |
| Update CM fields | `mcp__atlassian-sd__jira_update_issue` | jira-sd |
| Read shepherd releases/phases/targets | `mcp__dope__get_shepherd_*` | DOPE |
| Read PR details | `mcp__bitbucket__get_pull_request` | Bitbucket |

## Creating a manual CM

### Inputs needed

1. **PR**: Merged PR in ocm-shepherd (or relevant repo) with the change details
2. **Shepherd release**: Either existing or to-be-created in the target flock
3. **Reference CM**: A recent completed CM in the same flock (see finding reference CMs below)

### Finding reference CMs

The CHANGE project uses `Change Request` as the issue type name (not "Change" or "Change Management"). Use this JQL:

```text
project = CHANGE AND issuetype = "Change Request" AND summary ~ "<flock-or-service-keyword>" ORDER BY created DESC
```

If that returns nothing, broaden with assignee or team-member names:

```text
project = CHANGE AND issuetype = "Change Request" AND assignee in (<team-member-1>, <team-member-2>) ORDER BY created DESC
```

Known reference CMs by flock:

| Flock | Reference CM | Description |
|---|---|---|
| ocm-customer-onboarding | CHANGE-2918724 | Deploy Catalina Pre-req stack change (per-realm releases) |

### Release strategy

**Single release vs per-realm releases:**

| Approach | When to use | Trade-off |
|---|---|---|
| Single release (all prod realms) | Default for infra changes where all regions get the same change | Simpler CM, avoids forwarded-approval issues across releases |
| Per-realm releases | When realms need independent rollout/rollback or different configs | Granular tracking but more setup work, forwarded approvals may not chain |

Use a single release unless there is a specific reason to split by realm.

### Shepherd release settings

When creating the release in the Shepherd UI:

| Setting | Default for infra CM |
|---|---|
| Release Type | RollForward |
| Change Type | Infrastructure |
| Change Class | Routine |
| Execution targets | All prod realm targets (skip R1, OC1-Dev) |

### Process

1. **Gather context**
   - Fetch PR details from Bitbucket: title, description, commit hash, Jira ticket references
   - Check shepherd flock for existing releases (`get_shepherd_releases`)
   - Fetch a reference CM from the CHANGE project (`jira_get_issue` with `fields=*all`)

2. **Draft all field content as copy-pasteable blocks**
   - Summary: concise title (~70 chars)
   - Description: Jira wiki markup with PR link, commit, release type, release link table
   - Deployment Plan (`customfield_10308`): commit link + `||Scope||Release||` table
   - Executive Summary (`customfield_11705`): business context
   - Test Results (`customfield_16400`): dev/alpha release links, test scenarios, results
   - Implementation/Rollback (`customfield_10409`): rollback commit link
   - Brief Description (`customfield_14403`): one-line summary

3. **Output for operator**
   - Lay out each field as a labeled, copy-pasteable block
   - Operator creates the ticket, creates the shepherd release, links them
   - Do not create via MCP unless explicitly asked

### Jira wiki markup conventions

Release link table:
```
||Scope||Release||
|All prod realms|[https://devops.oci.oraclecorp.com/t/<short-url>]|
```

Per-realm table (when using separate releases):
```
||Realm||Release||
|OC1|[https://devops.oci.oraclecorp.com/shepherd/projects/...]|
|OC4|[https://devops.oci.oraclecorp.com/shepherd/projects/...]|
```

Commit link:
```
[<short-hash>|https://bitbucket.oci.oraclecorp.com/projects/OCICM/repos/<repo>/commits/<full-hash>]
```

## Validating a CM

### When to validate

After the operator creates a CM, verify:
- Change Locations align with the shepherd release execution targets
- All required fields are populated and match the reference CM format

### Location alignment process

1. **Get release phases**: `get_shepherd_release_phases` → list of realms
2. **Get execution targets**: `get_shepherd_phase_execution_targets` → specific regions per realm
3. **Get CM locations**: Read `customfield_15700` from the CM ticket
4. **Three-way compare** (release realms vs CM realms vs reference CM):
   - Every realm in the release MUST appear in the CM locations
   - CM may over-declare (include gov realms not in release) — acceptable
   - Non-region entries (Backbone, missioncontrol) should NOT be in CM locations
5. **Fix discrepancies**: `jira_update_issue` on `customfield_15700` using `[{"value": "OCx-region-name"}, ...]` format

### Field completeness check

Compare your CM against the reference CM for these fields:

| Check | Field | Pass criteria |
|---|---|---|
| Commit referenced | `customfield_10308` | Contains valid Bitbucket commit link |
| Release linked | `customfield_10308` | Contains shepherd release URL(s) |
| Rollback defined | `customfield_10409` | Contains rollback commit (NOT copied from reference) |
| Test evidence | `customfield_16400` | Links to successful dev/alpha releases |
| Locations set | `customfield_15700` | Aligns with release execution targets |
| Peer approver | Peer Approver field | Not blank before requesting approval |

## After CM creation

- Paste CM URL into the shepherd release phase's `cmUrl` field (Shepherd UI)
- Request peer approval (designated peer approver)
- Ensure a second peer reviews before deployment begins
- Clean up any halted/abandoned releases in the flock
