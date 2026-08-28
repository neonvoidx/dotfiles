# Service OKE Realm Setup User Guide

Use this guide when you want Codex to help set up or verify Kubernetes access for a service OKE realm.

## Quick Prompts

Use a plan prompt when you only want Codex to resolve the config and show what it would use:

```text
plan kubectl on ocNN for <service_key>
```

Use the normal kubectl prompt when you want Codex to get you to kubectl using the lightest working path:

```text
kubectl on ocNN for <service_key>
```

Use the setup and verify prompt when you want Codex to actively authenticate, replace the current service OKE tunnel, start the requested realm tunnel, prepare kubeconfig, and prove access with `kubectl get pods`:

```text
set up and verify kubectl on ocNN for <service_key>
```

For AAT, the service can usually be omitted:

```text
plan kubectl on ocNN
kubectl on ocNN
set up and verify kubectl on ocNN
```

## Config Files

The repo-local config is a replacement override:

```text
.agents/service-oke/<service_key>.toml
```

Use this when your service repo needs team-specific values, such as extra realms, different SSH config paths, different kubeconfig backup names, custom profile naming, or service-owned metadata.

Important: this file is not a partial overlay. If `.agents/service-oke/<service_key>.toml` exists, the helper loads that file instead of the packaged fallback. Copy the fallback or template and keep every value the service still needs.

The packaged fallback config lives under the skill:

```text
skills/service-oke-realm-setup/assets/service-teams/<service_key>.toml
```

Use the fallback when a broadly shared, non-secret config is enough or when operators do not have the service repo checked out.

For AAT, the fallback is:

```text
skills/service-oke-realm-setup/assets/service-teams/aat.toml
```

The AIPack `pack/dev-starter/.../aat.toml` copy is a symlink mirror. The source of truth is the skill asset above.

## Minimum Config

Start from:

```text
skills/service-oke-realm-setup/assets/service-oke-config.template.toml
```

Minimum service-level fields:

```toml
[service]
key = "example"
display_name = "Example Service"
permissions_slug = "example-service"
tenancy_name = "example_service"

[profile]
template = "{realm}-{service_key}"

[paths]
ssh_config = "$HOME/.ssh/example-service/ssh_config"
kubeconfig_backup_template = "$HOME/.kube/config.{service_key}.{realm}.bkp"
```

Minimum per-realm fields:

```toml
[realms.ocNN]
region = "<oci-region>"
profile = "ocNN-<service_key>"
```

`profile` may be omitted only when the profile template produces the exact desired profile.

## What Codex Does

For a plan prompt, Codex resolves and reports values only. It does not authenticate, start tunnels, copy kubeconfig, or update files. It should also end with `Kubectl readiness: yes`, `yes with warnings`, or `no`, based on read-only checks of service config, kubeconfig backup, JIT activation/propagation, OCI profile validity, local tunnel listeners, and an optional read-only kubectl probe.

For a normal kubectl prompt, Codex tries to use the lightest working path. It may reuse an existing valid session, tunnel, and kubeconfig when they are already good. If setup is missing, it should guide or run the needed setup steps.

For setup and verify, Codex runs the full setup path:

1. Resolve the service config and realm.
2. Verify service JIT activation and check configured JIT propagation before kubectl.
3. Validate or start OCI session authentication.
4. Discover live OKE and bastion details from OCI.
5. Refresh the service SSH config with current node IPs.
6. Keep only one service OKE tunnel by replacing the old `ssh` process that owns `6443`.
7. Create or refresh the per-realm kubeconfig backup.
8. Copy the selected backup into `$HOME/.kube/config`.
9. Start the tunnel and verify with `kubectl get pods`.

## Common Stops

If the realm is missing from config, add a realm block or pass the region explicitly:

```toml
[realms.ocNN]
region = "<oci-region>"
profile = "ocNN-<service_key>"
```

If OCI login opens a browser and you do not have access, setup cannot continue for that tenancy/profile. Request access or use a realm/profile where you can authenticate.

If your service has a stable Secret Service or equivalent metadata page that proves JIT propagation, add it under `[jit]` in your service config:

```toml
[jit]
role = "prod-admin"
propagation_url = "https://devops.oci.oraclecorp.com/secret-service/<region>/namespace/<namespace>/secret/<secret>"
propagation_secret_name = "<secret>"
propagation_path = "/secret/<namespace>/<secret>/latest"
```

Codex can also use a propagation URL you provide for a single run without saving it.

If port `6443` is already used by an old service OKE `ssh` tunnel, the setup path should kill only that old `ssh` process and reuse `6443` for the current realm. It should not use broad `pkill ssh`.

If a non-`ssh` process owns a needed port, Codex should stop and ask before killing it.

## More Details

Use `references/configuration.md` for the full TOML schema, discovery order, optional fields, and auto-populated metadata behavior.
