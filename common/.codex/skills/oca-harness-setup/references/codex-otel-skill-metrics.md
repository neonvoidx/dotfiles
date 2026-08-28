# Codex OpenTelemetry Usage Signals

Use Codex OpenTelemetry as DBTools-default logs, local-default metrics, and mandatory user identity:

- DBTools hosted dashboard: Codex log exporter events sent to `CODEX_OTEL_LOGS_ENDPOINT`, defaulting to `https://dsostore.oraclecorp.com/ords/DASHBOARD/telemetry/v1/logs`; `x-codex-user` comes from required `CODEX_OTEL_USER`. Use this for aggregate Codex token/app/model usage, not skill/MCP/workflow attribution.
- Local metrics stack: Codex metrics exporter events sent to `AIPACK_OTLP_METRICS_ENDPOINT`. Use this for `codex.skill.injected` / `aipack_codex_skill_injected_total` and local Prometheus/Grafana validation.
- Local log testing: override `CODEX_OTEL_LOGS_ENDPOINT` to `http://127.0.0.1:4318/v1/logs` when validating the bundled collector or opting out of hosted logs.

This starter pack no longer includes mandatory agent-authored self-reporting. Pack attribution, semantic outcomes, and self-report reconciliation are follow-on design work.

The pack renders this Codex config fragment to `~/.codex/config.toml`:

```toml
[otel]
environment = "dev"
exporter = { otlp-http = { endpoint = "{env:CODEX_OTEL_LOGS_ENDPOINT:-https://dsostore.oraclecorp.com/ords/DASHBOARD/telemetry/v1/logs}", protocol = "json", headers = { "x-codex-user" = "{env:CODEX_OTEL_USER}" } } }
trace_exporter = "none"
log_user_prompt = false

[otel.metrics_exporter]
[otel.metrics_exporter.otlp-http]
endpoint = "{env:AIPACK_OTLP_METRICS_ENDPOINT:-http://127.0.0.1:4318/v1/metrics}"
protocol = "json"
```

Set the dashboard identity before syncing:

```bash
aipack config env set CODEX_OTEL_USER first.last
```

Do not include `@oracle.com` in `CODEX_OTEL_USER`. If `CODEX_OTEL_USER` is absent, `aipack profile refs` reports it as required and sync/render fails instead of sending anonymous rows.

Override the log endpoint only for local validation, hosted-log opt-out, or an alternate compatible receiver:

```bash
aipack config env set CODEX_OTEL_LOGS_ENDPOINT http://127.0.0.1:4318/v1/logs
```

Unset `CODEX_OTEL_LOGS_ENDPOINT` and re-sync to return logs to DBTools. If a team hosts a compatible receiver, set that receiver instead:

```bash
aipack config env set CODEX_OTEL_LOGS_ENDPOINT <otlp-http-logs-url>
```

`AIPACK_OTLP_METRICS_ENDPOINT` defaults to `http://127.0.0.1:4318/v1/metrics` in the Codex OTEL settings template for local collector testing. For internal aipack reporting and CLI operation metrics, set the same key with `aipack config env set AIPACK_OTLP_METRICS_ENDPOINT <otlp-http-metrics-url>` or from the TUI Config tab.

## Local setup

Use the local stack when validating the pack or demonstrating the local OTEL path. The proven topology is Codex CLI -> OTLP HTTP collector on `127.0.0.1:4318` -> Prometheus/Grafana for metrics and collector debug output for logs. Local log validation requires overriding `CODEX_OTEL_LOGS_ENDPOINT` to `http://127.0.0.1:4318/v1/logs`.

Prerequisites:

```bash
codex --version
podman machine list
podman machine start
podman compose version
```

The local proof used `codex-cli 0.125.0`, `otel/opentelemetry-collector-contrib:0.123.0`, `prom/prometheus:v2.54.1`, and `grafana/grafana:11.2.2`. If corporate VPN intercepts container registry TLS, pull the images from a network path that does not break Docker Hub TLS, then reconnect before testing any VPN-only endpoint.

Remote installs and updates preserve this stack only when extras are accepted:

```bash
aipack pack install oci-dev-starter-pack -w extras
aipack pack update oci-dev-starter-pack -w extras
```

Use the stack shipped with this pack:

```text
~/.config/aipack/packs/oci-dev-starter-pack/extras/aipack-otel-stack/
  compose.yaml
  otel/config.yaml
  prometheus/prometheus.yml
  grafana/provisioning/datasources/prometheus.yml
  grafana/provisioning/dashboards/aipack.yml
  grafana/dashboards/aipack-codex-skills.json
```

Compose file:

```yaml
services:
  otel-collector:
    image: docker.io/otel/opentelemetry-collector-contrib:0.123.0
    command: ["--config=/etc/otelcol/config.yaml"]
    volumes:
      - ./otel/config.yaml:/etc/otelcol/config.yaml:ro
    ports:
      - "4318:4318"
      - "8889:8889"

  prometheus:
    image: docker.io/prom/prometheus:v2.54.1
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
      - "--storage.tsdb.path=/prometheus"
      - "--web.enable-lifecycle"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    ports:
      - "9090:9090"
    depends_on:
      - otel-collector

  grafana:
    image: docker.io/grafana/grafana:11.2.2
    environment:
      GF_SECURITY_ADMIN_USER: admin
      GF_SECURITY_ADMIN_PASSWORD: admin
      GF_AUTH_ANONYMOUS_ENABLED: "true"
      GF_AUTH_ANONYMOUS_ORG_ROLE: Viewer
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
      - ./grafana/dashboards:/var/lib/grafana/dashboards:ro
    ports:
      - "3000:3000"
    depends_on:
      - prometheus

volumes:
  prometheus-data:
  grafana-data:
```

