---
name: oci-ops-ssh-connect
description: Preflights local ossh and oci-ops access, reads a Jira ticket to identify a target hostname and region, validates OCI authentication, resolves the tenancy OCID, and returns the appropriate oci-ops SSH connection command. Use when a user asks to SSH to an OCI host from a Jira ticket, set up ossh or oci-ops access, resolve a host region or tenancy, or needs an oci-ops SSH command.
---

# OCI Ops SSH Connect

## Goal

Safely derive a ready-to-run `oci-ops ssh connect` command from a Jira ticket.
Read ticket data and validate local prerequisites, but do not open an SSH session or change OCI configuration unless the user explicitly requests it.

## Workflow

1. Confirm `ossh`, `oci-ops`, and `oci` are installed and visible on `PATH`:

```bash
command -v ossh
command -v oci-ops
command -v oci
```

If one is unavailable, report the missing tool and stop. Do not guess an installation method.

2. Ask for the Jira ticket key if it was not supplied. Read it with the Jira MCP using `jira_jira_get_issue` and request `*all` fields. Use the Jira-SD MCP only when the ticket is explicitly Jira Service Desk.

3. Extract the target hostname, OCI region, and tenancy name or OCID from the ticket summary, description, comments, and custom fields. Prefer explicit labeled values. If more than one credible value is present, present the candidates and ask the user to choose. Never infer a region solely from a hostname.

4. Resolve the tenancy OCID when the ticket identifies the tenancy context as `csiprod` but does not include an OCID. Treat `csiprod` as the required local OCI profile, not as an OCID. First validate that profile without displaying configuration values:

```bash
oci --profile csiprod session validate --local
```

The stock OCI CLI does not resolve a tenancy name to an OCID: `oci iam tenancy get` requires `--tenancy-id`. If the tenancy-named profile is unavailable, instruct the user to authenticate it with the explicit region extracted from the ticket. Do not execute this command:

```bash
oci session authenticate --profile-name <tenancy-name> --region <region>
```

After the user completes authentication, validate the session and retrieve the tenancy OCID with the team's approved profile-based lookup. Do not invent an Accounts API endpoint, parse credentials, or substitute an unrelated tenancy.

5. Validate the OCI session and target-region access before producing the connection command:

```bash
oci --profile <profile> session validate --local
oci --profile <profile> --region <region> iam region list --query "data[?name=='<region>']"
```

If either validation fails and the profile is `oc1`, use the OCI session recovery workflow: refresh it with interactive authentication permitted, then re-run both commands. Otherwise report the failure and the profile/region needed; do not silently use a different profile.

If the region-scoped call reports `user` is missing, retry it with the profile's session-token authentication instead of treating the profile as incomplete:

```bash
oci iam region list --config-file ~/.oci/config --profile <profile> --auth security_token --region <region> --query "data[?name=='<region>']"
```

Do not edit the profile or produce the SSH command until this region-scoped call succeeds.

6. The connection command requires locally generated SSH configuration. Do not run the generator automatically. If `oci-ops ssh connect` reports that SSH config files do not exist, return this prerequisite command using the resolved ticket values, then wait for the user to run it:

```bash
oci-ops ssh generate-config --region <region> --tenancy '<tenancy-ocid>'
```

7. Construct, but do not execute, the exact SSH command. Keep it on one line and quote values that could contain shell-sensitive characters:

```bash
oci-ops ssh connect --region <region> --tenancy <tenancy-ocid> --host <hostname>
```

Before returning it, verify the local command's accepted flags with:

```bash
oci-ops ssh connect --help
```

Use the documented equivalent flags if they differ. Never include tokens, private keys, or credentials in output.

## Response Format

Report only the relevant evidence and the final command:

```text
Hostname: <hostname>
Region: <region>
Tenancy OCID: <ocid>
OCI session: valid for profile <profile>

Run:
oci-ops ssh connect ...
```

If blocked, identify the exact missing tool, ticket value, profile, session state, or tenancy-lookup command and ask the shortest question needed to continue.
