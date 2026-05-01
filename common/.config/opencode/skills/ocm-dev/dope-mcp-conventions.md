# DOPE MCP Conventions

## Start broad, narrow incrementally

DOPE alarm and metric queries with narrow filters (specific project + fleet + region) can return empty results even during active incidents. The data model has multiple granularity levels, and premature filtering skips the level where data exists.

### Query strategy

1. **Broad first:** Query alarm status at compartment or project level without fleet/region filters.
2. **Cross-reference:** Use Confluence runbooks and `team-reference-tables.md` Grafana panel mappings to identify the correct service → panel → tenancy path.
3. **Narrow last:** Apply project + fleet + region filters only after confirming data exists at a broader scope.

### When broad queries return empty

If compartment-level queries also return empty, pivot to:
- Jira-SD OTS tickets (alarm query text and transition timestamps provide indirect 5xx evidence)
- Confluence runbooks for the service (e.g., "Inventory Service Killers")
- Grafana dashboard mappings from `team-reference-tables.md`

## Logging namespace lookup

Service tenancy names for logging may differ from other tooling aliases. When `tenant_name` returns empty, try alternate names from `team-reference-tables.md` or broaden the namespace search.

## Auth: OP_TOKEN expiry

DOPE MCP requires a valid `OP_TOKEN`. "Could not get operator token" (Error Code: -1) means the token expired. This requires operator intervention (YubiKey). See `access-warmups-detail.md` for the refresh procedure.
