---
name: service-oke-realm-setup
description: Set up or reactivate service OKE access for a given OCI realm. Use when the user wants service JIT activation and propagation preflight, session-auth commands, SSH tunnel commands, OKE kubectl verification, service SSH config entries, OKE/database tunnels, or per-realm kubeconfig backup files after the user completes external-browser OCI tenancy authentication. Derive region from local realm state and use a realm-derived profile name.
---

# Service OKE Realm Setup

Use this skill for service OKE access setup in any realm. The user supplies `realm` and optionally `service`; default `service` to Account Admin Tool (`account-admin-tool`, short key `aat`) when the prompt omits service and the local AAT files match. Derive `region` from local per-realm state and choose the profile name from the realm and service, then have the user complete service JIT access, check configured JIT propagation, and complete external-browser OCI auth for the service tenancy. Prefer live OCI for IP-sensitive values. Shepherd state history may be used only as a fallback or user-requested hint for a tunnel command when live OCI is blocked; label it as unverified until kubectl or a tunnel probe succeeds.

Default to the user's active-copy workflow: use the service/realm kubeconfig backup as the per-realm source of truth, snapshot `$HOME/.kube/config`, copy the `*.bkp` content into `$HOME/.kube/config`, and run kubectl from that active config. Use a temporary kubeconfig only when the user explicitly asks not to touch the active config or when an alternate local port must be tested without changing the durable backup.

Important: if a realm already has SSH setup in a service SSH config, do not assume the instance IP addresses are still valid. During setup or refresh, always re-query live OKE node IPs from the authenticated tenancy and replace the realm block so every `HostName <bastion_ocid>-<node_private_ip>` entry is current.

## Files

- User manual: `references/user-guide.md` explains the short prompts, config precedence, setup modes, and common stops for service teams and operators.
- Service config: prefer `<service-repo>/.agents/service-oke/<service_key>.toml` when the current workspace is the service repo; otherwise use shared fallback configs under `assets/service-teams/<service_key>.toml`. Use `references/configuration.md` for the config contract and `assets/service-oke-config.template.toml` as the starting template.
- SSH config: service-specific; AAT default is `$HOME/.ssh/account-admin-tool-dev-tools/ssh_configs/config_aat`
- Kubeconfig cache: service-specific; AAT default is `$HOME/.kube/config.<realm>.bkp`
- Active kubeconfig copied from the chosen `*.bkp` before kubectl: `$HOME/.kube/config`
- Temporary kubectl config: create under `/tmp` or `mktemp` only when explicitly needed, then delete after the command
- Generic helper: `scripts/setup_service_oke_realm.py` reads the service OKE TOML config and supports the full live-OCI setup path for any service with enough config metadata.

## Path Portability

Do not hardcode a specific workstation username or home directory.

- Resolve user-owned paths from `$HOME` or `~` at runtime.
- In examples, prefer `$HOME/.kube/...` and `$HOME/.ssh/...` instead of absolute workstation-specific home paths.
- If a user provides an explicit absolute path, use that path for the current run only and do not bake it into generic skill instructions.

## Required Inputs

- `realm`: lower or upper case, for example `oc42`
- `service`: optional; default to `account-admin-tool` / `aat` for AAT prompts or when the local AAT cache is the only match
- `config`: optional explicit path to a service OKE config; when omitted, discover the current repo config first, then the shared `assets/service-teams/<service_key>.toml` fallback
- `region`: optional for cached realms; derive it from the service/realm kubeconfig backup first, then the matching realm block in the service SSH config; ask only when missing or ambiguous
- `profile`: optional; choose the realm/service-derived profile name `<realm>-<service_key>`, for example `oc42-aat`, unless a local realm convention clearly requires a different name
- `tenancy_name`: service-specific; AAT default is `account_admin_tool`
- `alias`: prefer the OCI region key lowercased, for example `yxj`; if it cannot be discovered, ask the user or use a region-derived alias only after confirming
- JIT propagation target: optional; prefer service-owned config `[jit].propagation_url`, `[jit].propagation_secret_name`, and `[jit].propagation_path`. If missing, the user may provide a propagation URL and expected metadata for their service in the current prompt/run.

## Configuration

Teams should keep concrete service values in config instead of expanding this shared skill with service-specific branches. Prefer repo-local service-owned config when available. Use shared fallback configs under `assets/service-teams/` for broadly shared, non-secret operator metadata that cross-team users need even when they do not have the service repo checked out.

