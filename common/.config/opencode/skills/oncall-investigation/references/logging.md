# Logging Guidance

Use this file when searching Lumberjack, DevOps, or splat logs, or when the right tenant, compartment, namespace, or auth path is uncertain.

## Lumberjack and DevOps search flow

- Use the configured Lumberjack scope as the starting point.
- Teams may configure either:
  - explicit `tenant_name` plus namespace list
  - discovery hints such as `phonebook` plus `project`
- When the incident is alarm-backed, resolve the logging tenant from the alarm-backed environment before searching logs:
  1. read the alarm definition
  2. capture its project, fleet, query, and compartment
  3. infer the environment label from alarm evidence such as fleet name or display name
  4. if `team.lumberjack.tenant_names_by_environment` has a mapping for that environment, prefer that tenant over the default `tenant_name`
  5. verify the chosen tenant by resolving logging namespaces and checking that the returned compartment matches the alarm compartment when possible
  6. only then run Lumberjack searches against the matched tenant and namespace
- If a `phonebook` is configured, fetch candidate compartments for the incident region before guessing manually.
- Derive the log time range and region set from the incident, unless the user explicitly asks for a fixed range.
- Normalize the incident region to the logging backend's expected query key before searching. For example, a ticket or alarm may refer to `us-seattle-1` while the Lumberjack/Ibex route for the same incident expects `r1`.
- If the metrics do not identify a specific AD and the logging backend supports AD-scoped routes, start with all ADs for the first search instead of guessing one AD up front.
- Start with the narrowest useful time slice and region that can test the current hypothesis.
- When strong identifiers already exist, prefer fielded filters over broad message or path matching.
- If a concrete request id or workflow id is known, use it as the primary correlation key before broadening into endpoint-path, message-text, or time-window-only searches.
- For request- or API-based investigations, prefer the non-service-log request path first when the namespace may expose request-family records:
  - start with `service_log=false`
  - prefer `WHERE "logGroup" = 'request*'`
  - pair that with the matching status field, typically `#statusCode`, plus any known operation, path, tenancy, or request id hint
- If the non-service-log request path stays empty after validating the searchable tuple, treat that as a likely sign that the namespace does not expose request-family log groups for this investigation and retry OCI service logs with `service_log=true`.
- Treat `service_log=true` as an alternate request-record source, not as application-log search. OCI service logs provide request-level fields such as timestamp, status, duration, service, resource or host, and `id` as the local `opc-request-id`.
- In `service_log=true` request-record searches, do not use `logGroup`. Use `data.status` as the HTTP status field when mining by status family, and treat `id` as the local `opc-request-id` for replay and handoff.
- For control-plane, worker, data-plane, or other application log searches, keep `service_log=false` and use the configured application namespace, log group, logger, exception, workflow, or request-id fields.
- Choose the first log system from the signal source, not from habit:
  - if the metric, alarm, canary, or ticket evidence is emitted by splat or splat proxy logs, start in splat
  - if the metric or alarm is emitted by the downstream service itself, start in the downstream service namespace first, preferring the non-service-log request path before any `service_log=true` fallback, and then check splat afterward for end-to-end correlation
- For the canonical downstream metric-driven request-id mining order, including the request-log-first `service_log=false` path and the `service_log=true` fallback, use `Metric-driven request-id mining` below.
- Treat request-centric log hits as a pivot point, not the end of the investigation. If those hits expose one or more workflow instance ids, replay each relevant workflow end-to-end before concluding.
- For workflow replay, run `WHERE "#wfInstanceId" = '<workflow-instance-id>' | SORT by ts asc` and read the full ordered timeline rather than only the first matching line.
- If the same request surfaces multiple workflow ids, inspect each relevant workflow role separately, such as dispatcher, poller, retry, or cleanup flows.
- When a workflow-id search returns mixed request context, pair the workflow replay with the surrounding request-specific fields before assuming every line belongs to the same request.
- If the incident is API- or request-based and an `#opc-request-id` is known:
  - start in splat first when the evidence source is splat or splat-side
  - start in downstream first when the evidence source is a downstream-emitted service metric or a downstream application error, then pivot back to splat to understand the end-to-end request path
