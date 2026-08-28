# CM Change Classes

Use this reference when the CM is not obviously a standard infra or application rollout.

The goal is to classify the CM into a reusable review path without hard-coding one team's wording into the main skill.

## Review Modes

- `release-backed`
  The source of truth is one or more linked Shepherd releases.
- `runbook-backed`
  The source of truth is a service-specific runbook or operator procedure.
- `hybrid`
  The source of truth is both a runbook and a linked release, repo change, or config rollout.

## Common Change Classes

### `data-fix`

Use when the CM changes data records, API-managed resources, or adhoc state outside a standard product rollout.

Typical signals:

- summary or description contains `data fix`, `manual fix`, `adhoc`, `backfill`, `repair`, `update record`, `API change`, or `subscription update`
- execution mentions an internal API, script, database action, or operator-managed resource mutation
- validation is expected to prove a before and after data state

Review anchors:

- exact targets are identified
- mutation scope is bounded
- read-before-write, backup, export, or equivalent restoration prep is defined when applicable
- execution steps are explicit and repeat-safe
- post-change verification proves the intended state
- rollback restores the prior state or provides a concrete containment path

### `host-restart`

Use when the CM intentionally restarts one or more hosts, instances, or pools.

Typical signals:

- summary or description contains `restart`, `bounce`, `reboot`, or `recycle`
- runbook references ODO pools, instance pools, or instance reboot flows

Review anchors:

- exact host, pool, region, and AD scope is identified
- traffic drain or failover handling is documented when needed
- restart procedure is explicit
- post-restart health checks are explicit
- abort or escalation conditions are explicit

### `host-replacement`

Use when the CM replaces or evacuates a failing host and restores workload elsewhere.

Typical signals:

- summary or description contains `replace host`, `host replacement`, `evacuate`, or `move workload`
- execution implies taking a host out of service and restoring capacity elsewhere

Review anchors:

- failing host or capacity unit is identified
- workload isolation, drain, or failover steps are documented
- replacement or restoration target is documented
- rejoin or cutback checks are documented
- rollback or safe-restoration path is concrete

### `host-reprovision`

Use when the CM reprovisions an instance, image, pool member, or host-local runtime.

Typical signals:

- summary or description contains `reprovision`, `rebuild`, `reimage`, or `recreate`
- the change depends on a provisioning baseline or replacement artifact

Review anchors:

- exact host or pool scope is identified
- source image, config, or provisioning baseline is identified
- prechecks and data persistence concerns are covered
- post-reprovision health and registration checks are covered
- rollback or alternate restoration target is concrete

### `host-maintenance`

Use when the CM performs a narrow operational task on hosts or service runtimes that is not a normal release.

Typical signals:

- summary or description contains `maintenance`, `manual intervention`, `service restart`, or host-level package or daemon steps
- execution references host login, daemon restarts, or one-off operational commands

Review anchors:

- exact scope is identified
- prerequisites and approvals are documented
- execution steps match the runbook
- validation confirms service health, not just command completion
- rollback or escalation path is concrete

## Mode Selection Heuristics

Choose `release-backed` when:

- the CM is mainly implemented through Shepherd releases
- the ticket links release IDs and the release evidence explains the intended change

Choose `runbook-backed` when:

- there is no meaningful release evidence
- the primary execution path is a service runbook, host procedure, API procedure, or manual remediation

Choose `hybrid` when:

- the CM uses both a service runbook and a release-backed rollout
- the runbook describes how to prepare, execute, validate, or roll back a release-backed change

## Classification Notes

- Do not rely on one keyword alone when choosing the class.
- Use the CM text, linked repos, release links, target resources, and team config together.
- If two classes fit, prefer the one that best explains the real rollback path.
- If still ambiguous, say so in the review assumptions and explain which class you used and why.