Collector requirements:

```yaml
receivers:
  otlp:
    protocols:
      http:
        endpoint: 0.0.0.0:4318

processors:
  deltatocumulative: {}
  batch: {}

exporters:
  prometheus:
    endpoint: 0.0.0.0:8889
    namespace: aipack
    send_timestamps: false
    metric_expiration: 24h
    resource_to_telemetry_conversion:
      enabled: true

service:
  pipelines:
    metrics:
      receivers: [otlp]
      processors: [deltatocumulative, batch]
      exporters: [prometheus]
```

Prometheus must scrape the collector's Prometheus exporter:

```yaml
global:
  scrape_interval: 5s
  evaluation_interval: 5s

scrape_configs:
  - job_name: otel-collector
    static_configs:
      - targets: ["otel-collector:8889"]
```

Pin the Grafana datasource UID to `Prometheus`; otherwise provisioned dashboard panels can break after stack recreation:

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    uid: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
```

Provision dashboards from `grafana/dashboards`:

```yaml
apiVersion: 1

providers:
  - name: aipack
    orgId: 1
    folder: AIPack
    type: file
    disableDeletion: false
    updateIntervalSeconds: 5
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
```

The expanded "aipack Codex OTEL Metrics" dashboard is shipped at `extras/aipack-otel-stack/grafana/dashboards/aipack-codex-skills.json`.

Start the stack:

```bash
cd ~/.config/aipack/packs/oci-dev-starter-pack/extras/aipack-otel-stack
podman compose up -d
curl -sS http://127.0.0.1:9090/-/ready
curl -sS http://127.0.0.1:3000/api/health
```

Render the Codex config from this pack. Use the target user's real profile name; the pack template defaults Codex OTEL logs to DBTools and metrics to the local collector endpoint.

```bash
aipack sync --profile <profile> --harness codex --scope global --dry-run
aipack sync --profile <profile> --harness codex --scope global
```

The rendered `~/.codex/config.toml` must include the `[otel]` block shown above, with the DBTools log endpoint, required `x-codex-user`, localhost metrics endpoint, `log_user_prompt = false`, and `trace_exporter = "none"`.

Emit a probe skill event:

```bash
mkdir -p /tmp/codex-otel-skill-test/.codex/skills/otel-probe
cat > /tmp/codex-otel-skill-test/.codex/skills/otel-probe/SKILL.md <<'EOF'
---
name: otel-probe
description: Use when verifying Codex OTEL skill metrics emission.
---

Reply with exactly otel-probe-ok.
EOF

codex exec --skip-git-repo-check --ephemeral --ignore-rules --json \
  -C /tmp/codex-otel-skill-test \
  'Use $otel-probe and then reply with exactly otel-probe-ok.'
```

Verify the metric in Prometheus:

```bash
curl -sS --get http://127.0.0.1:9090/api/v1/query \
  --data-urlencode 'query=sum by (skill, status) (aipack_codex_skill_injected_total)'
```

Open Grafana at:

```text
http://127.0.0.1:3000/d/aipack-codex-skills/aipack-codex-otel-metrics
```

The dashboard should include panels for skill injections, thread skill exposure, turn latency, token usage, tool calls, MCP timing, shell snapshots, startup/prewarm, plugins, hooks, WebSocket/API/SSE/Responses API timing, and raw metric/resource-label inventory. Empty panels are expected until the corresponding Codex path runs in the selected time window.

Troubleshooting:

- `podman` cannot connect to its socket from a sandboxed agent: run Podman machine and compose commands from the user's shell or with explicit unsandboxed approval.
- Container image pulls fail only on VPN: pull images while disconnected or from an approved network path, then reconnect for VPN-only collectors.
- Grafana panels say "data source not found": confirm `grafana/provisioning/datasources/prometheus.yml` contains `uid: Prometheus`, then restart Grafana.
- Prometheus has no `aipack_codex_skill_injected_total`: confirm Codex config rendered to `~/.codex/config.toml`, the collector exposes `4318`, and the probe command used an explicit `$otel-probe` skill invocation.
- DBTools hosted dashboard has no skill/MCP/workflow rows: expected. It currently handles aggregate Codex token/app/model usage. Use local metrics for `codex.skill.injected` while pack attribution and semantic reporting remain follow-on work.

Expected automatic signal:

```text
codex.skill.injected{
  skill="<skill-name>",
  status="ok|error",
  invoke_type="implicit",
  originator="codex_exec|codex_tui|...",
  session_source="exec|tui|...",
  model="<model>",
  app_version="<codex-version>"
} 1
```

Explicit skill invocation records `skill` and `status`. Codex source also records `invoke_type="implicit"` when it detects implicit skill use through reading a `SKILL.md` with file-reader commands or running a script under a skill's `scripts/` directory. The local collector uses the `deltatocumulative` processor so OTLP delta sums become cumulative Prometheus counters before export.

```promql
sum by (skill, status) (aipack_codex_skill_injected_total)
```

Codex automatic skill events cover skill injection across explicit and implicit invocation types. They do not identify the owning pack, workflow usage, semantic completion, or outcome.

The `codex.thread.skills.*` metrics are only exposure/rendering diagnostics:

- `codex.thread.skills.enabled_total`
- `codex.thread.skills.kept_total`
- `codex.thread.skills.truncated`
- `codex.thread.skills.description_truncated_chars`

They count visible skill descriptions and truncation. They do not identify which skill was used.

Do not enable prompt logging or traces for aipack usage reporting. Codex log/trace events can include account fields, prompt text when `log_user_prompt=true`, tool arguments, and tool output. Keep `trace_exporter = "none"` and `log_user_prompt = false`. If a richer OTEL receiver is used later, add a filter/projection layer before storing raw events.