- In splat, start with request logs first. When the namespace supports request-family log groups, prefer `WHERE "logGroup" = 'request*'` before broad message or path filtering.
- In splat, prefer `WHERE "#opc-request-id" = '<opc-request-id>' | SORT by ts asc` when the exact value is available. If proxy logs require partial request-id matching, use the narrowest stable wildcard that still keeps the end-to-end request path visible, then sort ascending and read the whole sequence before concluding.
- If splat shows the failure happened inside the proxy, treat that as proof the request did not reach the downstream service yet and do not jump straight to downstream API logs.
- If splat shows the request was forwarded and the error came back from downstream, pivot first with a cross-system `#opc-request-id` alignment search rather than assuming exact full-id equality across both systems.
- For `splat -> downstream` or `downstream -> splat` correlation, use the narrowest stable shared portion of the request id as the join key, typically the middle segment with a wildcard such as `#opc-request-id='*<segment2>*'`, then confirm the match with timestamp, operation, status, tenancy, and nearby context.
- Once the matching downstream-side or splat-side request entry is found, replay that system's full ordered local `#opc-request-id` timeline before narrowing further.
- After log evidence identifies the downstream service, use `workflow.md` for any broader pivot into that service's existing `[[team]]` config; keep this file focused on request and log correlation mechanics.
- Use `#logger` to identify which class emitted the error or exception, but do not let a `#logger` filter replace the initial full replay. First read the whole `#wfInstanceId` or `#opc-request-id` timeline in the correct system, then add `#logger` to isolate the failing class and nearby context.
- When an exception message is already known, combine identifiers and class filters explicitly, for example `WHERE "#wfInstanceId" = '<id>' | WHERE "#logger" = '<class>' | SORT by ts asc`, `WHERE "#opc-request-id" = '<id>' | WHERE "#logger" = '<proxy-class>' | SORT by ts asc` for splat, or `WHERE "#opc-request-id" = '<id>' | WHERE "#logger" = '<downstream-class>' | SORT by ts asc` for the downstream service, so the evidence shows both the timeline owner and the emitting code path.

Common high-signal fields:
- `#opc-request-id`
- `#ServiceOperationId`
- `#statusCode`
- `data.status`
- `id`
- `#logger`
- `logGroup`
- `Upstream.ResponseStatus`
- `Downstream.ResponseStatus`
- `DownstreamProcessingException`
- `#wfInstanceId`
- `#wfDef`

## Namespace discovery rules

- Treat configured namespaces as starting hints, not guaranteed runtime truth.
- Before concluding that a service has no logs, validate the exact searchable tuple:
  - region
  - availability domain when the backend route is AD-scoped
  - compartment
  - namespace
  - logGroup when the namespace block configures one
  - log type
- For AD-scoped backends, prefer the AD from alarm or metric evidence. If no AD is available from those sources, validate across all ADs before narrowing.
- If the namespace config includes a `region`, treat that as the preferred backend query key for that namespace family, not necessarily the public region name shown in the ticket or alarm UI.
- Do not assume the default Lumberjack `tenant_name` matches every environment. Alarm fleet names such as `*-dev` may require an environment-specific tenant mapping such as `tenant_names_by_environment.dev`.
- Recommended matching order:
  1. if alarm-backed, resolve the environment-specific tenant from alarm metadata and `tenant_names_by_environment`
  2. if the configured namespace blocks include `environment`, `region`, or `log_group`, prefer the namespace family whose fields match the incident first
  3. use that tenant to discover runtime namespaces and returned compartments
  4. if needed, use `phonebook` and region to fetch claimed compartments
  5. try the configured namespace against those candidate compartments
  6. if the namespace is still ambiguous or empty, continue tenant-based namespace discovery until the alarm compartment or another strong runtime compartment matches