Discovery order:

1. User-provided config path.
2. Current repository `.agents/service-oke/<service_key>.toml`.
3. Current repository `.agents/service-oke/<service_slug>.toml`.
4. Shared skill fallback `assets/service-teams/<service_key>.toml`.
5. Shared skill fallback `assets/service-teams/<service_slug>.toml`.
6. Existing local kubeconfig and SSH config evidence.
7. Ask for missing tenancy, Permissions Portal slug, SSH config path, kubeconfig path, or compartment details.

The config may provide durable values such as service aliases, Permissions Portal slug, tenancy name, profile template, realm region/profile overrides, kubeconfig backup template, SSH config path, JIT propagation metadata, tunnel ports, and live OCI discovery hints. It must not contain secrets, tokens, private keys, one-time auth URLs, cookies, or incident-specific values.

When explaining config setup to a service team, split fields into `Required`, `Optional`, and `Auto-populated by helper`. The minimum service config needs service identity, tenancy, profile template, SSH config path, and kubeconfig backup template. The minimum realm config is usually `region` plus `profile`; `profile` may be omitted only when the profile template is exact. The helper may populate `alias`, `compartment_id`, `bastion_compartment_id` when different, and `realm_domain` after discovery. Mention `--no-update-config` for read-only runs. Treat `[jit].propagation_url` and its expected metadata as service-owned optional config that each team provides for its own safe metadata-only propagation check.

When a config exists, treat it as the source of truth for service identity and path conventions, but still verify IP-sensitive values with live OCI before writing SSH config or claiming kubectl works.

## Tenancy Name Validation

Treat `tenancy_name` as derived evidence, not a silent assumption.

- For known services with an explicit local mapping, use the mapped tenancy name.
- For services without an explicit mapping, derive the tenancy name only from local config, prior commands, profile metadata, or user-provided input.
- Before asking the user to run an auth command, say which tenancy name will be used and why when it is not an explicit known mapping.
- If OCI auth, validation, or local evidence suggests the tenancy name is wrong, tell the user directly: name the service, realm, profile, attempted tenancy name, and the error or conflicting evidence.
- Do not keep retrying with alternate tenancy names silently. Ask the user for the exact tenancy name or a known-good auth command when the correct tenancy cannot be proven.

## Service Resolution

When the user provides a service name, normalize it before resolving realm details:

- First look for a matching service OKE config using the Configuration discovery order. If found, read service identity, aliases, tenancy, permissions slug, profile convention, kubeconfig backup path, SSH config path, realm overrides, and tunnel defaults from that config before falling back to hardcoded or inferred values.
- For `AAT`, `Account Admin Tool`, or `account-admin-tool`:
  - `service_key`: `aat`
  - `permissions_slug`: `account-admin-tool`
  - `tenancy_name`: `account_admin_tool`
  - SSH config: `$HOME/.ssh/account-admin-tool-dev-tools/ssh_configs/config_aat`
  - kubeconfig backup: `$HOME/.kube/config.<realm>.bkp`
  - profile convention: `<realm>-aat`
- For other services:
  - derive a lowercase hyphenated `service_slug` from the supplied name
  - derive `service_key` from the slug unless local files show a shorter established key
  - look first for service-specific kube backups such as `$HOME/.kube/config.<service_key>.<realm>.bkp`, then `$HOME/.kube/config.<realm>.<service_key>.bkp`
  - look for obvious SSH configs under `$HOME/.ssh/*<service_slug>*/*config*` and `$HOME/.ssh/*<service_key>*/*config*`
  - use profile convention `<realm>-<service_key>`
  - ask for missing `tenancy_name`, SSH config path, kubeconfig path, or Permissions Portal slug only after these local derivations fail

Do not assume AAT-specific paths, tenancy, JIT URL, or profile suffix for a non-AAT service unless the user explicitly says the service uses the AAT setup.

## Realm Resolution

When the user gives only a realm, derive the service first, then derive the rest before asking follow-up questions:

1. Inspect the service/realm kubeconfig backup.
   - Read `--region` from the user exec args.
   - Read `--profile` only as migration evidence; if it is `DEFAULT`, a legacy airport-code alias, or otherwise not service/realm-derived, plan to rewrite the backup to `<realm>-<service_key>`.
   - Read the current API server port so the temp kubeconfig rewrite preserves the intended local-port behavior.
