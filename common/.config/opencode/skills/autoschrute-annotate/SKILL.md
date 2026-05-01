---
name: autoschrute-annotate
description: '[Workflow] Investigate elevated 5xx windows for an OCM service and optionally write a Grafana annotation after explicit approval.'
source_type: workflow
metadata:
    last_updated: 2026-03-10T00:00:00Z
    owner: ocm
---

# /autoschrute-annotate - Autoschrute annotation workflow

## Inputs

- service name (`ocm-inventory`, `ocb-discovery`, `ocm-migration`, or `ocb-agent`)
- region (for example `us-ashburn-1`)
- start date (`YYYY-MM-DD`)
- end date (`YYYY-MM-DD`)
- annotation intent:
  - `investigate-only`
  - `investigate-and-annotate`

## Preconditions

- Follow `skills/ocm-dev/access-warmups-detail.md` before multi-call execution.
- Use `rules/ocm-team.md` plus `skills/ocm-dev/team-reference-tables.md` as the source of truth for service tenancy names, panel ids, and dashboard conventions.
- Use `skills/find-5xx-times/SKILL.md` to derive the incident window.
- Use `skills/autoschrute-add-annotation/SKILL.md` only after the mutation gate is cleared.

## Steps

1. Confirm the four required inputs and stop if any are missing.
2. Validate that the service exists in `rules/ocm-team.md`; if it does not, stop and report that the workflow only supports mapped OCM services.
3. Run the warmups required by `skills/ocm-dev/access-warmups-detail.md`.
4. Use `find-5xx-times` to identify the elevated 5xx window for the requested service, region, and date range.
5. Resolve the service tenancy name, Grafana dashboard uid, and panel id from `skills/ocm-dev/team-reference-tables.md`.
6. Call DOPE `get_logging_namespaces` with the region and service tenancy name; collect every returned namespace for the service.
7. Resolve AD coverage before log search:
   - If the caller specified an AD, use only that AD.
   - If AD is not specified, enumerate all ADs for the region and scan each AD (do not default to `ad1` only).
8. For each targeted AD, call DOPE `search_logs` with exact timestamps from the elevated 5xx window, all collected namespaces, limit `25`, and query `WHERE "#statusCode" >= 500 | SORT by ts asc` using `service_log=true` first.
9. If step 8 returns no usable 5xx evidence (or no usable `#opc-request-id`), retry the same query with `service_log=false` across the same AD set before concluding no data.
10. Pick one failing `#opc-request-id` from the 5xx log results; if none exist after fallback search, stop and report that no request id was available in the sampled failing logs.
11. Call DOPE `search_logs` again with the same timestamps, same namespaces, and same AD coverage, limit `25`, and query `WHERE "#opc-request-id" = '<opc-request-id>' | WHERE "#level" = 'ERROR' | SORT by ts asc`.
12. Summarize the likely root cause from the error logs, including the chosen request id, the log evidence, and the annotation text you would write.
13. If the input intent is `investigate-only`, stop here and return the summary plus the proposed annotation text.
14. MUTATION: state the exact dashboard uid, panel id, region, annotation text, expected result, and rollback story; require explicit confirmation before writing anything.
15. After approval, invoke `autoschrute-add-annotation` with the region, dashboard uid, panel id, elevated-window start/end in epoch milliseconds, and the approved annotation text.

## Verify

- The workflow returns a bounded incident window from `find-5xx-times`.
- If AD was not provided, the workflow searched all ADs for the region instead of only `ad1`.
- The workflow records the exact namespaces and exact DOPE log queries used for evidence.
- If `service_log=true` produced no usable evidence, the workflow retried with `service_log=false` and records which mode produced the final evidence.
- The root-cause summary cites the specific `#opc-request-id` and error log lines used.
- No annotation is written unless the user explicitly approved the mutation step.
- If annotation was approved, `autoschrute-add-annotation` reports success from its own stdout.

## Done when

- The caller has either:
  - an evidence-backed root-cause summary plus proposed annotation text, or
  - a successful Grafana annotation with the same evidence attached.