- If a configured namespace returns no hits, check whether the namespace is valid only under a different claimed compartment or whether the service uses a region- or tenant-specific runtime namespace.
- If the same region has multiple environment-specific namespace families, test each candidate family separately and keep only the one that matches the strongest runtime identifiers for the incident, such as `#opc-request-id`, workflow id, or work request id.
- If the same namespace is reused for multiple durable streams, such as API and worker logs, treat `team.lumberjack.namespaces.log_group` as part of the configured scope and add `WHERE "logGroup" = '<configured-log-group>'` before broad text or class filtering.

## Splat guidance

- If request tracing suggests a splat, proxy, or routing issue, check splat before concluding the request never reached the target service.
- If the team config includes an explicit splat block, prefer its tenant and namespace hints over global defaults.
- If the team config includes `team.splat.tenant_names_by_environment`, resolve the incident environment first and prefer that tenant over the default `tenant_name`.
- For splat log searches, expect `splat-proxy` or `splat-proxy-overlay`.
- In `R1` or `REGION1`, splat Lumberjack searches should use tenant `mpapi`.
- In other realms, splat Lumberjack searches typically use tenant `splat`.
- If configured splat namespaces include `environment` or `region`, start with the entries whose scope matches the incident before widening to the rest.
- For splat request tracing, sort ascending and read the full ordered proxy timeline first so you can see request arrival, routing choice, downstream invocation, and downstream response in sequence.
- If the full request id is available in splat, prefer `WHERE "#opc-request-id" = '<opc-request-id>' | SORT by ts asc`.
- If exact request-id matching is not usable in splat, fall back to the narrowest stable wildcard form, such as `#opc-request-id='*<middle-segment>*'`, before adding URI or path text.
- Do not assume the full three-segment `#opc-request-id` is stable across `splat` and downstream application logs. Cross-system joins should use the narrowest stable shared portion of the id, typically `*<middle-segment>*`, then validate the candidate match from surrounding evidence.
- For request-centric splat investigations, prefer `WHERE "logGroup" = 'request*'` before `#logger`, exception text, or path matching when that filter is available in the namespace.
- After the full splat replay is understood, add `#logger` to identify which proxy class emitted the relevant routing, invocation, or error line. Do not start with `#logger` alone if doing so would hide other stages of the same request.
- When splat evidence needs to prove where the failure surfaced, combine the request-id filter with the class filter explicitly, for example `WHERE "#opc-request-id" = '<id>' | WHERE "#logger" = '<proxy-class>' | SORT by ts asc`.
- Use `#ServiceOperationId` to answer which downstream operation splat selected and to group impact by operation when multiple requests share the same failure mode.
- If the team config registers `team.splat.service_operations`, use that registry to translate `#ServiceOperationId` into the service-facing operation name and expected downstream target before broadening into downstream logs.
- The registry may contain exact `service_operation_id` entries or broader `service_operation_pattern` families such as `accounts.*`; prefer the most specific matching registration when both could apply.
- When a splat replay exposes a durable `#ServiceOperationId` that is not yet registered exactly or by stable family pattern, call that out as a follow-up config improvement so later investigations can pivot faster.
- Use proxy status fields such as `#statusCode`, `Upstream.ResponseStatus`, and `Downstream.ResponseStatus` together to distinguish:
  - proxy-side transport or invocation failures
  - downstream application responses that returned a normal HTTP status
- If splat shows the proxy itself failed the request, stop there for the first RCA layer because the downstream service was not reached.
- If splat shows the request was forwarded and the downstream returned the failure, pivot to the downstream application's logs by aligning on the stable shared request-id segment or request root first, then replay the downstream system's full local `#opc-request-id` timeline there before narrowing by class or exception text.
- When pivoting into splat application logs, prefer `WHERE "logGroup" = 'application*'` before broad text matching so the first pass stays inside the proxy's application-log family.
- Use splat to answer:
  - did the request arrive at proxy?
  - which downstream operation was selected?
  - did splat receive a downstream response, and what status came back?
- If splat shows downstream invocation and repeated downstream `500` responses, move immediately to the downstream application's logs using the aligned shared request-id segment or request root rather than assuming exact full-id equality.

### Single-request tracing

