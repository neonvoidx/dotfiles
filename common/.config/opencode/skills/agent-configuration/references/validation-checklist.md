# Harness validation checklist

Run after any change to rules/skills/MCP/tools:

1) Harness loads the intended rules/instructions.
2) Skills are discoverable (index present; skill loads successfully).
3) MCP servers are registered and visible in the client.
4) Tool surface is least-privilege:
   - global deny still in place
   - ops agents own enterprise tools
   - write tools only enabled intentionally
5) Reconcile local allowlists vs upstream tool inventories — remove dead tools.
6) Record deltas as links + TODOs (don’t speculate).
