# Service OKE Configuration

Use a TOML file to describe service-specific OKE access details. The shared skill should own the workflow; service configs should own concrete tenancy, JIT, kubeconfig, SSH, and discovery conventions.

## Location

Preferred service-repo location:

```text
.agents/service-oke/<service_key>.toml
```

Example:

```text
.agents/service-oke/aat.toml
```

Shared fallback location for cross-team operator use:

```text
assets/service-teams/<service_key>.toml
```

Example:

```text
assets/service-teams/aat.toml
```

Use the service repo copy as the team's source of truth when the current workspace has one. Use the shared fallback copy when operators need a sanitized config but do not have the service repo checked out.

The config is safe to commit when it contains only operational metadata. Do not store secrets, tokens, private keys, one-time login URLs, cookies, or incident-specific values.

## Discovery Order

1. Explicit config path from the user.
2. Current repo `.agents/service-oke/<service_key>.toml`.
3. Current repo `.agents/service-oke/<service_slug>.toml`.
4. Shared skill fallback `assets/service-teams/<service_key>.toml`.
5. Shared skill fallback `assets/service-teams/<service_slug>.toml`.
6. Existing local kubeconfig and SSH config evidence.
7. Ask for the missing service-specific values.

## Suggested Schema

```toml
version = 1

[service]
# Required for a service config.
key = "example"
display_name = "Example Service"
permissions_slug = "example-service"
tenancy_name = "example_service"

# Optional but recommended.
aliases = ["example-service"]
host_prefix = "example-service"
tenancy_source = "Explicit service OKE config"

[profile]
# Required unless every realm defines `profile`.
template = "{realm}-{service_key}"

[paths]
# Required.
ssh_config = "$HOME/.ssh/example-service/ssh_config"
kubeconfig_backup_template = "$HOME/.kube/config.{service_key}.{realm}.bkp"

[jit]
# Optional. Defaults operationally to prod-admin in the skill.
role = "prod-admin"
# Optional but recommended for kubectl preflight. Service teams should provide
# a stable metadata-only page for their own service when available.
propagation_url = "https://devops.oci.oraclecorp.com/secret-service/<region>/namespace/<namespace>/secret/<secret>"
propagation_secret_name = "<secret>"
propagation_path = "/secret/<namespace>/<secret>/latest"

[tunnel]
# Optional. Defaults to 6443 -> 6443.
local_oke_port = 6443
remote_oke_port = 6443

# Optional. Add only when the service needs extra tunnels.
[[tunnel.extra_forwards]]
name = "database"
local_port = 1522
remote_port = 1522
resource_type = "autonomous_database"
display_name = "EXAMPLEADB"
required = false

[discovery]
# Optional documentation for humans.
mode = "live_oci"
notes = "Use live OCI for cluster, endpoint, bastion, and node IP discovery."

[realms.oc1]
# Minimum required per realm.
region = "us-ashburn-1"
profile = "oc1-example"

# Optional. The helper can often infer and populate these.
alias = "iad"
compartment_id = "ocid1.compartment..."
bastion_compartment_id = "ocid1.compartment..."
realm_domain = "oracleiaas.com"
```

## Minimum Required Fields

For a new service config, provide these service-level fields:

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

For each realm, start with:

```toml
[realms.ocNN]
region = "<oci-region>"
profile = "ocNN-<service_key>"
```

`profile` may be omitted only when `profile.template` produces the exact desired profile name.

For AAT specifically, the shared fallback already provides the service-level defaults, so a new realm usually only needs:

```toml
[realms.ocNN]
region = "<oci-region>"
profile = "ocNN-aat"
```

## Auto-Populated Fields

The generic helper may add missing realm fields back into the TOML after it discovers them:

- `alias`: from OCI region metadata or an existing SSH host block.
- `compartment_id`: from an existing SSH `ProxyCommand --compartment`, or from unique live OCI compartment discovery.
- `bastion_compartment_id`: only when the bastion compartment differs from `compartment_id`.
- `realm_domain`: from OSSH region metadata or an existing SSH block.

The helper does not overwrite existing values by default. Use `--no-update-config` if you want a read-only run that does not populate missing TOML fields.

## Field Notes

- `service.key`: stable short name used in config filenames and profile templates.
- `service.aliases`: user-facing names that should resolve to this service.
- `service.permissions_slug`: Permissions Portal service slug used for `prod-admin` JIT.
- `service.tenancy_name`: tenancy name to use for OCI session authentication.
- `service.host_prefix`: optional SSH host prefix. Defaults to `<service_key>-service`.
- `profile.template`: default OCI profile convention. Use `{realm}` and `{service_key}` placeholders.
- `paths.ssh_config`: SSH config file containing service host and tunnel blocks.
- `paths.kubeconfig_backup_template`: per-realm kubeconfig backup path. Use placeholders instead of hardcoding every realm path when possible.
- `jit.propagation_url`: optional read-only Secret Service URL Codex should inspect before kubectl to confirm JIT has propagated beyond Permissions Portal activation.
- `jit.propagation_secret_name`: optional expected secret name to verify on the propagation page.
- `jit.propagation_path`: optional expected Secret Service path to verify on the propagation page.
- If these fields are absent, Codex should ask the service owner for a service-specific propagation target and use it for the current run. Save it to config only when the user explicitly asks to make it reusable.
- `tunnel.extra_forwards`: optional additional port forwards such as database tunnels. For Autonomous Database discovery, use `resource_type = "autonomous_database"` plus `display_name`.
- `realms.<realm>`: per-realm overrides for region, profile, alias, compartment IDs, realm domain, cluster ID, bastion ID, or kubeconfig path when local conventions differ.

Config values are discovery anchors. Before writing persistent SSH config or reporting success, verify live OCI state for cluster endpoints, bastions, node IPs, and other IP-sensitive values.