- Use this mode when the ticket already includes one or more concrete request ids.
- Start with the smallest, highest-signal replay:
  - the system that emitted the signal or provided the request id
  - `WHERE "logGroup" = 'request*'` when the first system is splat and that log group is available
  - exact local `#opc-request-id`
  - `SORT by ts asc`
- Reusable first-pass snippets:
  - splat request-log replay when the provided id is expected to exist in splat request logs:
    - `WHERE "logGroup" = 'request*' | WHERE "#opc-request-id" = '<opc-request-id>' | SORT by ts asc`
  - splat application-log replay after the request path is already understood and you need proxy-class detail:
    - `WHERE "logGroup" = 'application*' | WHERE "#opc-request-id" = '<opc-request-id>' | SORT by ts asc`
  - downstream local replay when the downstream service preserves the same local request id:
    - `WHERE "#opc-request-id" = '<opc-request-id>' | SORT by ts asc`
  - shared request-root join for cross-system alignment when splat and downstream do not share the full three-segment id:
    - `WHERE "logGroup" = 'request*' | WHERE "#opc-request-id" = '*<shared-request-segment>*' | SORT by ts asc`
  - downstream workflow replay when a request trace exposes a workflow instance id:
    - `WHERE "#wfInstanceId" = '<workflow-instance-id>' | SORT by ts asc`
- Guardrails for shared snippets:
  - keep placeholders generic, such as `<opc-request-id>`, `<shared-request-segment>`, and `<workflow-instance-id>`
  - use the exact local `<opc-request-id>` first, then fall back to `<shared-request-segment>` only for cross-system alignment when exact full-id matching is not stable across splat and downstream logs, or for namespaces where exact matching is incomplete
  - keep these as first-pass tracing snippets, not final RCA queries
- Read the full proxy timeline before narrowing so you can see request arrival, routing choice, downstream invocation, response status, and any retry or error behavior in order.
- Only after the full replay is understood should you add:
  - `#logger` to isolate the emitting proxy class
  - exact exception text to isolate one failure line
  - partial request-id matching if exact matching is incomplete in that namespace
- When the investigation pivots into another logging system, treat that as a cross-system alignment step: use the stable shared request-id segment or request root, typically `*<segment2>*`, to find the peer request first, then switch back to exact local request-id replay inside that system.

### Metric-driven request-id mining

- Use this mode when the alarm, dashboard, or ticket gives a tight time window and a `2xx`, `4xx`, or `5xx` symptom, but no concrete `#opc-request-id` yet.
- Start from the metric-derived scope first, and choose the first log system from the metric source:
  - same incident window, expanded earlier than the alarm event open time by the alarm lookback plus pending duration when the incident is alarm-backed
  - same region and AD scope
  - routed operation, URI, tenancy, or other metric dimensions when known
- For splat-emitted status-family metrics:
  - start in splat request logs
  - prefer `WHERE "logGroup" = 'request*'` when available
  - use `#statusCode` as the first status-family filter when mining candidate request ids
- For downstream-emitted service metrics:
  - start with the downstream non-service-log request path first
  - prefer `WHERE "logGroup" = 'request*'` when available
  - use `#statusCode` as the first status-family filter when mining candidate request ids from that request-log path
  - if the non-service-log request path stays empty after validating region, AD, namespace, time window, and scope filters, retry OCI service logs with `service_log=true` as an alternate request-record source
  - in the `service_log=true` request-record fallback, use `data.status` as the status-family field and treat `id` as the local `opc-request-id`
  - use the metric dimensions, operation name, local status, exception, or workflow fields to find the failing requests
  - after recovering a request id, workflow id, or other correlation key, pivot back to splat to understand the end-to-end request path and client-visible outcome
- Use the narrowest status range that matches the metric family:
  - `2xx` -> `>= 200` and `< 300`
  - `4xx` -> `>= 400` and `< 500`
  - `5xx` -> `>= 500` and `< 600`