2. Inspect the matching `### <REALM>` block in the service SSH config.
   - Read the region from the block header, such as `### OC16 (Overlay bastion) - us-westjordan-1`.
   - Read the tunnel comment for OKE endpoint and SSH host.
3. If the kube backup and SSH config disagree on region, stop and report both values instead of guessing.
4. Ask for `region` only when no local source provides it or the local sources conflict.
5. Use `<realm>-<service_key>` as the profile in session-auth commands and kubeconfig exec args. Ask for `profile` only when the user says the service/realm-derived default is wrong or a documented local convention clearly uses another name.
6. When a cached kubeconfig uses a non-service/realm-derived profile such as `DEFAULT`, update the service/realm kubeconfig backup to the derived profile and make sure the matching OCI profile exists before asking the user to authenticate it.

## JIT Preflight

Kubectl access requires service `prod-admin` JIT access in addition to a valid OCI session and a working SSH tunnel.

Before kubectl verification, make sure service JIT is active in Permissions Portal and check propagation when the service config provides a propagation target:

- Open `https://permissions.oci.oraclecorp.com/service/<permissions_slug>?tab=prod-admin`.
- Confirm the page shows the expected service name.
- Confirm the selected role/tab is `prod-admin`.
- Open `Activations` and check for a current activation for the user.
- If no current activation exists, activate `prod-admin` and verify the activation row or success text before continuing.
- If `[jit].propagation_url` is configured, open it before running `kubectl`.
- If no propagation URL is configured, ask the user whether they have a service-specific propagation URL and expected visible metadata for their service. Use a user-provided URL for the current run. Only write it to service config when the user explicitly asks to save it.
- Report propagation as `propagated` when the page shows Secret Service details, the configured expected secret name/path when present, and an active latest version row.
- Report propagation as `pending` when JIT is active but the propagation page still asks for login, reports a blocked OC1 popup, redirects to sign-in, or does not show latest metadata yet. Say access may still be propagating.
- Report propagation as `not configured` when the service config has no propagation URL; ask the user for a propagation target if they want this check for that service.
- Do not stop the workflow solely because propagation is `pending`, `blocked`, or `not configured`. Inform the user clearly before continuing and let them decide whether to wait, retry, or proceed.

Propagation check safety:

- Prefer external Google Chrome when the built-in browser blocks the Secret Service OC1 login popup.
- Inspect metadata only.
- Never click `View Secret`.
- Never copy, print, summarize, or expose secret values, callback URLs, id tokens, cookies, or session material.
- Report only non-secret metadata such as latest version, version name, state, and created timestamp.
- Do not store secret values or one-time/session-bearing URLs in service config. Only store stable metadata-page URLs and expected visible labels/paths.

Login boundary:

- If the browser lands on SSO, MFA, or a login form, keep the browser on that page and ask the user to complete login.
- Never ask for, type, store, or log passwords, MFA codes, cookies, or one-time tokens.
- Do not click `Remove`, `Revoke`, role membership changes, ownership changes, policy changes, or access-review actions.

## Plan Readiness Verdict

When the user asks to plan or dry-run kubectl access, end with a clear verdict:

```text
Kubectl readiness: yes / yes with warnings / no
```

Use read-only checks only. Do not authenticate, start or kill tunnels, copy kubeconfig, rewrite SSH config, update service config, or change files.

Check these prerequisites and report each one:

- service config resolved: service key, realm, region, profile, tenancy, kubeconfig backup, SSH config, local OKE port, and required extra forwards
- kubeconfig backup exists and points at the expected local Kubernetes API port
- kubeconfig exec args use the selected realm/service profile and region
- service `prod-admin` JIT activation is confirmed, or explain why it is unknown, such as SSO/login blocking the portal
- configured JIT propagation is checked, or reported as `not configured`
- OCI profile validates with `oci session validate --profile <profile>`
- local tunnel listener exists on the OKE port, and required extra-forward listeners exist when applicable
- optional read-only kubectl probe succeeds, such as `kubectl --kubeconfig <backup> get --raw /version --request-timeout=10s` or `kubectl --kubeconfig <backup> get ns --request-timeout=10s`

Verdict rules:

