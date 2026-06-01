# Canary Investigation Guidance

Use this file when the ticket is canary-backed and the team config includes `team.canary`.

## Canary flow

- Start from the fired metric, not from a guessed canary name.
- Treat the ticket's fired metric as the authoritative clue for which canary actually failed.
- Use the configured `role = "canary"` metric fleet to confirm which failure series fired.
- Use `service_project`, `phonebook`, incident region, and time window to resolve the real runtime canary.
- Fetch the raw canary run logs before broader Lumberjack searching.
- Extract request ids, workflow ids, endpoint names, downstream status codes, and explicit exception text from the raw canary log first.

Preferred canary-backed investigation order:
1. ticket
2. canary logs
3. splat logs
4. downstream application logs
5. metrics
6. releases
7. code

If the fired metric does not map cleanly to a canary name, keep that as an open issue and state which candidate canaries were considered.

## Relationship to other references

- Use `metrics.md` first if you still need to confirm which alarm series actually fired.
- Use `logging.md` after canary log review when you need broader downstream service evidence.
- Use `writeback.md` before posting any ticket comment.