- Pair the status-family filter with `#ServiceOperationId`, path, tenancy, and time window in splat. In downstream logs, use only downstream-native identifiers such as path, tenancy, local status, exception, workflow fields, and, for OCI service-log request records only, `data.status` and `id`.
- If the team config registers a stable splat service-operation family for the service, use that registration during the splat pass:
  - exact `service_operation_id` when one operation is known
  - otherwise the registered family or stable service-name wildcard such as `WHERE "#ServiceOperationId" = '*<service-operation-pattern>*'`
- Guardrails for shared snippets:
  - keep placeholders generic, such as `<opc-request-id>`, `<shared-request-segment>`, `<workflow-instance-id>`, and `<service-operation-pattern>`
  - keep these as first-pass mining snippets, not final RCA queries
  - do not hard-code team names, tenants, namespaces, or regions in the shared guide
  - keep service-specific routing knowledge in `team.splat.service_operations`, not in the snippet body
- Reusable first-pass snippets:
  - `4xx` splat request-id mining. Use this when the metric is a splat-backed `4xx` family alarm or dashboard spike:
    - `WHERE "logGroup" = 'request*' | WHERE "#ServiceOperationId" = '*<service-operation-pattern>*' | WHERE "#statusCode" >= '400' | WHERE "#statusCode" < '500' | SORT by ts asc`
    - Add path or tenancy only if the first pass is still noisy, for example `| WHERE "#requestUrl" = '*<path-fragment>*'` or `| WHERE "#tenant-id" = '<tenant-ocid>'`
  - `5xx` splat request-id mining. Start with the customer-visible status family first:
    - `WHERE "logGroup" = 'request*' | WHERE "#ServiceOperationId" = '*<service-operation-pattern>*' | WHERE "#statusCode" >= '500' | WHERE "#statusCode" < '600' | SORT by ts asc`
  - `4xx` downstream request-log mining. Use this when the downstream namespace exposes request-family records:
    - `WHERE "logGroup" = 'request*' | WHERE "#statusCode" >= '400' | WHERE "#statusCode" < '500' | SORT by ts asc`
    - Add downstream-native path, tenancy, operation, exception, or workflow filters only if the first pass is still noisy.
  - `5xx` downstream request-log mining. Use this when the downstream namespace exposes request-family records:
    - `WHERE "logGroup" = 'request*' | WHERE "#statusCode" >= '500' | WHERE "#statusCode" < '600' | SORT by ts asc`
    - Add downstream-native path, tenancy, operation, exception, or workflow filters only if the first pass is still noisy.
  - `4xx` OCI service-log request-record fallback. Use this only after the `service_log=false` request-log path has been validated and stayed empty:
    - `WHERE "data.status" >= '400' | WHERE "data.status" < '500' | SORT by ts asc`
  - `5xx` OCI service-log request-record fallback. Use this only after the `service_log=false` request-log path has been validated and stayed empty:
    - `WHERE "data.status" >= '500' | WHERE "data.status" < '600' | SORT by ts asc`
  - `5xx` splat proxy-vs-downstream split. If the incident is specifically about where the `5xx` surfaced in splat, run the sibling status-field passes as well:
    - `WHERE "logGroup" = 'request*' | WHERE "#ServiceOperationId" = '*<service-operation-pattern>*' | WHERE "Upstream.ResponseStatus" >= '500' | WHERE "Upstream.ResponseStatus" < '600' | SORT by ts asc`
    - `WHERE "logGroup" = 'request*' | WHERE "#ServiceOperationId" = '*<service-operation-pattern>*' | WHERE "Downstream.ResponseStatus" >= '500' | WHERE "Downstream.ResponseStatus" < '600' | SORT by ts asc`
    - Some splat surfaces expose these fields as `#Upstream.ResponseStatus` and `#Downstream.ResponseStatus`; use the exact label your namespace exposes.
  - Use the exact operation id from `team.splat.service_operations` instead of the wildcard family whenever the alarm or prior replay already identified one concrete routed operation.