- `yes`: all required prerequisites are confirmed, or a read-only kubectl probe succeeds and no required prerequisite is known to be missing.
- `yes with warnings`: kubectl can likely execute or a read-only probe succeeds, but one non-blocking signal is unknown or advisory, such as Permissions Portal activation being login-blocked while propagation is confirmed.
- `no`: a required prerequisite is missing or failed, such as invalid OCI profile, missing kubeconfig backup, absent local tunnel listener, wrong kubeconfig profile/port, or failed kubectl probe.

When the verdict is `yes` or `yes with warnings`, include the exact kubectl command the user can run. When it is `no`, list the shortest next action needed to become ready.

## Fast Path

Use this path when the service/realm kubeconfig backup already exists and the user asks to run a kubectl command, provide session/tunnel commands, or reactivate cached access. The fast path applies to kubeconfig handling under `$HOME/.kube`: use the cached `config.<realm>.bkp` as the source of truth, normalize it when needed, and copy it into `$HOME/.kube/config` for verification. Do not force the Full Setup Path just because the SSH config may be stale.

The service SSH config is the exception to cached handling. For every fast-path run, compare live OKE node/private IPs from OCI with the realm block in the service SSH config and update the SSH config if the `HostName <bastion_ocid>-<node_private_ip>` values drifted. Do this before providing or running any SSH tunnel command. If live OCI cannot verify node IPs, say that freshness is unverified before giving or running a tunnel command.

For shorthand requests such as `kubectl pods on oc16` or `run kubectl on oc1`, do not jump straight to kubectl. First derive the realm details, then present the JIT, session, and tunnel handoff commands. Run kubectl only after one of these is true:

- the user confirms JIT is active, the OCI profile validates, and the tunnel is running
- the current turn directly validated JIT/session/tunnel successfully
- the user explicitly asks Codex to run the auth and tunnel setup commands on their behalf

1. Inspect the cached backup; do not copy it to the active kubeconfig by default:

```bash
KUBECONFIG=<service_realm_kubeconfig_backup> kubectl config view --raw --minify
```

2. Confirm service `prod-admin` JIT is active and propagation has been checked using the JIT Preflight above. If the user handles JIT externally, ask them to confirm it is active; still run the configured propagation check before kubectl when possible, or inform the user if no propagation target is configured.

3. Resolve the OCI profile and region from local realm state using Realm Resolution, then validate the profile:

```bash
oci session validate --profile <profile>
```

If validation fails or the user wants to prepare externally, provide this exact session command and pause until they confirm it validates:

```bash
oci session authenticate --profile-name <profile> --region <region> --tenancy-name <tenancy_name> --session-expiration-in-minutes 60
oci session validate --profile <profile>
```

If authentication or validation fails in a way that may indicate a bad tenancy name, stop and report the attempted tenancy name explicitly before suggesting any next command.

4. Refresh the service SSH config node IPs from live OCI before tunnel setup.

- Query the live service compartment for the OKE cluster and current active node/private IPs.
- Compare the live node IPs with every service-node `HostName` entry in the realm block.
- If they differ, update the service SSH config in place before providing or running the tunnel command. This does not require regenerating kubeconfig or using the Full Setup Path when the `~/.kube` backup is already valid.
- This check must catch stale `HostName <bastion_ocid>-<node_private_ip>` entries and replace them with the current live OKE node private IPs for the requested realm.
- If the failure was `failed to reach end-host via bastion resource`, perform this drift check before concluding the bastion, JIT, session, or OKE private endpoint is unhealthy.

Example AAT live-node check:

```bash
oci compute instance list-vnics \
  --auth security_token \
  --compartment-id <service_compartment_ocid> \
  --region <region> \
  --profile <profile> \
  --output json
```

5. Check local tunnel ports before starting the current realm tunnel:

```bash
lsof -nP -iTCP:6443 -sTCP:LISTEN
lsof -nP -iTCP:1522 -sTCP:LISTEN
```

Keep only one service OKE tunnel active by default. Treat `6443` as the canonical Kubernetes API port for the current realm. If `6443` is already owned by an `ssh` tunnel for a previous realm, report the owning process, kill only that `ssh` PID, verify `6443` is clear, and reuse `6443` for the current realm. If a configured database forward such as `1522` is also owned by an `ssh` tunnel from a previous realm, kill only that same tunnel PID or the specific `ssh` PID owning that port before starting the current realm. Never use broad `pkill ssh`. If a non-`ssh` process owns a needed port, stop and ask before killing it. Choose an alternate local OKE port such as `6444` only when the user explicitly asks for a temporary/non-mutating check or explicitly wants to preserve the existing tunnel.

