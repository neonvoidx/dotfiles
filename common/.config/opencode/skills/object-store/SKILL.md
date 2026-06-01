---
name: object-store
description: Use this skill when you need to access Oracle Object Storage from this repo, especially to resolve a tenancy or account, discover the namespace, list buckets or objects, download logs, or search downloaded files. Prefer direct `oci` CLI commands on the local machine, including `oci raw-request` for SPLAT account lookup, and reuse the shared on-call team config when a team has stable tenancy, namespace, bucket, or prefix conventions.
---

# Oracle Object Storage

Use this skill for read-only OCI Object Storage work from this repo.

The skill can be used in two modes:

- ad hoc: parameterize realm, region, tenancy, namespace, bucket, object name, and output path from the current request
- team-config driven: load the team's shared on-call TOML file when a team has stable Object Storage conventions such as tenancy, namespace, bucket names, common prefixes, or default compartment guidance

Use the shared on-call team configs under `skills/oncall-investigation/assets/service-teams/` as the shared source of truth for Object Storage defaults when they already exist. Put Object Storage guidance in the `team.object_store` block there, including default compartment, default tenancy name, realm-specific tenancy overrides, and bucket-family guidance.

Profile selection for this environment:
- Ask which OCI profile to use for live requests, or suggest a likely profile name when the shared team config or local environment already makes one obvious.
- Prefer the short realm-style profile naming convention when it fits the local setup, such as `r1`, `oc1`, `oc2`, or `oc17`.
- If the user explicitly names a profile, use that exact profile string for the first live command. Do not silently substitute a different local alias or synthesize a temporary config before attempting the workflow.
- When a command example below shows `<PROFILE>`, substitute the selected profile name.

## Guardrails

- Ask for permission before executing any shell command or OCI call.
- This skill is strictly read-only. Do not upload, delete, rename, overwrite, or otherwise modify Object Storage contents.
- Do not run `oci session authenticate`, `oci session refresh`, or any other command that creates, refreshes, or mutates OCI session credentials on the user's behalf. If session-token auth is missing, expired, or unauthorized, stop and ask the user to run `oci session authenticate` themselves, then continue after they confirm.
- Do not hard-code one operator's tenancy, profile, bucket, or local paths unless the user explicitly gives them.
- Do not create temporary OCI config files, merge profile blocks, or patch around missing local profile fields in order to make a profile work. Use the selected profile as-is, let the real workflow fail if it must, then report the exact failure and ask the user to authenticate or repair their profile themselves.
- Treat shared team configs as durable hints, not immutable truth. Confirm live realm, auth state, and any time-specific prefix or object selection before downloading.
- Prefer placeholders and fill them from user input or command results:
  - `<REALM>`
  - `<PROFILE>`
  - `<REGION>`
  - `<SECOND_LEVEL_DOMAIN>`
  - `<TENANCY_NAME>`
  - `<TENANCY_OCID>`
  - `<COMPARTMENT_NAME>`
  - `<NAMESPACE>`
  - `<BUCKET>`
  - `<OBJECT_NAME>`
  - `<OUT_PATH>`
- If a team config provides `default_tenancy_name` plus `tenancy_names_by_realm`, resolve the tenancy name for the selected realm from that map first and fall back to the default only when the realm is not listed.
- Resolve `<SECOND_LEVEL_DOMAIN>` from the local OCI region metadata for the selected realm or region, such as `~/.oci/regions-config.json`, instead of assuming `oraclecloud.com`.
- If a command fails with auth or environment errors, report the exact failure and pivot to the next smallest diagnostic step.

Allowed operations in this skill:
- account or tenancy lookup by name through SPLAT
- namespace lookup
- compartment lookup
- bucket listing
- object listing
- object download
- local decompression of downloaded files
- local read and search of downloaded files

Disallowed operations in this skill:
- upload
- delete-object
- bucket creation or deletion
- object mutation of any kind
- any OCI write action outside Object Storage as part of the investigation

Direct `oci` CLI note:
- standard `oci os` commands work once tenancy or compartment context is known
- account lookup by tenancy name still needs a signed SPLAT request, which this skill performs with `oci raw-request` instead of a repo-local helper script
- when the selected profile is session-token backed, pass `--auth security_token` on live OCI CLI commands in this workflow so the CLI reads the session token instead of falling back to API-key-style profile validation

## Quick Check