- Use range filters for `5xx` mining instead of `= 500` unless the metric or prior evidence proves the issue is exactly one HTTP code. Alarm families and splat request logs often mix `500`, `502`, `503`, or `504` during the same burst.
- Once candidate rows are found, extract the matching `#opc-request-id` values and immediately switch to single-request replay for each promising request before concluding from aggregate counts alone.
- Reusable handoff from mining to replay:
  - exact local replay: `WHERE "#opc-request-id" = '<opc-request-id>' | SORT by ts asc`
  - OCI service-log request-record replay: `WHERE "id" = '<opc-request-id>' | SORT by ts asc`
  - shared request-root join for cross-system alignment: `WHERE "logGroup" = 'request*' | WHERE "#opc-request-id" = '*<shared-request-segment>*' | SORT by ts asc`
- Interpret the first promising replay before widening:
  - matching `#statusCode` `4xx` or `5xx` with a normal downstream response can indicate the application returned the customer-visible status
  - matching `#statusCode` `4xx` or `5xx` plus a failing downstream response is the signal to pivot into downstream logs using the shared request root
  - `#statusCode` `5xx` with missing normal downstream status is often a proxy-to-downstream invocation failure
  - `2xx` rows are primarily baseline or comparison requests unless the investigation is about missing success traffic

### Blast-radius analysis

- Use this mode after the single-request trace identifies a concrete proxy-side failure signature and you need to count or group impact.
- Keep the time window tight and prefer request logs first:
  - `WHERE "logGroup" = 'request*'` when available
  - proxy-side class filters such as `#logger`
  - exact exception text or failure flags only after the proxy class is known
- For impact extraction, prefer selecting only the fields needed to count and group requests rather than reading full stack traces.
- Common impact fields:
  - `ts`
  - `#ServiceOperationId`
  - `#tenant-id`
  - `#opc-request-id`
- If `team.splat.service_operations` exists, group the final blast-radius summary by both raw `#ServiceOperationId` and the registered operation `name` so the writeback is readable to responders who do not recognize the raw proxy identifier.
- When the registration is pattern-based, keep the raw `#ServiceOperationId` in the summary so responders can still distinguish the exact routed operation inside the broader family.
- Group blast radius by:
  - downstream operation
  - caller tenancy
  - upstream or downstream response status when relevant

### Proxy-side transport failure signals

- Treat these as common signs that the proxy failed while invoking the downstream service rather than receiving a normal downstream application response:
  - proxy-emitted transport exceptions such as connection resets, socket exceptions, TLS handshake failures, or timeouts
  - a synthesized upstream `5xx` returned by the proxy even though no normal downstream HTTP response is visible
  - proxy-specific fields that indicate invocation failure, missing downstream status, or downstream-processing errors
  - request replay that shows downstream invocation attempts but no normal downstream application response line
- Field names vary by proxy and logging schema. Use the configured namespace's actual proxy fields and status markers as supporting evidence, not as a hard-coded signature.
- If these signals appear together in the proxy timeline, classify the first RCA layer as a proxy-to-downstream transport or invocation failure.
- In that case:
  - do not assume the downstream application processed the request
  - do not treat missing downstream application logs as proof that the search was wrong
  - pivot next to blast-radius counting in splat and to infrastructure, release, endpoint-health, or host-level checks for the downstream target

## Auth preflight and fallback notes

- Validate the required logging or DevOps auth before starting the investigation's execution phase, not only after a log query fails.
- If a tool reports that it could not get an operator token, do not assume `OP_TOKEN` is missing from `~/.env`.
- Distinguish between:
  - env-backed workflows that read an existing `OP_TOKEN`
  - tool paths that try to mint or refresh a token through SSH or operator-token helpers
- Make sure `OP_TOKEN` is exported into the current command environment before validating or using it.
- When the local environment already has a valid `OP_TOKEN`, prefer env-backed REST calls or env-backed clients before concluding there is an auth gap.
- If the required token is invalid and cannot be refreshed automatically, stop and tell the user to refresh the token before continuing the investigation.

## Relationship to other references

- Use `metrics.md` first when the incident is alarm-backed and the logging tenant depends on alarm environment.
- Use `canary.md` first for canary-backed incidents so the investigation starts from the raw canary evidence.
