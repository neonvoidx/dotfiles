---
name: ecar-design-review
description: Use when reviewing a design document for ECAR, PreCAR, or equivalent OCI architecture review and you need to assess applicability, required sections, SDP coverage, action items, and readiness before producing feedback.
metadata:
  owner: platform_org
  last_updated: 2026-03-19
---

## When to use

- Use for ECAR, PreCAR, or equivalent OCI architecture design reviews.
- Use when the user wants a review artifact, readiness score, or action-item list rather than ad hoc commentary.
- Use when the input is a design doc, Confluence page, ticket-linked design, or pasted architecture notes.

## When not to use

- Do not use for code-only review, API-spec-only review, or pull-request review without a design document.
- Do not use as a substitute for the latest official ECAR process or SDP checklist when those are required but unavailable.
- Do not infer ECD or ECL sign-off from document quality alone.

## Preconditions

- Identify the review mode up front: `ecar` or `precar`.
- Identify the source artifact before judging it: local file, Confluence page, ticket attachment, or pasted content.
- If the latest official SDP checklist is not in hand, fetch it from the canonical internal source or record `official SDP checklist unavailable`.
- If the latest official ECAR process page is not in hand, fetch it from the canonical internal source or record `official ECAR process reference unavailable`.

## Official Source Fidelity

- Use the actual official ECAR process sections, closure rules, and SDP checklist items for the review, not a shortened paraphrase from memory.
- Treat the checked-in source file in this pack as a routing aid, not the final authority, when a newer official source is available.
- If the review uses anything less than the latest official ECAR process or SDP checklist, label the result `degraded review basis`.
- Cite the internal Confluence or documentation source used for the process and checklist whenever the review output format supports citations.

## Source Handling

- Prefer the original design document over summaries or ticket comments.
- If the design doc lives in Confluence and the tool surface allows it, fetch page content and metadata before reviewing derivative notes.
- If the user provides only a Jira key, stop and ask for the linked design artifact unless the Jira issue already contains the full design text.
- If the input omits diagrams or linked artifacts referenced by the design, record `missing referenced artifact` instead of assuming the content exists.
- If a local Confluence-processing workflow or rule exists in the active pack, follow it before reviewing the design source.
- If no such Confluence-processing construct exists, review the fetched source directly and state that the Confluence-processing helper was unavailable.
- If the review target is a Confluence document, prepare a paste-ready review comment when the user wants feedback returned to the document.

## Applicability Screen

- Mark `ECAR required` when the proposal includes customer-facing API or data changes, significant re-architecture, operational dependency changes, cross-team interfaces, CAPA-driven changes, high-risk changes, one-way-door decisions, or multi-region, AD, or FD changes.
- Mark `ECAR likely not required` for internal-only bug fixes, optimizations, purely internal interfaces, or non-impactful configuration changes, unless the official process says otherwise.
- If applicability is unclear, mark `ECD confirmation needed` and err toward review rather than forcing a no.

## Required Coverage

- For `ecar`, assess these sections explicitly: motivation or problem statement with business, customer, and technical motivation; solution proposal with options considered and rationale; architectural overview with diagrams plus logical blocks and data or control flow; detailed component design; risks with short-term, medium-term, and long-term mitigations; sizing, scalability, and operational posture; deployment plan; rollback plan; testing, validation, and observability; dependencies and integration points; security and compliance; change management or phasing; action items or notes; and ECD or ECL sign-off tracking in the ECAR ticket.
- For `precar`, allow incomplete detail, but require intent, open questions, expected risks, and early trade-offs to be explicit.
- Record every required section as one of `present`, `missing`, or `unclear`.
- Convert each `missing` or materially weak section into an action item.

## SDP Evaluation

- Use the latest official System Design Principles checklist, not the abbreviated snapshot in this pack.
- Evaluate every official SDP principle as exactly one of `Relevant`, `Not Relevant`, or `Clarification Needed`.
- Add a justification for every principle, even when marked `Not Relevant`.
- Convert every unmet relevant principle and every unclear principle into an action item.
- If the official checklist cannot be fetched, continue only with explicit notice that SDP coverage is incomplete and the result is not a full ECAR-quality review.

## Feedback Rules

- Use empathy and professional respect in the review language.
- Structure the feedback around the official checklist and required sections rather than free-form architecture debate.
- Keep feedback tied to business impact, operational impact, dependency risk, or review-process requirements.
- Cover both the questions explicitly asked by the team and any material business, OCI, or dependency risks the document does not ask about.
- Prefer concrete findings over generic architecture advice.
- Separate findings into `major action item` and `minor action item`.
- Mark an item `major` when it blocks ECAR closure, hides a material risk, or leaves a required section or principle unresolved.
- Mark an item `minor` when it improves clarity, traceability, or completeness without blocking review closure.
- Do not create rat-hole commentary. If a point does not change risk, readiness, or review closure, leave it out.
- Capture an action item for every major missing section, unresolved risk, SDP gap, or open question that matters to the review outcome.
- Keep notes in a shared and persistent form when the task includes comment or tracker updates; otherwise produce a paste-ready artifact that can be preserved without restructuring.

