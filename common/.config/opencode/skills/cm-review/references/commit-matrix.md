# Commit-Diff Validation Matrix

Use this reference when a `release-backed` or `hybrid` CM has release evidence plus Bitbucket/SCM diff information, commit tables, PR links, or explicit commit hashes. For pure `runbook-backed` CMs, use it only when the user asks for commit validation or when code, repo, artifact, release, or config evidence is part of the reviewed scope.

## Scope

- Treat Bitbucket or SCM compare ranges as candidate evidence, not authoritative deployment scope when release artifacts, config hashes, Release Check evidence, or owner-provided release details identify a narrower CM delta.
- Fetch supporting commits only when needed to explain validation evidence.
- Resolve the current CM release delta from:
  - application artifact names and current/new versions
  - flock or config current/new hashes
  - linked Shepherd release artifacts, resource changes, and phase or target scope from Release Check
  - implementation and rollback target scope from the CM
  - runbook or provider repo scope for runbook-backed and hybrid CMs

## Candidate Relation Labels

- `in-scope`
  Commit changes a deployed application, worker, canary, shared runtime library, DAL, runtime config, build/dependency or SLAPS-sensitive surface, Shepherd/config artifact, rollback target, runbook target, or other operational surface released by this CM.
- `supporting evidence only`
  Commit changes tests, generated validation output, docs, or tooling that only supports an in-scope change and is not deployed by the CM.
- `compare-only / out of CM scope`
  Commit appears in a broad compare but is outside the current CM release delta, such as a different artifact, unrelated SPLAT/spec/config path, unrelated flock or phase, a commit before the CM current config baseline, or a path not shipped by the linked releases.
- `blocked`
  Available evidence is insufficient to decide whether the candidate commit is related to the current CM release.

## Validation Relevance Labels

- `requires CM validation`
  Production/runtime code, public or internal API behavior, model or DTO conversion, DAL or persistence behavior, worker or workflow behavior, runtime config, Shepherd/Terraform/policy, release artifacts, dependencies, security posture, logging behavior, rollback behavior, or operational scripts that run during deployment.
- `CI/test evidence only`
  Unit tests, integration tests, test fixtures, mocks, test resources, or generated validation output that only prove another change and do not alter deployed behavior.
- `no runtime validation required`
  Docs-only, skill-only, comments-only, local developer tooling, formatting-only, or non-deployed metadata changes.
- `blocked`
  Remote diff was unavailable, incomplete, or ambiguous enough that validation relevance cannot be determined.

## Required Validation By Changed Surface

- API or resource changes require API/resource unit or integration tests and validation of request, response, and error mapping.
- Model converter or DTO changes require converter round-trip and null or compatibility tests.
- DAL changes require entity converter, repository, store-manager, pagination, and in-memory persistence tests as applicable.
- Worker or workflow changes require workflow unit tests and failure-path coverage.
- Spec changes require spec validation output and API compatibility evidence.
- Config, Terraform, policy, or Shepherd changes require plan or resolved-config diffs and target-scope validation.
- Security changes require targeted negative tests or scan evidence for the fixed class of issue.
- Dependency changes require build/dependency validation, and SLAPS-related changes require SLAPS scan or approval evidence only when SLAPS applies.
- Logging changes require regression checks that sensitive data is not logged and production log levels are correct.

## Outcome Labels

- `covered`
  CM names or links concrete evidence specific enough for the changed surface and the evidence plausibly exercises or verifies the changed behavior, config, dependency, security property, rollout target, or rollback path.
- `partial`
  CM provides concrete evidence that covers only part of the changed surface or only some required risk dimensions.
- `generic only`
  CM relies on broad HERDS, canary, alarm, dashboard, pre-prod, no-SEV, screenshot, or Shepherd-success wording without showing that it exercises or verifies the commit's specific changed surface; treat this as a validation gap in findings.
- `missing`
  No CM validation evidence is provided for the commit, or the only evidence is so generic that there is no defensible way to tie it to the changed surface.
- `not required`
  Commit is test-only, docs-only, tooling-only, or otherwise non-deployed and does not change rollout risk.
- `blocked`
  Commit evidence cannot be fetched from the remote source.

## Matrix Record

For each CM-related commit, record:

- commit id and title
- source, such as CM commit table, Bitbucket compare, SCM PR, or explicit hash
- why the commit is related to the current CM release delta
- changed-file categories, such as API, worker, DAL, spec, config, Terraform, security, dependency, or docs-only
- validation relevance
- required tests or evidence inferred from the diff
- CM validation, test result, Shepherd, HERDS, SLAPS when applicable, or manual evidence that covers it
- why the evidence is specific enough to cover the changed surface, or why it remains generic only
- outcome label

## Finding Rules

- Count evidence as specific only when it names or links a concrete run, page, dashboard, screenshot, command output, test job, release validation, plan diff, scan, approval result, or manual validation output that matches the changed surface, target scope, artifact/config version, timing, and environment.
- Record `compare-only / out of CM scope` commits in an excluded-commit note with count, commit ids when useful, and exclusion reason. Do not include them as validation-gap rows.
- Call out every deployment-affecting `partial`, `generic only`, `missing`, or `blocked` commit in the findings.
- Do not collapse unrelated commits into one generic validation gap when the required evidence differs by changed surface.
- If broad compare evidence and narrower release evidence conflict, explain which evidence defines the CM release delta and carry the mismatch as residual risk or a finding when it affects approval confidence.