Run from the repo root or any working directory on the local machine and first confirm the OCI CLI is installed:

```bash
oci --version
```

Then confirm the Object Storage commands are available:

```bash
oci os ns get --help
```

And confirm raw signed requests are available for account lookup:

```bash
oci raw-request --help
```

If `oci` is not installed or not on `PATH`, stop and ask the user to use a machine or shell environment where OCI CLI is already available.

Before running any live OCI call, verify whether the selected profile appears to be session-token backed. Prefer the smallest direct check that keeps the Standard Workflow moving. If the token is expired, missing, or a live request returns `401 Unauthorized`, stop and ask the user to execute:

```bash
oci session authenticate --profile <PROFILE>
```

If the environment uses a profile-specific auth flow, tell them to run the equivalent authenticate command for that profile and then confirm when it is ready.

When the selected profile is session-token backed, pass `--auth security_token` on the live OCI CLI commands in this workflow, including `raw-request`, `os`, and `iam` calls. Without that flag, the CLI may validate API-key-only fields such as `user` before it attempts the call.

When the user already gave a profile, start the live workflow with Standard Workflow step 1 rather than doing extra local profile archaeology first. If step 1 fails with an auth, session, or profile-config error, surface that exact failure and ask the user to authenticate or repair the profile before retrying step 1.

## Preflight Intake

Before the first live OCI call, gather the required request details in one message whenever possible:

- OCI profile name, or a suggested profile name if the shared team config already provides one
- target realm
- tenancy name or tenancy OCID
- exact UTC date and time window
- target bucket or service surface if already known
- whether the user wants raw files, a merged file, or both

Restate the collected inputs back to the user in absolute form before continuing so the realm, tenancy, and time window are locked.

## Normalization

Normalize obvious operator-input issues before live discovery:

- if the tenancy or account name appears to contain a likely typo, confirm the corrected value once before running SPLAT or bucket discovery
- if the user gives relative or ambiguous time wording, restate the exact UTC date and time range that will be used
- after normalization, repeat the final tenancy identifier and UTC window before the first live OCI command

## Team-Config Workflow

Use this path when the team already knows which tenancy, compartment, namespace, buckets, or log prefixes usually matter.

1. Load the shared team config and select the correct `[[team]]` block.
2. Treat `[team.object_store]` as the starting context for profile guidance, realm-specific tenancy selection, default tenancy name fallback, default compartment, and bucket-family hints.
3. Still verify live results:
   - confirm the active selected profile matches the target realm
   - list buckets before assuming a bucket still exists
   - treat time-window prefixes and object names as request-specific, not config-owned
4. If the shared team config is missing a needed field, fall back to the ad hoc workflow instead of inventing values.

## Standard Workflow

Before step 1, confirm the target realm and OCI profile with the user. Treat realm as required context for authentication and endpoint selection, and treat profile as explicit execution context rather than assuming `DEFAULT`.

Execution rule:
- Treat step 1 as required for the Standard Workflow. Execute it with the exact selected profile as the first live OCI request.
- Do not block step 1 on speculative config repair, alias hunting, or handcrafted temporary profile files.
- If step 1 fails because the profile is expired, unauthorized, malformed, or missing, quote the exact failure briefly, ask the user to run `oci session authenticate` or repair that profile themselves, and then retry from step 1 after they confirm.

### 1) Resolve a tenancy or account by name

This step is required before namespace discovery in the Standard Workflow. Use the tenancy display name to resolve the tenancy or account and record the returned OCID, even if a local profile or shared config already exposes a likely OCID.

```bash
oci --profile <PROFILE> raw-request \
  --auth security_token \
  --http-method GET \
  --target-uri "https://splat-api.<REGION>.oci.<SECOND_LEVEL_DOMAIN>/v1/accounts?name=<TENANCY_NAME>"
```

Capture:

- `ocid`
- `accountName`
- `homeRegion` if present

Also record the realm the user asked for and make sure it matches the active authenticated session.

Before building the SPLAT URL, derive `<SECOND_LEVEL_DOMAIN>` from the local OCI region metadata. For example, `oc16` / `us-westjordan-1` maps to `oraclecloud16.com`, so the SPLAT host becomes `splat-api.us-westjordan-1.oci.oraclecloud16.com`.

If the request fails because the SPLAT endpoint format for the target realm is different, stop and ask the user for the correct realm-specific SPLAT base URL or another approved account-discovery source.