6. Prepare the active kubeconfig from the per-realm backup:

- snapshot `$HOME/.kube/config` before replacing it
- copy the service/realm kubeconfig backup into `$HOME/.kube/config`
- if the selected local port is not the backup's port, rewrite `$HOME/.kube/config` to `https://127.0.0.1:<local_port>` for the current active realm
- normalize stale OCI exec args if present: `security-token` -> `security_token`
- set `command: /opt/homebrew/bin/oci` when the backup uses bare `oci`
- correct non-service/realm-derived profiles to `<realm>-<service_key>`, such as AAT `<realm>` `DEFAULT` -> `<realm>-aat`

7. Provide the tunnel command when the user wants to set it up externally. Read the endpoint and host from the refreshed realm block in the service SSH config when present:

```bash
ssh -N \
  -F <ssh_config_path> \
  -o StrictHostKeyChecking=accept-new \
  -o ExitOnForwardFailure=yes \
  -o ServerAliveInterval=30 \
  -o ServerAliveCountMax=3 \
  -L <local_port>:<oke_private_endpoint_ip>:6443 \
  <service-host>
```

If the primary host fails with an end-host, bastion, or TLS timeout, do not retry blindly. Report the exact failure and suggest sibling service OKE hosts only when they exist in the service SSH config.

8. Verify with the active config:

```bash
PATH=/opt/homebrew/bin:$PATH kubectl get pods
```

9. Leave `$HOME/.kube/config` on the selected realm unless the user asks to restore the prior active config. Clean up only temporary files and any temporary tunnel Codex started. If the user started the tunnel externally, leave it alone.

If `--verify` is used, validate the OCI profile first. If it is expired, either authenticate with `--authenticate` or stop with the exact `oci session authenticate` command.

Use the generic helper with a service config:

```bash
python3 skills/service-oke-realm-setup/scripts/setup_service_oke_realm.py setup \
  --realm <realm> \
  --service <service_key> \
  --config <optional_service_oke_toml> \
  --authenticate \
  --replace-existing-tunnel \
  --start-tunnel \
  --verify
```

If the service config cannot uniquely discover the service compartment, pass `--compartment-id` or add `realms.<realm>.compartment_id` to the service config. If the bastion lives in a separate compartment, pass `--bastion-compartment-id` or add `realms.<realm>.bastion_compartment_id`.

## External Handoff

When the user says they can set things up externally, or uses shorthand like `kubectl pods on <realm>` without saying prerequisites are already ready, first ask them to activate service `prod-admin` JIT and mention that Codex will check configured JIT propagation before kubectl, then give them exactly two commands:

```bash
oci session authenticate --profile-name <profile> --region <region> --tenancy-name <tenancy_name> --session-expiration-in-minutes 60
```

```bash
ssh -N -F <ssh_config_path> -o StrictHostKeyChecking=accept-new -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -L <local_port>:<oke_private_endpoint_ip>:6443 <service-host>
```

Then, after they confirm `oci session validate --profile <profile>` succeeds and the tunnel is running, run the configured read-only JIT propagation check, snapshot `$HOME/.kube/config`, copy the realm `*.bkp` into `$HOME/.kube/config`, and run kubectl from the active config.

## Full Setup Path

Use this path when the realm kubeconfig backup is missing, the SSH config block is missing, validation fails, or the user wants to confirm/update SSH instance IPs.

1. Start external-browser auth and wait for the user to complete it:

```bash
/opt/homebrew/bin/oci session authenticate \
  --profile-name <profile> \
  --region <region> \
  --tenancy-name <tenancy_name> \
  --session-expiration-in-minutes 60
```

2. Initialize OSSH region metadata:

```bash
PATH=/opt/homebrew/bin:$PATH ossh init-regions-config
```

3. Query live OCI resources from the authenticated service tenancy:

- service compartment OCID
- active overlay bastion OCID
- OKE cluster OCID and private endpoint
- active OKE node private IPs; these must replace any existing node IPs in the service SSH config
- service database/private endpoint IP when the service has a database tunnel
- ZTB DNS for the region/realm

