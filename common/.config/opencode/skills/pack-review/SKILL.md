---
name: pack-review
description: '[Workflow] Systematic review of a pack at three levels — ecosystem fit, internal coherence, and content quality'
source_type: workflow
metadata:
    last_updated: 2026-04-01T00:00:00Z
    owner: shrug-labs
---

# Pack Review

## Inputs

- Required: pack path or name (e.g., `my-pack`, or full path)
- Optional: specific level to focus on (ecosystem, coherence, content)

## Steps

1. **Validate structure**

   Run `aipack pack validate <pack-root>`. This checks manifest structure, file references, and secret patterns. If validation fails, fix structural issues before proceeding — content review on a broken pack wastes effort.

2. **Audit metrics**

   Run `scripts/pack-audit.sh <pack-root>` (in the pack-content-craft skill directory). Review the output for:
   - Budget violations (OVER) — rules >60 lines, SKILL.md >500 lines
   - Missing frontmatter fields (MISS/NONE)
   - CSO trigger failures on skill descriptions
   Note findings. These are mechanical checks — the semantic review comes in later steps.

3. **Identify ecosystem**

   List all other packs at `~/.config/aipack/packs/`. Note which are currently synced to the active harness. Read each pack's `pack.json` to understand scope overlap.

4. **Level 1: Ecosystem fit**

   Use pack-content-craft skill, specifically references/review-guide.md Level 1 criteria.
   - Check for rule overlap across packs
   - Check for skill description overlap (ambiguous triggers)
   - Calculate total always-on token budget across all loaded packs
   - Flag dependencies and conflicts

   Report findings before proceeding.

5. **Level 2: Internal coherence**

   Read ALL content files in the pack. Use references/review-guide.md Level 2 criteria.
   - Check cross-references (do workflows reference existing skills?)
   - Check for contradictions between rules and skills
   - Check profile coverage (if profiles exist)
   - Assess token balance (rules vs skills ratio)

   Report findings before proceeding.

6. **Level 3: Content quality**

   For each piece of content, apply references/review-guide.md Level 3 criteria:
   - Three behavioral tests (removal, specificity, rationalization)
   - Per-construct checklist
   - Semantic assessment: vague guidance, hedging language, missing decision trees

   Report findings per file.

7. **Produce review summary**

   Consolidate all findings:
   - Grouped by severity (must-fix, should-fix, nit)
   - Each finding: level, file, evidence, specific recommendation

   Present summary for discussion.

## Verify

- `aipack pack validate` passed (or failures are documented as findings)
- Every content file in the pack was read and evaluated
- Findings include specific evidence (quoted text, line numbers)
- Recommendations are actionable (not "improve this")

## Notes

- This workflow invokes the pack-content-craft skill. If that skill is not available, the review cannot proceed — the criteria live there.
- Perform the full review inline. Read files directly — do not delegate review steps to background agents.
- Default scope is the entire pack across all levels. If the user requests a narrower scope (e.g., "just the changed files" or "Level 3 only"), use git history to identify the delta. But don't self-narrow — a full review catches drift and decay that incremental reviews miss.
- Do NOT fix issues during review. Report them. Fixes are a separate task.
