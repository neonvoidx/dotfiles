# ocm-dev — Routing & Reference

Consolidated navigation for OCM engineering. Substantive content is in sub-files; everything else routes to canonical external resources.

## Substantive facets

| Topic | File | What it provides |
|-------|------|-----------------|
| AI/MCP governance | ai/INDEX.md | OCM AI practice, MCP tool defaults, migration assistant posture |
| Migration Assistant playbook | ai/migrationAssistantPlaybook.md | 5-stage pipeline for safe AI migration assistance |
| North Star 2026 | north-star.md | Strategic objectives, 3 streams, phase timeline, metrics |
| Release terms glossary | release-terms.md | 15 terms (bake, canary, CM, GO/NO-GO, etc.) with workflow links |
| Script inventory | scripts.md | 10 oracle-quickstart categories classified by mutability |
| Script safety rubric | safety-rubric.md | 4 classification levels + 7-step preflight checklist |
| CM operations (manual) | cm-operations.md | CHANGE project field mappings, manual CM creation, CM validation |
| Team reference tables | team-reference-tables.md | 5xx queries, OTS templates, Grafana annotations, Shepherd/Jira/Splat mappings |
| Jira MCP conventions | jira-mcp-conventions.md | Two-server routing, comment retrieval, CM query patterns |
| DOPE MCP conventions | dope-mcp-conventions.md | Broad-first query strategy, logging namespace lookup, auth expiry |
| Execution baselines detail | execution-baselines-detail.md | Inputs, audit expectations, steps, evidence, failure modes for execution governance |
| Access warmups detail | access-warmups-detail.md | Inputs, sequencing, outputs, evidence, failure modes for access warmups |
| Handoff note template | handoff-template.md | Multi-shift continuity handoff template (markdown) |

## Pack workflow routing

| Need | Workflow |
|------|---------|
| Stuck/failed migration triage | `workflows/ocm-migration-triage.md` |
| Observability investigation (dashboards/logs/metrics) | `workflows/ocm-observability-investigate.md` |
| Oncall handoff note | `workflows/generate-handoff-note.md` |
| Incident postmortem | `workflows/ocm-incident-postmortem.md` |
| Release readiness (GO/NO-GO) | `workflows/ocm-release-readiness.md` |
| Shepherd deployment | `workflows/ocm-shepherd-deploy.md` |
| CM creation/validation | `ocm-dev/cm-operations.md` (manual) or `ocm-runbooks/shared/how-tos/create-cm.md` (Sheepy) |
| Prerequisites drift check | `workflows/ocm-prereqs-drift-check.md` |
| Docs drift check | `workflows/ocm-docs-drift-check.md` |

Execution order for incidents: triage → investigate → handoff → postmortem.

## API surfaces

| Surface | Link |
|---------|------|
| OCM public API | https://docs.oracle.com/en-us/iaas/api/#/en/ocm/20220919/ |
| OCB public API | https://docs.oracle.com/en-us/iaas/api/#/en/OCB/20220509/ |
| Internal endpoints (API Summary) | https://confluence.oraclecorp.com/confluence/display/OCIMigrationDR/API+Summary |

## Confluence anchors

### Core engineering

| Topic | Page |
|-------|------|
| Realm Build Runbook | https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12075203796 |
| Deployment plan tracker | https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19083594114 |
| OCM on-call: plugin deployment | https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19047080351 |
| Technical Content dashboard | https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12404907423 |
| Migration Prerequisites v2.3 | https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=18525161800 |
| Prerequisites v2.3 (creating) | https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19254551310 |
| North Star 2026 | https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=18171568883 |
| Target Persona | https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12404907494 |
| OCI Migrate User Model | https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12404907952 |

### Onboarding (new hire)

| Topic | Page |
|-------|------|
| New Hire Onboarding | https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12404907402 |
| Buddy / mentorship | https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12404907481 |
| Migration service SDLC | https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12404907522 |
| Technical Guide | https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12404907551 |
| Cheat Sheet | https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12404908210 |
| Replication guide | https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12404909808 |
| Git/PR Guide | https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12813702839 |
| IntelliJ Settings | https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12404907489 |
| OCI CLI Tool | https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12404907508 |
| Aider intro | https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=16839771303 |