Some realms split resources across compartments. For AAT, OC14 is an example: `zerotrust_internalbastion` lives in `account_admin_service`, while OKE and AATADB live in `account_admin_tool`. If a bastion query returns empty in the service compartment, list sibling compartments under the service tenancy and check likely service compartments. Use the bastion-owning compartment in the `ProxyCommand --compartment` value, and use the service OKE compartment for cluster, node pool, and database discovery.

OC5 note for AAT: the service compartment from `config_aat` is the correct compartment anchor for SSH and OKE discovery. If OCI CLI calls appear to hang in OC5, rerun with `--debug --no-retry`; the common root cause is TLS verification against the OC5 temporary customer CA. Build a temporary CA bundle from the OC5 endpoint chain and use `REQUESTS_CA_BUNDLE=<bundle>` for `oci ce cluster create-kubeconfig`. If normal OCI CLI resource-list commands still fail, signed REST calls using the OCI CLI Python environment and that CA bundle can query Container Engine, Database, and Bastion endpoints directly.

OC51 note for AAT: local SSH config evidence uses region `eu-budapest-1`, profile `oc51-aat`, alias `jsk`, and service compartment `ocid1.compartment.oc51..aaaaaaaacjjultfyrm27dolf7mkk5bvjnvhnze5lgy2lzatghgb5jezt4q7a`. The AAT helper may need this compartment passed explicitly because compartment discovery can return no accessible candidates. Before tunnel setup, ensure OSSH has the region PKI bundle:

```bash
/opt/homebrew/bin/ossh download-pki-certs eu-budapest-1
```

If SSH fails with `TLS error detected, please run ossh download-pki-certs eu-budapest-1` or `PKISVC CrossRegion Intermediate eu-budapest-1 certificate is not trusted`, run the command above and retry the same tunnel command once before changing bastion, host, or kubeconfig assumptions.

4. Add or replace the realm block in the service SSH config. Always rewrite the block from live OCI data, even when the realm block already exists, so stale node IPs are removed. Include:

- `<service_key>-service-<alias>-jump` or the service's established host prefix
- `<service_key>-service-<alias>-<node-index>-oke` or the service's established host prefix
- a tunnel comment:

```bash
# ssh -L 6443:<oke_private_endpoint_ip>:6443 [-L <db_local_port>:<db_private_ip>:<db_remote_port>] <service-host>
```

5. Add the ZTB host key if needed:

```bash
ssh-keyscan -t ecdsa <ztb_dns> >> "$HOME/.ssh/known_hosts"
```

6. Start the tunnel. Before starting, check `6443` and any configured database port such as `1522`; if either is already owned by an `ssh` tunnel, kill only that PID and verify the ports are clear. Reuse `6443` for the current realm rather than leaving another realm on `6443` and moving the current realm to `6444`. Do not use broad `pkill ssh`.

For a new realm or after a connection issue, first run a foreground tunnel check so prompts and host-key failures are visible:

```bash
PATH=/opt/homebrew/bin:$PATH ssh -N \
  -F <ssh_config_path> \
  -o ExitOnForwardFailure=yes \
  -L 6443:<oke_private_endpoint_ip>:6443 \
  [-L <db_local_port>:<db_private_ip>:<db_remote_port>] \
  <service-host>
```

In another command, verify listeners before running `kubectl`:

```bash
lsof -nP -iTCP:6443 -sTCP:LISTEN
lsof -nP -iTCP:1522 -sTCP:LISTEN
```

Only after the foreground check succeeds, stop it and start detached:

```bash
PATH=/opt/homebrew/bin:$PATH ssh -fN \
  -F <ssh_config_path> \
  -o ExitOnForwardFailure=yes \
  -L 6443:<oke_private_endpoint_ip>:6443 \
  [-L <db_local_port>:<db_private_ip>:<db_remote_port>] \
  <service-host>
```

If `ssh -fN` exits immediately after the first `kubectl` connection, start the same tunnel with a detached Python subprocess instead:

