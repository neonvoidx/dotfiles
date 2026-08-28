# Writeback Contract

Only post findings back to the ticket when the user explicitly asks.

## Current Ticket System

CM review writeback is Jira-only today.

- Author CM writeback comments in Jira wiki markup.
- Do not use Markdown as the source format for CM writeback comments.
- If CM review later needs a non-Jira writeback path, define that format separately instead of reusing this Jira contract.

## Repository Version Preflight

Use the repository version preflight result captured at workflow start.

If the workflow result is missing, use `repository-version-preflight` with `../SKILL.md` as the caller before drafting the customer-facing body.

If the preflight says the active CM Review skill is stale, add a customer-visible warning immediately after the required first line and before findings:

`WARNING: This writeback is not using the latest CM Review skill version. It used CM Review vX.Y.Z, but the latest repository CM Review skill version is vA.B.C. The review may not include the latest workflow checks.`

If the preflight says the repository comparison could not be completed, do not claim the run used the latest version. Add a customer-visible warning in the same top-of-comment position:

`WARNING: The CM Review repository version check could not be completed. This writeback used CM Review vX.Y.Z, but it could not verify whether that is the latest repository version. Blocker: <brief blocker>.`

The warning is informational and must not block the writeback when the user asked for one.

## Required Prefix

Prefix the first line of every posted comment with:

`[codex-gpt-5.5]`

The same first line must also mention the active CM Review skill version from `../SKILL.md`, for example:

`[codex-gpt-5.5] CM Review v1.6.0 based on the ticket fields and linked release evidence.`

If the version in `../SKILL.md` has changed, use that current version in the comment instead of copying the example.

## Comment Shape

Use this structure:

1. One opening line stating this is CM Review vX.Y.Z based on the ticket fields and linked release evidence.
2. A stale-version warning line when the active version is older than the latest repository version, or a version-check-limited warning when repository comparison failed.
3. A flat findings list, ordered from highest to lowest severity.
4. An optional `Positive verification:` section for confirmed alignment summaries.

In Jira wiki markup, prefer this layout:

- opening line with the required prefix and active CM Review skill version
- optional `WARNING:` line required by repository version preflight
- `h3. Findings`
- `*` bullets for findings
- `h3. Positive verification`
- `*` bullets for concise confirmed-alignment summaries
- optional `h3. Residual risk`
- `*` bullets for remaining risk or follow-up

## Positive Verification Style

Use `Positive verification` to summarize checks that aligned with the CM, not to list every raw evidence detail. Prefer concise result summaries such as:

- `* Release scope alignment - Structured Change Location(s) matches the linked Shepherd target regions.`
- `* Artifact alignment - Linked Shepherd release deploys the CM-stated artifact and version.`
- `* Pre-start status alignment - Linked release is still in the expected review/pre-start state for this CM.`

Do not use positive verification bullets to say something is "not a finding" or to restate low-value raw state details. Avoid standalone details such as `cmUrl=null is expected...` or full phase-state narration like `Shepherd state is Halted / Reviewing, with current phase ...`, unless the exact detail is necessary to explain an active finding or residual risk.

## Manual CM Required-Section Comment

When posting CM Review findings for a runbook-backed, operational, or otherwise manual CM, the writeback comment must request a `Why this manual change is required?` section if the ticket does not already include that exact section with specific justification.

Use a concise finding such as:

`* Medium - Please add a section titled "Why this manual change is required?" that explains why this work must be handled as a manual change instead of relying only on generic business justification.`

## Canary Cadence Finding

When posting CM Review findings for a release-backed or hybrid CM that relies on canary validation between stages, regions, or realms, the writeback comment must call out a cadence mismatch when the bake window is shorter than the canary cadence and no completed post-deploy canary result or alternate changed-surface validation exists before promotion.

Use a concise finding such as:

`* Medium - The CM relies on canary validation between rollout stages, but the documented bake window is shorter than the canary cadence. Please extend the bake to include a completed post-deploy canary run, provide an on-demand canary result, or document alternate validation that covers the changed surface before promoting to the next stage, region, or realm.`

## Comment Rules

- Keep the comment ticket-specific and concise.
- Before posting, confirm `repository-version-preflight` ran or was attempted, and that any `stale` or `unverified` status produced the required `WARNING:` line.
- Use Jira wiki syntax for headings and bullets, such as `h3.` and `*`.
- When the comment mentions review identifiers that have URLs, use full Jira wiki hyperlinks instead of bare identifiers. This applies to Shepherd releases, rollback releases, plan-only releases, Bitbucket commits, SCM commits, PRs, Jira tickets, Confluence pages, dashboards, or other evidence links identified during review.
- Prefer canonical full URLs when available. For example, use `[4045a042...|https://devops.oci.oraclecorp.com/shepherd/projects/limits/flocks/limits-dp/releases/4045a042-ce02-4496-93bd-e9fb726fef21]` for Shepherd releases and `[743b5db0446|https://bitbucket.oci.oraclecorp.com/projects/EXAMPLE/repos/example-repo/commits/743b5db0446]` for commits. If only an official short URL is available, link that full short URL instead of leaving the identifier unlinked.
- Never post placeholder URLs such as links containing `<project>`, `<flock>`, `<repo>`, `<release-id>`, or other unresolved template tokens. If the full URL cannot be verified or reconstructed, leave the identifier as plain text and state the evidence-link limitation when it matters to the review.
- Link the first meaningful mention of each identifier; avoid repeating the same long hyperlink in every bullet unless it materially improves readability.
- Do not mention ticket comments unless the user asked to include them.
- Do not paste raw JSON, raw tool output, or large plan bodies.
- Do not paste the full commit-diff validation matrix by default. Post the matrix only when the reviewer decides that level of detail materially helps the CM record; otherwise post the matrix-derived findings and keep the generated matrix as reviewer evidence.
- Include exact regions, versions, commits, or release identifiers only when they materially support the finding.
- If the review is based on linked Shepherd evidence, say so plainly.
- If commit verification was limited by missing artifact or commit detail, say that explicitly instead of overstating confidence.