If step 1 did not produce a tenancy OCID and no compartment OCID is available from the request or shared team config, stop and ask the user for the missing OCI identifier before continuing.

### 2) Resolve the Object Storage namespace

```bash
oci --profile <PROFILE> os ns get \
  --auth security_token \
  --compartment-id <TENANCY_OCID>
```

If `--namespace` is omitted on later commands, the CLI can auto-resolve it, but explicit namespace values are easier to reuse and debug.

### 3) List buckets

```bash
oci --profile <PROFILE> os bucket list \
  --auth security_token \
  --namespace-name <NAMESPACE> \
  --compartment-id <TENANCY_OCID>
```

After listing buckets, pause for an explicit elicitation step before continuing:
- ask the user to review the bucket list and confirm whether the expected bucket appears to be present
- if the expected bucket is present, summarize the likely purpose of the closest matches and then ask which bucket they want to access in the target realm
- if the expected bucket is not present, do not continue to object listing yet; first ask whether they want to switch to a different compartment, tenancy, realm, or naming assumption

If the requested bucket is not present:
- tell the user the bucket was not found in the current compartment
- ask whether they want to switch to a different compartment
- if they do, resolve the new compartment and repeat the namespace or bucket-discovery steps as needed

### 4) List objects in a bucket

Use `--prefix` when the bucket is large or when the user gives a date or service name:

```bash
oci --profile <PROFILE> os object list \
  --auth security_token \
  --namespace <NAMESPACE> \
  --bucket-name <BUCKET> \
  --prefix <PREFIX>
```

For log retrieval requests, treat the user's date and time inputs as UTC unless they explicitly say otherwise. When the user gives a point in time or a time range:
- list candidate objects that match the relevant UTC date or service prefix
- expect multiple objects for the same apparent log name because logs may come from multiple hosts
- do not assume one object is sufficient when several host variants exist for the requested window
- download all relevant host or time-slice candidates for the requested window before reporting back

### 5) Download a specific object

```bash
oci --profile <PROFILE> os object get \
  --auth security_token \
  --namespace <NAMESPACE> \
  --bucket-name <BUCKET> \
  --name '<OBJECT_NAME>' \
  --file <OUT_PATH>
```

Prefer `/tmp/...` for temporary log analysis unless the user asks for a durable location.

If the downloaded object is compressed, decompress it locally before searching. Support common compressed log cases such as `.gz` or `.zip`.

When duplicate or near-duplicate filenames exist for the same timestamp:
- keep the host-specific files separate
- inspect each relevant file rather than collapsing them into one result
- summarize which host file contained the evidence you found

When the user asks for a combined artifact:
- preserve the original downloaded files
- create one merged text file with a clear source header before each file's contents
- report the merged file path alongside the original file paths

### 6) Search the downloaded file locally

For log investigations, use `rg` with user-specific pivots such as tenancy name, tenancy OCID, work request OCID, request ID, service path, or operation name.

Example:

```bash
rg -n "<TENANCY_NAME>|<TENANCY_OCID>|POST /20230401/childTenancies|CreateChildTenancy|work request|opc-request-id" <OUT_PATH>
```

If a shared team config includes useful bucket-family or search guidance, use that as seed context and then add request-specific identifiers from the current incident.

## Post-Download Analysis

For log triage after download or merge, start with a compact scan for common failure markers:

```bash
rg -n "ERROR|Exception|5xx|timeout|Failed|WARN|opc-request-id" <OUT_PATH>
```

Then summarize the results by type instead of only listing matches:

- likely real service failures such as exceptions, timeouts, or server-side failures
- expected authorization or environment noise
- invalid-input or nonexistent-resource noise

If a merged file exists, scan it first for broad patterns and then fall back to individual host files when you need to localize the source of a match.

## Common Investigation Patterns

### Interactive log retrieval

Use this conversation flow when the user says something like "get me the logs in object store for `<TENANCY_NAME>` in `<REALM>`":

