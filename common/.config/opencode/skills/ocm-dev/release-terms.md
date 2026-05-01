# OCM release terms (glossary)

## Scope

- This is a **reference-only** glossary for release guardrails, rollout strategies, and change-management (CM) evidence.
- It intentionally **does not** restate governance or mutation rules; it links to the canonical workflows/rules.

## Canonical workflow links

- Release readiness (GO/NO-GO + evidence expectations): [`ocm-release-readiness`](../../../workflows/ocm-release-readiness.md)
- Shepherd deploy (guardrails, rollout/rollback posture): [`ocm-shepherd-deploy`](../../../workflows/ocm-shepherd-deploy.md)

## Confluence anchors (canonical plan context)

- Deployment plan (release-cycle tracker): https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19083594114
- Realm Build Runbook (sequencing + deployment mechanics): https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12075203796

## Terms

### Bake (bake time)

The observation period after a rollout slice completes where you watch the defined health signals for regressions **before expanding scope**.

### Canary

A deliberately small initial rollout slice used to reduce blast radius and validate health signals before wider expansion.

### Change management (CM)

The organizational process and system of record (often a ticket) that captures intent, risk, approvals, execution window, and post-change validation for a release.

### CM evidence

The links and artifacts that demonstrate the release was planned, approved, executed safely, and validated. Typical evidence includes:

- release identifier + pinned versions (tags/digests/SHAs)
- release notes / operator callouts
- rollout plan (including any canary/bake assumptions)
- rollback story (meaning, owner role, and time-to-restore expectation)
- verification signals and results (CI/build links, dashboards/alarms, health checks)
- approvals (who/what role approved, and where it is recorded)

Authoritative expectations and mutation posture live in: [`ocm-execution-baselines`](../../../rules/ocm-execution-baselines.md).

### Expansion (rollout expansion)

The act of increasing rollout scope from an initial slice (for example: canary) to additional slices, regions, realms, environments, or services.

### GO / NO-GO

The release readiness decision:

- **GO**: evidence indicates the release is safe to start under the declared guardrails and rollback story.
- **NO-GO**: a blocking requirement is missing or risk is not explicitly accepted/approved.

See readiness criteria and the readiness report contract: [`ocm-release-readiness`](../../../workflows/ocm-release-readiness.md).

### Guardrails

Preconditions and operator constraints that must hold before starting (and while expanding) a rollout, such as frozen scope, recorded approvals, defined stop conditions, observability readiness, and a usable rollback story.

### Mutation gate

The explicit stop-and-confirm requirement before **any** action that changes external state (tickets, SCM, deployments, approvals, etc.). It exists to prevent accidental execution and to ensure rollback + evidence expectations are declared up-front.

Canonical: [`ocm-execution-baselines`](../../../rules/ocm-execution-baselines.md).

### Pinned versions

Explicit, immutable identifiers for what is being released (for example: image digests, tags with digests, package versions, or commit SHAs). This is required to make both rollout and rollback unambiguous.

### Rollback

The act of restoring the system to a prior known-good state (as defined for the release) after a failed or unsafe rollout.

### Rollback story

The release-specific definition of rollback that answers:

- what “rollback” means for this release (target version/state)
- who is authorized to execute it (role)
- how quickly you expect to restore service (time-to-restore target)
- what signals prove rollback success (rollback verification)

See the deployment workflow’s rollback posture and verification checklist: [`ocm-shepherd-deploy`](../../../workflows/ocm-shepherd-deploy.md).

### Rollout strategy

The plan for how scope expands over time (slice order, canary/bake assumptions, checkpoints, and stop conditions). The deployment mechanics and sequencing are owned by the Realm Build Runbook and the active Deployment plan (see anchors above).

### Slice

A bounded portion of the total target scope used for staged rollout and verification (for example: a single environment, region, realm, or service subset).

### Stop conditions

The agreed signals that pause or stop rollout expansion (for example: error rate, latency, alarms, or customer impact), and the rule for deciding **hold** vs **rollback**.

### Shepherd (deployment)

The deployment system/workflow family used for OCM releases; this glossary treats Shepherd mechanics as **external** and points to the canonical runbooks and Shepherd repo truth rather than duplicating commands.

See: [`ocm-shepherd-deploy`](../../../workflows/ocm-shepherd-deploy.md).

## References (governance)

- Execution baseline (mutation gate + evidence posture): [`ocm-execution-baselines`](../../../rules/ocm-execution-baselines.md)
- Access warmups (governance pointers): [`ocm-access-warmups`](../../../rules/ocm-access-warmups.md)
