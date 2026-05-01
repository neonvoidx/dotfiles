---
name: provenance-investigation
description: Use when encountering files, configs, git state, or artifacts that differ from expectations — especially unexpected changes between sessions
metadata:
  owner: shrug-labs
  last_updated: 2026-03-09
---

# Provenance Investigation

Systematic method for tracing the origin of unexpected state changes.

## Iron Law

```
REPORT WHAT YOU OBSERVE BEFORE INTERPRETING IT.
```

State your observation ("file X has content I didn't write") separately from
your interpretation. Investigation comes before explanation.

## Investigation Sequence

1. **Observe** — State exactly what's unexpected and where
2. **Timestamp** — When was it last modified?
   - macOS: `stat -f '%Sm' <path>`
   - Linux: `stat -c '%y' <path>`
3. **Attribution** — Who or what changed it?
   - `git log --oneline --all -- <path>` (commit history for this file)
   - `git blame <path>` (line-level attribution)
   - Branch name or worktree may indicate the source session
4. **Scope** — Is this one file or a pattern?
   - `git diff --stat HEAD~5` (recent change spread)
   - `git log --oneline -10 --all --since='3 days ago'` (recent activity across branches)
5. **Context** — Check for related signals:
   - Work-tracking artifacts — active plans or drafts from another session?
   - Memory files — updated by another session?
   - New branches or worktrees — parallel work? (`git worktree list`, `git branch -a --sort=-committerdate | head -10`)
   - Pack content changes — synced or edited elsewhere?
6. **Synthesize** — Present findings: what changed, approximately when, likely source
7. **Ask if stuck** — If provenance is still unclear after steps 1-5, ask the user. Don't guess.

## Rationalization Table

| You're Thinking... | Reality |
|---------------------|---------|
| "Let me re-read it, maybe I missed something" | You read it correctly. Something else changed it. Check timestamps and git log. |
| "This looks like a bug in the file" | It looks like work from another session or harness. Investigate before "fixing." |
| "The tool must have failed" | The tool worked. The world moved while you weren't looking. |

## Degrees of Freedom

| Situation | Depth | Approach |
|-----------|-------|----------|
| One file differs from expectations | Steps 1-3 | Timestamp + git log, done |
| Multiple files differ | Full sequence | Look for patterns in timing and authorship |
| Git state is unexpected (branches, staged changes) | Steps 1-4 | Check for parallel branches and worktrees |
| Everything looks different | Stop | Ask the user — major context shift likely |
| Memory or config updated | Steps 1-2 | Timestamps usually sufficient, these change between sessions |
