# Review Guide

Systematic review criteria for evaluating pack content at three levels. Used by the pack-review workflow.

## Level 1: Ecosystem Fit

How does this pack layer with others? Review with all loaded packs visible.

**Overlap check:**
- Are any rules addressing the same behavior as rules in another pack? If yes, one should be deleted.
- Do any skills have overlapping trigger conditions in their descriptions? If yes, one will shadow the other unpredictably.
- Do workflows duplicate steps that another pack's workflow already handles?

**Layering check:**
- Does this pack assume content from another pack is loaded? If yes, that dependency must be documented.
- Does this pack conflict with another pack's rules? (e.g., one says "always X", another says "never X")
- Is the pack's scope clearly distinct from other packs? State the one-sentence scope and verify no other pack claims the same scope.

**Token budget across ecosystem:**
- Sum all always-on rules across all loaded packs. Total should be <20K tokens.
- If over budget: which rules fail the removal test? Cut those first.
- Skills and workflows are cheap (description-only until triggered) — no cross-pack budget concern.

---

## Level 2: Internal Coherence

Does the content within this pack work as a unit?

**Completeness check:**
- Does every workflow reference skills that exist (in this pack or a declared dependency)?
- Does every rule have at least one scenario where it triggers? If not, it's dead weight.
- Are there gaps — behaviors the pack's scope should cover but doesn't?

**Contradiction check:**
- Do any rules contradict each other? Read all rules sequentially and flag conflicts.
- Do any skills give guidance that contradicts a rule? Rules win — fix the skill.

**Profile check (if pack uses profiles):**
- Is every piece of content included in at least one profile? Orphaned content is invisible.
- Do profiles load contradictory content?
- Is the default profile the minimal useful set?

**Token balance:**
- Count of rules vs skills: if most content is in rules, the pack is token-expensive. Challenge each rule — should it be a skill instead?
- Rule line counts: any rule over 60 lines should be split (rule seed + skill detail).

---

## Level 3: Content Quality

Apply to each individual piece of content.

### Three Behavioral Tests (from SKILL.md)

For every rule, skill, workflow, and agent:

1. **Removal Test:** If this piece were removed, would agent behavior change on a realistic task?
   - If uncertain: actually remove it, run a task, observe. Don't guess.
2. **Specificity Test:** Does every directive contain a concrete action?
   - Scan for: "consider", "be careful", "or equivalent", "as appropriate", "ensure"
   - Each one is a flag. Replace with decision tree or exact instruction.
3. **Rationalization Test:** What excuses would the agent use to skip this?
   - If the content is discipline-enforcing: does it have rationalization tables, red flags, iron laws?
   - If not: it will be rationalized away under pressure.

### Per-Construct Checks

**Rules:**
- [ ] Under 60 lines?
- [ ] Imperative voice, trigger-action pairs?
- [ ] No model defaults restated? ("be concise", "don't hallucinate")
- [ ] No hedging language? ("consider", "you might want to")
- [ ] Do/Don't structure with at least one example?

**Skills:**
- [ ] Description starts with "Use when..." and describes triggering conditions only?
- [ ] Description does NOT summarize the skill's workflow? (CSO violation)
- [ ] SKILL.md body under 500 lines?
- [ ] Heavy reference in separate files, not inline?
- [ ] Clear "when to use / when not to use"?

**Workflows:**
- [ ] Every step: one action, one specific tool/command?
- [ ] No "or equivalent" / "or appropriate" hedging?
- [ ] Mutation gates before state changes?
- [ ] Decision trees for ambiguous steps?
- [ ] Verification steps with concrete pass criteria (not "ensure success")?

**Agents:**
- [ ] Explicit tool allowlist?
- [ ] Least privilege — only tools this agent needs?
- [ ] Clear scope boundary — what it does AND what it doesn't?

### Review Output Format

For each finding, state:
1. **Level** (ecosystem / coherence / content)
2. **Piece** (which file)
3. **Finding** (what's wrong, with evidence)
4. **Severity** (must-fix: behavioral impact / should-fix: quality / nit: style)
5. **Recommendation** (specific fix, not "improve this")