1. Ask permission to execute.
2. Gather the OCI profile, realm, tenancy name or OCID, exact UTC window, target bucket or surface if known, and whether the user wants raw files, a merged file, or both.
3. Normalize likely typos or ambiguous time inputs and restate the final tenancy identifier plus exact UTC window before running commands.
4. If a shared team config exists, load the matching `[[team]]` block and restate the resolved profile, realm, tenancy, compartment, namespace, and bucket candidates before running commands.
5. Confirm the target realm and make sure the authenticated OCI session behind `<PROFILE>` matches that realm.
6. If the session-backed profile is missing or expired, stop and ask the user to run `oci session authenticate --profile <PROFILE>` themselves before continuing.
7. Do not create temporary OCI config aliases or try to repair the selected profile on the user's behalf; the next action is to wait for the user to authenticate and then retry the failed workflow step.
8. Run the SPLAT account lookup by tenancy name as the required first live OCI step.
9. Confirm the tenancy OCID or compartment OCID is now known. If it is not, stop and ask the user for it.
10. Resolve the Object Storage namespace when the config or request does not already provide it.
11. List buckets once.
12. Summarize the closest bucket matches with brief purpose hints, then ask the user which bucket they want.
13. Add an elicitation step asking the user to evaluate whether the expected bucket is actually present in the results before proceeding.
14. If the bucket is not listed, offer to switch compartments and repeat discovery.
15. List candidate log objects for the requested UTC window, starting from any configured bucket prefixes when available.
16. Download all relevant host or time-slice variants for that window.
17. Decompress when necessary while preserving the originals.
18. If the user asked for a combined artifact, create a merged file with per-source headers.
19. Read and search the file contents locally, starting with the merged file when one exists.
20. Report which objects were checked, where the files were written, and what was found.

### Bucket or namespace discovery without tenancy-name lookup

If the user only has a tenancy or compartment OCID and does not have a tenancy display name:
- pause and ask for the tenancy display name or another approved account-discovery source so the required Standard Workflow step 1 can still run
- if the user explicitly instructs you to skip Standard Workflow and proceed from the known OCID, restate that deviation before starting with `get-namespace`

### Compartment lookup by name

If the user is working below the tenancy level:

```bash
oci --profile <PROFILE> iam compartment list \
  --auth security_token \
  --name <COMPARTMENT_NAME> \
  --compartment-id <PARENT_COMPARTMENT_OCID> \
  --compartment-id-in-subtree true \
  --access-level ACCESSIBLE \
  --all
```

## Troubleshooting

- `401 Unauthorized` or `NotAuthenticated`: likely expired or insufficient OCI credentials for the selected profile. Do not try to set or refresh the session token yourself. Ask the user to run `oci session authenticate --profile <PROFILE>`, then resume from the last successful step after they confirm. Do not restart the entire discovery flow unless earlier context is now invalid. Run the CLI with the explicit selected profile.
- profile-config parse errors such as missing required OCI config fields: first confirm the workflow actually passed `--auth security_token` on the selected session-token-backed profile. If the flag was missing, retry the failed step with `--auth security_token` before concluding the profile is unusable. If the step still fails with the same profile-config error, treat the selected profile as unusable, do not manufacture temporary profile configs, ask the user to repair or re-authenticate it themselves, and then retry the failed workflow step with that same profile after they confirm.
- `404 NotAuthorizedOrNotFound` or similar `404` responses: this can also mean the session, realm, or compartment is wrong, not just that the resource is missing. Ask the user to run `oci session authenticate --profile <PROFILE>` for the target realm and confirm the request is using the intended profile.
- `oci: command not found`: switch to a machine or shell where OCI CLI is installed and already configured.
- SPLAT account lookup fails: confirm the target region, realm-specific SPLAT domain, authenticated profile, and tenancy display name before retrying. If the realm uses a different SPLAT base URL, ask the user for it.
- `No buckets found` or `No objects found`: confirm the namespace, compartment, bucket name, and prefix before widening the search.
- team config points at the wrong bucket, namespace, or compartment: treat the config as stale, report the mismatch clearly, continue with live discovery, and update the config separately if the user wants.

## Output Style

When reporting results back:
- state the target realm explicitly
- state the resolved tenancy, namespace, and bucket names explicitly
- include the output directory used for the download or analysis
- include the exact object or set of objects downloaded
- include the merged-file path if one was created
- note the UTC date or time window used for the search
- say when multiple hosts produced separate files with similar names
- say whether decompression was required
- summarize whether the search found the requested evidence and whether the notable matches look like real failures, auth noise, or bad-input noise
- call out any assumptions, especially the selected profile, region, and search terms
- if a shared team config was used, say which team entry supplied the starting context