```bash
python3 - <<'PY'
import os
import subprocess

log = open("/tmp/service-oke-tunnel.log", "ab", buffering=0)
cmd = [
    "ssh", "-N",
    "-F", "<ssh_config_path>",
    "-o", "ExitOnForwardFailure=yes",
    "-o", "ServerAliveInterval=30",
    "-o", "ServerAliveCountMax=3",
    "-L", "6443:<oke_private_endpoint_ip>:6443",
    # Add a database -L argument here only when the service needs one.
    "<service-host>",
]
subprocess.Popen(
    cmd,
    stdin=subprocess.DEVNULL,
    stdout=log,
    stderr=log,
    start_new_session=True,
    env={**os.environ, "PATH": "/opt/homebrew/bin:" + os.environ.get("PATH", "")},
)
PY
```

On macOS, if `ssh -fN` or the detached Python subprocess exits when the first forwarded connection arrives but a foreground TTY tunnel works, a terminal-backed detached tunnel is acceptable:

```bash
nohup script -q /tmp/service-oke-tunnel.typescript \
  ssh -N \
    -F <ssh_config_path> \
    -o ExitOnForwardFailure=yes \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -L 6443:<oke_private_endpoint_ip>:6443 \
    [-L <db_local_port>:<db_private_ip>:<db_remote_port>] \
    <service-host> \
  > /tmp/service-oke-tunnel.out 2>&1 &
```

After starting any detached tunnel variant, verify the listener survived one real `kubectl get pods` call before claiming the tunnel is ready.

7. Generate or refresh the service/realm kubeconfig backup:

```bash
/opt/homebrew/bin/oci ce cluster create-kubeconfig \
  --profile <profile> \
  --auth security_token \
  --cluster-id <cluster_ocid> \
  --file <service_realm_kubeconfig_backup> \
  --region <region> \
  --token-version 2.0.0 \
  --kube-endpoint PRIVATE_ENDPOINT \
  --overwrite \
  --with-auth-context
```

8. Preserve the generated backup, then copy it into the active kubeconfig for kubectl:

- `server: https://<oke_private_endpoint_ip>:6443` becomes `server: https://127.0.0.1:<local_port>` in the generated backup and active copy when needed
- `command: oci` becomes `command: /opt/homebrew/bin/oci`
- stale `--auth security-token` becomes `--auth security_token`

9. Copy the backup into the active kubeconfig:

```bash
cp <service_realm_kubeconfig_backup> "$HOME/.kube/config"
```

10. Verify:

```bash
lsof -nP -iTCP:<local_port> -sTCP:LISTEN
PATH=/opt/homebrew/bin:$PATH kubectl get pods
```

Generic helper full setup path:

```bash
python3 skills/service-oke-realm-setup/scripts/setup_service_oke_realm.py setup \
  --realm <realm> \
  --service <service_key> \
  --config <optional_service_oke_toml> \
  --authenticate \
  --replace-existing-tunnel \
  --start-tunnel \
  --verify
```

If the user has already authenticated externally, omit `--authenticate`.

Before invoking the helper with `--verify`, perform the JIT Preflight propagation check in the browser when the service config provides `[jit].propagation_url`. The helper does not perform browser-based propagation checks itself.

## Stop Rules

- If OCI auth is expired and browser auth is required, start the auth command and wait for the user; do not ask for passwords, cookies, MFA codes, or tokens.
- If service compartment discovery returns multiple candidates, stop and ask for the compartment OCID.
- If live OCI cannot confirm OKE endpoint or required database/private endpoint IPs, do not write persistent SSH or kubeconfig values from Shepherd/repo state. If the user explicitly asks for a best-effort tunnel command from Shepherd state history, provide it as a temporary unverified command and require tunnel/kubectl validation before claiming access works.
- If live OCI cannot confirm current OKE node private IPs, do not leave an existing SSH block untouched as if it were verified; report that SSH IP freshness could not be confirmed.
- If local port `6443` or a configured database port such as `1522` is already used by a different realm, report the owning process, kill only the `ssh` PID that owns the needed port, and verify the port is clear before starting the current realm tunnel. Reuse `6443` for the current realm by default, including one-off kubectl checks. Choose an alternate OKE local port only when the user explicitly asks to preserve the existing tunnel or asks for a temporary/non-mutating check. If the owner is not `ssh`, stop and ask before killing it.
- If `kubectl` says `connection refused`, check `lsof` immediately. If listeners are absent, the tunnel exited; rerun the tunnel in foreground with `ssh -N` to surface host-key prompts, OSSH region errors, or bastion connection failures before trying detached mode again.
- Never delete existing realm backup kubeconfigs; overwrite only the target `config.<realm>.bkp` during an explicit full setup.
