# OCM Team Reference Tables

Extracted from: `rules/ocm-team.md` | Last verified: 2026-03-12

## 5xx query information

| Service | 5xx Metric | T2 Project | T2 Fleet | Grafana panel | Service tenancy |
|---|---|---|---|---:|---|
| ocm-inventory | `ResponseOut_DM.StatusFamily.5XX[5h]{TrafficSource=EXTERNAL}.grouping().count()` | `ocm-inventory` | `ocm-inventory-api` | 128 | `ocminv` |
| ocb-discovery | `ResponseOut_DM.StatusFamily.5XX[5h]{TrafficSource=EXTERNAL}.grouping().count()` | `ocb-discovery` | `ocb-discovery-api` | 143 | `ocmdis` |
| ocm-migration | `ResponseOut_DM.StatusFamily.5XX[5h]{TrafficSource=EXTERNAL}.grouping().count()` | `ocm-migration` | `ocm-migration-api` | 133 | `ocmmig` |
| ocb-agent | `ResponseOut_DM.StatusFamily.5XX[5h]{TrafficSource=EXTERNAL}.grouping().count()` | `OcbControlPlane` | `agent-service-control-plane-api` | 134 | `ocbservice_prod` |

## OTS queries

General query template to find sev2s between two date intervals for a region + service:

```text
project in (OCMSD,OCB) and severity in (2,3) and component ~ <service-name> and title ~ <region-name> and Created > <start date> and Created < <end date>
```

On-call handoff query (last 10h, sev1-2, exclude telemetry reporters):

```text
project in (OCMSD, OCB) AND created > -10h AND Severity in (1, 2) AND reporter NOT IN (
  "jirasd-telemetry-uk-london-3",
  "jirasd-telemetry-us-tukwila-3",
  "jirasd-telemetry-uk-london-2"
)
```

## Grafana annotation conventions

- dashboard_id: `h8W0McaSz`
- tag/comment: `Autoschrute annotated`

| Service | Panel ID |
|---|---:|
| ocm-inventory | 128 |
| ocb-discovery | 143 |
| ocm-migration | 133 |
| ocb-agent | 134 |

## Shepherd project mappings

Shepherd project names differ from terraform directory names. Use these when querying DOPE or navigating the Shepherd UI.

| Terraform directory | Shepherd project | Flock | CM Jira project | CM Jira instance |
|---|---|---|---|---|
| `ocm_customer_onboarding_shepherd` | `oracle-cloud-bridge` | `ocm-customer-onboarding` | `CHANGE` | `jira-sd.mc1.oracleiaas.com` |

For other service flocks, the Shepherd project is also `oracle-cloud-bridge`. Flock names follow the pattern `ocm-<service>` or `ocb-<service>`.

## Jira project routing

| Ticket type | Jira project | Jira instance | Issue type |
|---|---|---|---|
| Change Management (CM) | `CHANGE` | `jira-sd.mc1.oracleiaas.com` | `Change Request` |
| Operational incidents (sev1-3) | `OCMSD`, `OCB` | `jira-sd.mc1.oracleiaas.com` | — |
| Engineering work (stories, bugs) | `OCICM` | `jira.oci.oraclecorp.com` | Story, Bug, Task |

When searching for CMs, use `issuetype = "Change Request"` (not "Change" or "Change Management").

## CM creation defaults

When asked to create a CM:

1. **Draft content for the operator** — do not create the ticket via MCP unless explicitly asked.
2. Output copy-pasteable blocks: summary, description (Jira wiki markup), field values.
3. Include in the description: PR link, commit hash, release type, release link table, pre-CM validation panel with test evidence.
4. Reference an existing CM in the same flock as the format template (e.g., search CHANGE project for recent tickets with the flock name).

The operator creates the ticket, creates the shepherd release, links them, and requests peer approval. The agent's job is to prepare the content so the operator can execute without drafting from scratch.

## Splat service mappings

| Service | Splat service |
|---|---|
| ocm-inventory | `ocb-inventory-service` |
| ocb-discovery | `ocb-discovery-api` |
| ocm-migration | `ocm-migration-api` |
| ocb-agent | `ocb-agent-svc` |