### AI / agent initiatives

| Topic | Page |
|-------|------|
| MCP server expansion (OCM+OCB) | https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=18943784416 |
| Starfix agent workflows | https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=17742149606 |
| Ops stabilization plan | https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=18120506580 |
| Ops stabilization tracker | https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=18269296927 |

## Repo anchors

| Repo | Key paths |
|------|-----------|
| ocm-shepherd | AGENTS.md, configs/ |
| ocm-runbooks | index.md, shared/, ocm-migration/, ocb-discovery/, ocb-agent/, ocm-inventory/ |
| ocm-ops-tools | , ocm-cline-workflows/, release_scripts/ |
| oracle-quickstart/oci-cloud-migrations | Scripts/ (see scripts.md for classified inventory) |

### Must-link runbooks (paths inside ocm-runbooks)

Shared:
- `shared/how-tos/create-cm.md` — CM creation (Sheepy)
- `shared/how-tos/handle-customer-requests.md` — Customer request handling
- `shared/how-tos/maintain-ocm-instances-database.md` — OCM instances DB

Service-specific:
- `ocm-migration/how-tos/deploy-application-shepherd.md` — Deploy (migration)
- `ocm-migration/how-tos/cold-start.md` — Cold start
- `ocm-migration/how-tos/root-cause-analysis.md` — RCA
- `ocm-migration/how-tos/region-build-mfo-issues.md` — Region build MFO
- `ocb-discovery/how-tos/deploy-application-shepherd.md` — Deploy (discovery)
- `ocb-agent/oncall/respond-to-incident.md` — Incident response (agent)

## Developer experience phases

Progressive disclosure for OCM/OSO engineers:

| Phase | OCM anchor | Common OCI tools |
|-------|------------|-----------------|
| Access / bootstrap | New Hire Onboarding | DevOps Portal, SCM, Phonebook |
| Local dev (clone/build/test) | Technical Guide | Build Service, Pipelines, Workflow, Kiev |
| Deploy / release | Shepherd pointers in onboarding | Shepherd, Guardrails, Splat |
| Security / compliance | — | Security Bar, WLP, SSv2 |
| Operate (tickets/oncall) | OCEAN account in onboarding | OTS, Ocean, Ops Central |
| Region build | — | ToRB, MFO, ViBE, RBC, RBDL |

## OCI internal developer docs (`oci-kb` MCP)

The `oci-kb` MCP server provides semantic search over the full corpus of internal-docs.oraclecorp.com — every tool listed in the developer experience phases table above, plus hundreds more.

**When to use:** You need to understand how an OCI internal tool works (Shepherd, Pipelines, OTS, oci-ops, Guardrails, etc.) and local docs or this skill's anchors don't cover the specific question. The KB covers tool documentation, not Confluence pages or team-specific content.

**When NOT to use:** Team-specific processes (use this skill's Confluence anchors or runbook links), customer-facing OCI docs (use public docs or oci-mcp), or Jira/Confluence content (use atlassian MCP).

**Usage pattern — always two steps:**
1. `search(query)` — returns snippets with `doc_id` and `source_text`. Scan the snippets to find the right document.
2. `getDocument(document_id)` — fetch the full markdown for the document you need. Use the `doc_id` from step 1.

Don't skip step 2 — search snippets are section headers and opening paragraphs, not the full content. The actionable detail (commands, config examples, API parameters) is in the full document.

**What's in scope:** All markdown from internal-docs.oraclecorp.com/en-us/iaas/ — OCI internal tooling documentation (Shepherd, Pipelines, Build Service, SCM, OTS, OCEAN, Guardrails, Pegasus, Kiev, and ~200 more).

**What's NOT in scope:** Confluence pages, team-specific runbooks, Jira tickets, customer-facing OCI public docs, or code repositories.

## Confluence governance

- Use the `confluence-navigator` agent for Confluence search/navigation.
- Author history is a staleness signal — capture created/updated metadata.
- Slack is a social routing hint, not a machine-queryable source.

## Migration lifecycle

Discovery → plan → replicate → deploy → validate → cutover.

Gate/triage points at each transition. For stuck migrations, start with the migration triage workflow.
