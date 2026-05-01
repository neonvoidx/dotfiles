# Behavioral Patterns

Techniques for writing pack content that resists agent rationalization and actually changes behavior. Each pattern is proven through testing — observed to make a measurable difference in agent compliance.

## Iron Laws

A single non-negotiable principle stated as an absolute constraint.

**When to use:** Discipline-enforcing content where the agent MUST NOT deviate.

**How to write:**
- State in CAPITALS: `NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST`
- Follow with explicit "No exceptions" list that closes every loophole
- Close specific workarounds — don't just state the rule, forbid the shortcuts

**Example:**
```markdown
## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

**No exceptions:**
- Not for "obvious" fixes
- Not for "I can see the problem"
- Not for "quick workaround while we investigate"
- If you haven't traced the root cause, you haven't earned the fix
```

**Why it works:** Agents rationalize under pressure. A clearly stated absolute with explicit loophole closers is harder to rationalize around than nuanced guidance.

---

## Rationalization Tables

Structured tables that anticipate and counter the excuses agents will generate.

**When to use:** Any content where the agent might find reasons to skip steps.

**How to build:**
1. Run RED phase of TDD loop — capture agent's exact rationalizations
2. One row per rationalization observed
3. "Reality" column must be specific and concrete, not just "do it anyway"
4. Add new rows as new rationalizations are discovered

**Structure:**
```markdown
| Excuse | Reality |
|--------|---------|
| "[exact words agent used]" | [specific, concrete counter] |
```

**Example (from test-driven-development skill):**
```markdown
| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing about design. |
| "This is different because..." | All of these mean: Delete code. Start over with TDD. |
```

**Why it works:** When the agent starts rationalizing, seeing its own excuse pre-listed creates a strong signal to comply. The "Reality" column provides the alternative reasoning path.

---

## Red Flags Lists

Self-check triggers that help the agent recognize when it's about to violate a discipline.

**When to use:** Discipline skills where the agent needs to catch itself mid-rationalization.

**How to write:**
- List the thoughts/behaviors that signal a violation is imminent
- End with a single clear action ("All of these mean: [do X]")
- Written as "If you're thinking..." or the thought in quotes

**Example:**
```markdown
## Red Flags — STOP and Reconsider

- "This is too simple to need [the process]"
- "I already know the answer"
- "I'll come back and do it properly later"
- "The user seems to want it fast"
- "This is different because..."

**All of these mean: Follow the process. No shortcuts.**
```

**Why it works:** Self-monitoring is easier than self-control. Recognizing the thought pattern is the first step to catching it.

---

## Degrees of Freedom

Match the specificity of your content to the fragility of the operation.

**Three levels:**

| Level | When | Content Style |
|-------|------|---------------|
| **High freedom** | Multiple valid approaches, context-dependent | Text instructions, general guidance |
| **Medium freedom** | Preferred pattern exists, some variation OK | Templates with parameters, pseudocode |
| **Low freedom** | Fragile operations, consistency critical | Exact scripts, no variation allowed |

**Rule of thumb:**
- Database migrations = low freedom (exact commands, exact sequence)
- Code review = high freedom (judgment calls, context-dependent)
- Deployment workflow = medium freedom (steps defined, parameters vary)

**Example in practice:**
```markdown
# LOW freedom — exact command, no variation
Run: `kubectl rollout restart deployment/api -n production`
Wait for: `kubectl rollout status deployment/api -n production` exits 0

# HIGH freedom — guidance, agent uses judgment
Review the PR for security concerns. Focus on input validation,
authentication checks, and data exposure in API responses.
```

---

## Graphviz Decision Trees

Visual flow for non-obvious decisions. Forces the agent through a specific reasoning path.

**When to use:**
- Non-obvious decision points where the agent might choose wrong
- Process loops where the agent might stop too early
- "When to use A vs B" decisions

**When NOT to use:**
- Linear instructions → numbered list
- Reference material → table
- Code examples → code block

**Conventions:**
- Diamond shapes for decisions
- Box shapes for actions
- Double circles for terminal states
- Edge labels for yes/no branches
- Semantic labels (not "step1", "step2")

---

## Spirit vs. Letter Blocker

A meta-pattern that cuts off entire classes of rationalization.

**When to use:** Any discipline-enforcing content.

**How to apply:** Add this statement early in the content:

```markdown
**Violating the letter of the rules IS violating the spirit of the rules.**
```

**Why it works:** Agents frequently argue they're "following the spirit" while technically violating the process. This pre-empts that entire argument class.

---

## RED Phase Artifacts as Anti-Pattern Examples

Use the actual output from TDD RED phase testing as the "bad example" in the skill itself.

**When to use:** Any skill that has a Good vs. Bad comparison section.

**How to apply:**
1. Run the RED phase (agent without the skill)
2. Capture the agent's actual output (or a representative excerpt)
3. Use it as the anti-pattern example in the skill, alongside the corrected version

**Why it works:** Examples grounded in observed agent behavior are more specific and realistic than hypothetical anti-patterns. The agent recognizes its own failure patterns more readily than contrived ones. Also prevents the author from inventing anti-patterns that don't actually occur.
