---
name: oci-build-service
description: Use when writing or debugging ocibuild.conf, troubleshooting build failures on OCI Build Service runners, or publishing artifacts to Artifactory generic repos.
metadata:
  owner: ocm
  last_updated: 2026-03-19
---

## ocibuild.conf key reference

Every Build Service repo needs an `ocibuild.conf` at the repo root. The required fields are `runnerTag`, `name`, `team`, `phoneBookId`, `description`, `version`, and `steps`.

Three settings cause the most trouble when missing or wrong:

- **`runnerTag: latest`** (currently 1.0.380). SCM-based repos require >= 1.0.266. Do not pin to a specific number unless you have a reason — it drifts stale.
- **`enableGit: true`** makes `.git` available in all steps. Without it, `git rev-parse` in ldflags fails silently and you get empty version strings.
- **`authCompartmentOcid`** is the phonebook compartment for authorization. OCM repos use `ocid1.compartment.oc1..aaaaaaaa3mxbk5qvg3xxp6nkmmtxwzshf66trhna4ngefysas3f7lawddlga`.

### Version interpolation variables

| Variable | Expands to |
|----------|-----------|
| `${BLD_NUMBER}` | Auto-incremented build number per branch |
| `${?BLD_BRANCH_SUFFIX}` | Branch name with leading hyphen; null on main/master |
| `${BLD_SHORT_COMMIT_HASH}` | Git short SHA |

### Branch control

`triggerOnCommitBranches` controls which branches trigger builds. `releaseBranches` controls which branches run publish steps (others get dry-run). `snapshotBranches` controls where `${?BLD_SNAPSHOT_SUFFIX}` expands to `-SNAPSHOT`.

## Step type decision tree

If your step needs Go compilation or any `go` command: use a `golang` step. The `make` runner (`build-runner-make`) has no Go installed, and `goVersion` is silently ignored on `make` steps. Setting `runnerImage` on a make step gets the image but not the right Go version. Combining `environment` PATH overrides with `runnerImage` on make steps causes `FailedToCreateMainContainer` — container scheduling fails silently.

If your step runs Makefile targets that do NOT call Go (packaging, file manipulation, shell scripts): use `make`.

If your step publishes binaries or tarballs to Artifactory: use `publishgeneric`.

If your step builds Docker images: use `dockerizer`. If it pushes them: use `publishdocker`.

If you need an explicit git checkout (shallow clone, specific depth): use `git`.

For Python packaging and publishing: use `python` and `publishpython` respectively.

| Step type | Runner | Key property |
|-----------|--------|-------------|
| `golang` | `build-runner-golang-boring-ssl` | `goCommands`, `goVersion` |
| `make` | `build-runner-make` (no Go) | `makeCommands: [{target, args}]` |
| `publishgeneric` | — | `repository`, `filePathsToPublish: [{localFile, targetDir}]` |
| `publishdocker` | — | `repository`, `imageName` |
| `dockerizer` | — | `images: [{platform}]` |
| `git` | — | `gitCloneType`, `depth` |

Common step properties: `dependsOn`, `artifacts`, `environment`, `skipOnDryRun`, `buildTimeout`, `runnerImage`.

## Runner constraints

Runners are isolated containers with no outbound internet. Every Go dependency must be vendored (`go mod vendor`) and every `go` command must use `-mod vendor`. Attempting to fetch from `proxy.golang.org` will hang and timeout.

The `.git/` directory is stripped from artifact tars between steps. If you need git commands in a non-checkout step, set `enableGit: true` at the top level.

**Every non-publish step must include `artifacts: ["**"]`** to forward its working directory to the next step. Without it, the next step starts with an empty directory. This also applies to `publishgeneric` steps when chaining to a second publish step — publish steps do not forward artifacts by default.

The `go.mod` file must use a two-part `go` directive (e.g., `go 1.25`). The `toolchain` directive (e.g., `toolchain go1.25.7`) is rejected as "unknown directive" on the build runner — omit it entirely.

Supported Go versions (as of 2026-03-18): 1.25.7, 1.25.4, 1.24.13, 1.24.12, 1.24.11, 1.24.4, 1.24.3, 1.24.1, 1.23.4, 1.23.0, 1.22.10, 1.22.6, 1.22.5, 1.22.3, 1.22.2, 1.21.13, 1.21.5, 1.20.12, 1.19.13. There is no Go 1.26.

There is no programmatic access to Build Service — no DOPE MCP, no OCI CLI (`oci devops` is a different system). Diagnosis requires manually downloading build logs from the UI at `devops.oci.oraclecorp.com/build`.

## Artifactory publish mechanics

OCI Artifactory generic-local repos do not allow the Build Service deployer to overwrite existing artifacts. The deployer's flow is delete-then-PUT. The delete returns 404 (permissions issue masked as not-found), and the subsequent PUT silently fails. The build step reports success despite the file not being updated. First-time publishes to new paths succeed; only overwrites fail.

Admin tokens can PUT directly to overwrite:

```sh
curl -sf -X PUT -H "Authorization: Bearer $ARTIFACTORY_TOKEN" \
  --upload-file local-file \
  "https://artifactory.oci.oraclecorp.com/<repo>/<path>" \
  -w "%{http_code}" -o /dev/null
```

For version discovery, use the Artifactory storage API instead of maintaining a mutable pointer file (the deployer can't update pointer files after their first publish). `GET /api/storage/<repo>/` returns a JSON listing of children. Parse `v*` folders, extract semver, pick highest. Anonymous access works (VPN required).

MARS is replacing OCI Artifactory. Build Service now publishes to MARS with synchronization to Artifactory. The Artifactory UI may be inconsistent for up to 15 minutes during sync. MARS responses include an `opc-request-id` header; Artifactory responses include `X-Artifactory-Id`.

## Provisioning a new Artifactory repo

Artifactory generic repos are request-based, not self-service. Build Service does NOT create repos — provision first, then reference in `publishgeneric` steps.

### Prerequisites

1. Active Phonebook entry with a Sev-2-able Jira SD queue
2. At least two repo admins who have **already logged into** `artifactory.oci.oraclecorp.com` (API can't assign permissions to users who haven't logged in)

### Request

File a Jira SD ticket in project **ART** at `jira-sd.mc1.oracleiaas.com`, or use the "Request a new repository" button on Confluence page `12073526776`.

| Field | Example value |
|-------|---------------|
| Team Name | `ocm` |
| Phonebook Entry | `https://devops.oci.oraclecorp.com/phonebook/<team>` |
| Repo Type(s) | `generic` |
| Service Name Tag | `aipack` |
| Repo Admins | GUIDs of 2+ admins |
| Anonymous Access | False |

Turnaround: ~3 business days. Automation creates two repos per type: `<team>-<tag>-dev-generic-local` (dev) and `<team>-<tag>-release-generic-local` (release). Naming constraint: 64 chars max, 41 chars max for team + tag combined.

### Post-provisioning

Newly provisioned repos have NO anonymous read access. Build Service can write (via `buildservice-deployer-2` credentials), but downloads return 404 until read permissions are configured. Repo admins must create permission targets via the Artifactory Admin panel. The phonebook ID in `ocibuild.conf` must match the phonebook tied to the Artifactory repo.

## Common failure patterns

| Symptom | Cause | Fix |
|---------|-------|-----|
| `go: command not found` in make step | `build-runner-make` has no Go | Change step type to `golang` |
| `goVersion` has no effect | Property ignored on `make` steps | Change step type to `golang` |
| `FailedToCreateMainContainer` | `environment` PATH override + `runnerImage` on make step | Use `golang` step type instead |
| Next step has empty working directory | Missing `artifacts: ["**"]` on previous step | Add `artifacts: ["**"]` to every non-final step |
| `unknown directive: toolchain` | `go.mod` contains `toolchain go1.x.y` | Remove `toolchain` line, keep two-part `go` directive |
| Module download timeout / `proxy.golang.org` unreachable | No outbound internet on runners | Run `go mod vendor`, use `-mod vendor` |
| `git rev-parse` returns empty or fails | `.git` stripped between steps | Set `enableGit: true` at top level |
| Artifact overwrite silently fails | Deployer can't overwrite in generic-local repos | Use immutable versioned paths; admin token for manual overwrite |
| Published file not updated, build shows success | Delete-then-PUT flow; delete 404s silently | Same as above — don't rely on deployer overwrites |
| Build uses wrong/old Go version | `go` on PATH in golang runner is pre-1.21 | Set explicit `goVersion` on the `golang` step |

## Team examples

Four OCM repos show the main build patterns:

| Repo | Pattern | Notes |
|------|---------|-------|
| `ocm-shepherd` | git-checkout only + `pipelineTriggerConfig` | Minimal build; real work happens in the downstream DevOps Pipeline |
| `replication-plugin` | golang test, golang build, make package, publishgeneric | Full Go CI/CD with coverage — reference for multi-step Go builds |
| `release-tooling` | make setup, make test, python package, publishpython | Python/Make pattern, no pipeline trigger |
| `openshift-e2e` | dockerizer, publishdocker | Docker-only build |

## Two-tenancy architecture

Build Service and DevOps Pipelines live in different tenancies for OCM:

| Thing | Tenancy | Namespace |
|-------|---------|-----------|
| SCM repos (aipack-oci etc) | SCM central | `axuxirvibvvo` |
| OCM DevOps Pipelines | OCM service | `axrzkmpmhdpx` |

`pipelineTriggerConfig` in ocibuild.conf is optional — it triggers a DevOps Pipeline after the build. Repos that do build + publish entirely in ocibuild.conf steps don't need it.

## Support

- Slack: `#oci_build_svc_users`
- Build UI: `devops.oci.oraclecorp.com/build`
- Canonical docs: Confluence BLD space (pages 12077639327, 12077639252, 12077639362)
