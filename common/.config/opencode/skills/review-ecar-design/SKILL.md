---
name: review-ecar-design
description: '[Workflow] Review an ECAR or PreCAR design document using the ecar-design-review skill and produce a readiness report with action items.'
source_type: workflow
metadata:
    last_updated: 2026-03-19T00:00:00Z
    owner: platform_org
---

## Inputs

- Required: design source as local file path, Confluence page, Jira-linked document, or pasted content
- Required: review mode `ecar` or `precar`
- Optional: ECAR ticket key
- Optional: Confluence feedback mode `none`, `draft-comment`, or `post-comment`
- Optional: output file path for the review report

## Entry Conditions

- The `ecar-design-review` skill is available.
- The design source is reachable in the current environment.
- The canonical ECAR process page and SDP checklist are available, or the review will explicitly record missing official references.

## Steps

1. Use the `ecar-design-review` skill and identify the design source type.
2. If the source is a local file, read the design document from disk.
3. If the source is a Confluence page and Atlassian access is available, use `mcp__atlassian__confluence_get_page` to fetch the page content and metadata.
4. If the source is a Jira issue and Atlassian access is available, use `mcp__atlassian__jira_get_issue` to recover the linked design artifact and review context.
5. If the official ECAR process reference is unknown and Atlassian access is available, use `mcp__atlassian__confluence_search` to locate the canonical ECAR process page.
6. If the official SDP checklist reference is unknown and Atlassian access is available, use `mcp__atlassian__confluence_search` to locate the canonical SDP checklist page.
7. If canonical references were found, use `mcp__atlassian__confluence_get_page` to fetch their content; otherwise record that the official references were unavailable.
8. Evaluate whether the design requires ECAR, fits PreCAR, or needs ECD confirmation.
9. Map the design against required ECAR or PreCAR sections and record `present`, `missing`, or `unclear` for each required area.
10. Evaluate every official SDP principle as `Relevant`, `Not Relevant`, or `Clarification Needed`, and add justification for each result.
11. Convert each missing section, unmet principle, or unresolved question into a `major` or `minor` action item with owner, closure condition, and closure rationale, or record the tracking gap explicitly.
12. Derive the expected ticket state as `Done` when no major action items remain, or `AI Follow-up` when any major action item remains.
13. Assign the readiness score from `1` to `5` using the skill rubric and record the sign-off state as observed evidence only.
14. Produce the final report with the required headings in the skill output contract, including `Ticket Status`.
15. If Confluence feedback mode is `draft-comment`, append `Confluence Comment Draft` to the report.
16. If the review would claim ECAR closure, verify that all major action items are resolved and both ECD and ECL approval comments are evidenced in the ECAR ticket; otherwise record that closure is not evidenced.
17. If Confluence feedback mode is `post-comment` and `confluence_add_comment` is not available, stop at the draft and record `manual Confluence comment posting required`.
18. If Confluence feedback mode is `post-comment` and `confluence_add_comment` is available, label `MUTATION`, name the Confluence page target, state that the action is adding the review comment, state the expected outcome and rollback, and wait for explicit approval.
19. After approval for step 18, use `mcp__atlassian__confluence_add_comment` to post the drafted review comment to the Confluence page.
20. If step 19 succeeds, append `Confluence Comment Status` with `posted`; otherwise append `Confluence Comment Status` with `not posted` and record `manual Confluence comment posting required`.
21. If an output path was provided, label `MUTATION`, obtain explicit approval, and then write the report to that path.

## Verify

- The report includes `Applicability`, `Document Coverage`, `SDP Assessment`, `Findings`, `Action Items`, `Sign-off Status`, `Ticket Status`, and `Readiness Score`.
- If Confluence feedback mode is `draft-comment` or `post-comment`, the report includes `Confluence Comment Draft`.
- If Confluence feedback mode is `post-comment`, the report includes `Confluence Comment Status`.
- Every required section has exactly one coverage state.
- Every official SDP principle has exactly one assessment state.
- Every action item includes owner plus closure information, or an explicit tracking gap.
- The expected ticket status matches the presence or absence of major action items.
- ECAR closure is never claimed without evidenced ECD and ECL sign-off.
- Confluence feedback is represented as a paste-ready draft unless `confluence_add_comment` confirms posting.
- The readiness score rationale matches the recorded major and minor action items.

## Done When

- The review exists as a paste-ready or file-backed report with applicability, evidence, action items, and readiness clearly stated.
