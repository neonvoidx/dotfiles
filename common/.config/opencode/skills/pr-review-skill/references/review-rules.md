---
name: review-rules
description: Consistent evaluation rules for PR review regardless of whether the source is local changes, Bitbucket, or OCI DevOps SCM.
metadata:
  owner: platform_org
  last_updated: 2026-03-19
---

## Scope

- Apply these rules after the code to review has been obtained.
- Use the same rules for self-review, Bitbucket PR review, and SCM PR review.
- Keep the review standard constant across retrieval paths. Only artifact acquisition may vary.

## File eligibility

- Review every eligible source-code diff file; do not silently skip eligible files.
- Review only source-code diffs and approved text-manifest diffs; do not expand into unrelated repository files by default.
- Exclude non-code files such as `.md`, `.yaml`, `.yml`, `.json`, `.xml`, `.ini`, `.conf`, `.env`, `.properties`, and `.toml`.
- Treat manifest-like `.txt` files as dependency or version artifacts only; do not apply code-only rules to them.
- If the repository defines additional include or exclude rules, apply those repository rules and note the override.

## Required rule-family coverage

- Evaluate every eligible file against all rule families in the approved rubric.
- At minimum, consider:
  - Null Safety
  - Error Handling
  - Design Principles and Dependency Injection
  - Code Duplication
  - Naming, Magic Numbers, and Readability
  - Source Code Organization and Comments
  - Performance
  - Security
  - Observability and Logging
  - Testing
  - OCI-specific guidance such as Workflow classes, Workflow versioning, Kiev rules, and Dependency Management
- Do not skip a rule family just because no issue is obvious at first glance.
- If a rule family has no findings, record none mentally and continue; do not treat lack of findings as permission to skip evaluation.

## Guidance order

- Evaluate code against the approved rubric only.
- Apply guidance in this order:
  - team or org guidance
  - language-specific guidance
  - repository-specific overrides
- If the rubric is incomplete or missing, stop and ask for the correct review standard instead of inventing one.

## Review method

- Review the changed code first. Do not drift into repository-wide commentary unless the user asks for broader review.
- Read the diff for each eligible file before producing findings.
- Use surrounding context only when required to understand the changed code correctly.
- Do not apply rules outside the approved rubric.
- Group repeated violations of the same rule in the same file into one finding anchored at the first occurrence.
- Do not emit one finding per line for repeated violations of the same rule in the same file.
- Keep findings specific to an observed issue in the reviewed change.

## Rule scoping

- Apply Null Safety or NPE rules only to code files and only to changed code segments; never classify `.txt`, `.md`, or config files as NPE findings.
- Apply Dependency Management checks to text manifests such as dependency-version files, including formatting and version-bump consistency.
- Apply OCI-specific workflow versioning rules when `@Step` definitions or workflow graph changes appear; require the rubric’s expected version bump for incompatible changes.
- Apply Kiev or schema-evolution rules to entity schema diffs; prohibit non-additive changes or type mismatches when the rubric says they are invalid.

## Severity

- Use `Blocker`, `Major`, `Minor`, or `Nit` when the repository or team already expects that scale.
- Otherwise use:
  - `MUST FIX` for correctness, security, runtime-failure, or build-break risks
  - `SHOULD FIX` for important maintainability or non-critical correctness concerns
  - `NICE TO HAVE` for minor style or idiom issues

## Finding format

- `Rule Violated: <exact rubric heading or repo rule>`
- `Severity: <chosen scale>`
- `Description: <concise explanation>`
- `Affected lines: <file and destination lines>`
- `Code Example: <minimal before/after or representative snippet>`
- `Suggestion: <clear remediation>`
- `What to verify: <tests, edge cases, or behavior to re-check>`
- Use the first affected line as the anchor line when an inline comment must be posted.
- For repeated occurrences in the same file and rule, list all affected lines inside one grouped finding.

## Output rules

- Each finding must include rationale, file or line reference, suggested fix, and what to verify.
- Keep findings review-oriented. Do not rewrite large chunks of code when a concise correction is enough.
- Separate findings from optional patches.
- If no issues are found, say that explicitly and call out residual uncertainty such as missing tests, missing docs, or generated files.
- Produce an overall review status:
  - `Needs Work` if any `MUST FIX` findings exist
  - `Ready` if findings are only `SHOULD FIX` or `NICE TO HAVE`
- Summarize findings by severity and by category in the final review output.

## Posting rules

- Draft findings before attempting any PR mutation.
- When posting is approved, post an inline comment for every finding rather than collapsing all findings into summary-only output.
- If write-capable tools are unavailable, return a paste-ready review instead of implying comments were posted.
- If posting comments is requested, apply the mutation gate before every state-changing step.
- Retry failed comment posts up to two additional times, then record `manual review required`.
- Do not claim a comment was posted until the underlying tool confirms success.

## Verification

- The same severity scale and finding format appear in all review modes.
- Every eligible file ends in exactly one state: `no findings recorded` or `findings prepared`.
- Every eligible file was evaluated against the full approved rule set.
- No review is declared complete until the chosen rubric and repository overrides were applied.