## Tracking And Closure

- Track every action item in the ECAR ticket when a ticket exists.
- For every action item, include owner, closure condition, and closure rationale, or record `owner needed` and `closure basis needed`.
- When no major action items remain, mark the expected ticket state as `Done`.
- When any major action item remains, mark the expected ticket state as `AI Follow-up`.
- When major action items exist, recommend Jira subtasks or tightly linked tracker entities for each major item.
- Do not claim ECAR closure until all major action items are resolved and both ECD and ECL approval comments are evidenced in the ECAR ticket.
- If review disagreements or process disputes are evidenced, record escalation through the official ECAR path, starting with `ecxr_escalation_us_grp@oracle.com`, then OCI Chief Architect if required by the process.
- If the user wants feedback returned to Confluence and no write-capable Confluence comment tool exists, return a paste-ready comment instead of claiming the comment was posted.
- If the user wants feedback returned to Confluence and `confluence_add_comment` is available, draft the comment first, apply the mutation gate, and post only after explicit approval.

## Readiness Scoring

- Assign readiness only after section mapping, SDP evaluation, and action-item classification are complete.
- Use this rubric exactly:
  - `5 ECAR-Ready`: all required sections and SDP principles addressed, no major action items, sign-off path is clear.
  - `4 Nearly Ready`: only minor issues or clarifications remain.
  - `3 Needs Improvement`: substantial gaps remain, but the document is reviewable and closure work is clear.
  - `2 Incomplete`: major sections or principles are missing, or ownership and closure are unclear.
  - `1 Not ECAR-Ready`: the document is out of scope for ECAR review or requires major rework before review is meaningful.
- For `precar`, scores `2` or `3` may still be acceptable when intent, trade-offs, and open risks are captured clearly.
- Justify the score with explicit findings, not overall sentiment.

## Output Contract

- Produce the review with these headings in this order:
  - `Applicability`
  - `Document Coverage`
  - `SDP Assessment`
  - `Findings`
  - `Action Items`
  - `Sign-off Status`
  - `Ticket Status`
  - `Readiness Score`
- If the user asks for Confluence-ready feedback, append `Confluence Comment Draft` after `Readiness Score`.
- If the user asks for Confluence posting and the comment is posted successfully, append `Confluence Comment Status` after `Confluence Comment Draft`.
- In `Document Coverage`, list each required section with `present`, `missing`, or `unclear`.
- In `SDP Assessment`, include one row or bullet per official principle with status and justification.
- In `Findings`, keep each item traceable to a section, principle, or specific design claim, and cite the relevant internal reference when available.
- In `Action Items`, separate `major` from `minor` and include owner, closure condition, and closure rationale, or `owner needed`.
- In `Sign-off Status`, report the observed ECD or ECL state, any missing approvals, and any escalation evidence, or `not evidenced`.
- In `Ticket Status`, report the observed ticket state and the expected state based on the major-action-item rules.
- In `Readiness Score`, state the numeric score and the rationale in 2 to 4 sentences.
- In `Confluence Comment Draft`, compress the review into a concise, paste-ready comment that preserves readiness, major actions, minor actions, and next-step expectations.
- In `Confluence Comment Status`, report `posted` only when the tool confirms success; otherwise report `not posted`.

## Failure Modes

- If the design source cannot be read, stop and report `design source unavailable`.
- If the official ECAR process cannot be fetched, continue only with explicit notice that closure rules may be incomplete.
- If the official SDP checklist cannot be fetched, continue only with explicit notice that SDP coverage is partial.
- If ownership or ticket linkage is missing, record `tracking gap` instead of inventing owners or workflow state.
- If the review artifact cannot cite the official process or checklist source, record `reference citation missing`.
- If the user asks to post back to Confluence and no write-capable comment tool exists, record `manual Confluence comment posting required`.
- If Confluence comment posting fails, record `manual Confluence comment posting required` and keep the draft in the output.

## Verification

- Confirm every required ECAR or PreCAR section ended in exactly one state: `present`, `missing`, or `unclear`.
- Confirm every official SDP principle ended in exactly one state: `Relevant`, `Not Relevant`, or `Clarification Needed`.
- Confirm every `missing`, `unclear`, or unmet required item produced an action item or an explicit reason why none was needed.
- Confirm every action item includes owner plus closure information, or an explicit tracking gap.
- Confirm the expected ticket status matches the presence or absence of major action items.
- Confirm closure is never claimed without evidenced ECD and ECL sign-off.
- Confirm the final score matches the recorded major and minor action items.
- Confirm any Confluence comment output is either a paste-ready draft or a tool-confirmed posted comment, never an implied posting.
