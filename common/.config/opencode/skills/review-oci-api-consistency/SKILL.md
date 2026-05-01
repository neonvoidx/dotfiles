---
name: review-oci-api-consistency
description: '[Workflow] Review an OCI API spec against OCI API consistency requirements and produce an evidence-based compliance report.'
source_type: workflow
metadata:
    last_updated: 2026-03-17T00:00:00Z
    owner: platform_org
---

# Review OCI API Consistency

## Purpose

To provide an actionable, comprehensive checklist and rule reference based on the [OCI API Consistency Guidelines](https://confluence.oraclecorp.com/confluence/display/DEX/API+Consistency+Guidelines).  
This workflow is intended for use in ECAR/PreCAR reviews and automated/manual assessment of API specifications, Swagger/OpenAPI definitions, and service contract documentation for new or updated OCI APIs.

## How to Use

- For each new or modified API, review all relevant categories in this file.
- For each section, validate that the API adheres (or intentionally/exceptionally deviates with ARB approval).
- Document findings, compliance points, and action items for non-compliance.
- This rule file may be applied as a compliance matrix, or integrated into ECAR/PreCAR review action item tracking.

## Inputs

- Required: API spec path
- Required: review scope (`full`, `delta`, or `ecar`)
- Optional: validator output path
- Optional: changed-files list or diff
- Optional: prior ARB exceptions

## Entry Conditions

- The API spec exists in the workspace.
- The review scope is known before the workflow begins.
- The OCI API Consistency Guidelines are reachable from the canonical reference.
- If the review scope is `delta`, a diff or changed-files list is available.

## Steps

1. Read the API spec, related models, and any checked-in validator output before producing findings.
2. If validator output is missing, record `missing validator evidence` and continue the review without inferring a clean validator run.
3. Evaluate the API against the checklist in `Review Matrix`, preserving each section name in the report.
4. Separate exceptions into `approved` and `approval missing`; do not treat a deviation as acceptable unless ARB approval is documented.
5. Produce a compliance report with sections `passed`, `failed`, `needs-arb-exception`, and `missing-evidence`; cite the affected operation, model, field, or path for every non-pass result.
6. For ECAR or PreCAR reviews, append one concrete action item per failed or unapproved check and identify the exact guideline category that triggered it.

## Verify

- Confirm the report covers every changed operation or explicitly states `full spec reviewed`.
- Confirm every failed item includes a spec location and a guideline category.
- Confirm every exception is labeled `approved` or `approval missing`.
- Confirm the final output is ready to paste into ECAR or PreCAR notes without additional restructuring.

## Done When

- The workflow produces a complete compliance report with evidence, exceptions, and action items.

## Review Matrix

## MASTER CHECKLIST

### 1. Spec & Documentation
- [ ] Spec must be defined in Swagger/OpenAPI 2.x format (2.0 only; not yet OpenAPI 3.x).
- [ ] Validator output and suppression list checked in with code/spec review.
  - [ ] Clean validator run: no errors/warnings, or all have documented/approved suppressions.
- [ ] Uses latest Swagger Spec Validator & Preprocessor, correct validation profile (usually DEFAULT).
- [ ] No unapproved schema suppressions or global suppressions; entity-specific only.
- [ ] API includes issue routing table (`x-obmcs-issue-routing-table`) with owner contacts.

### 2. Naming, Paths & HTTP Fundamentals
- [ ] Resource, operation, parameter, and enum names adhere to required casing (camelCase, PascalCase for models, all-uppercase for enum values).
- [ ] Follows RESTful conventions:
  - [ ] Standard HTTP verbs: POST (Create), GET (Get/List), PUT (Update), DELETE (Delete), PATCH (Patch).
  - [ ] Actions use POST with `/actions/<operationName>` sub-path.
  - [ ] No verb-based paths; path segments only describe resource hierarchy.
- [ ] Path parameters are named with `<resourceType>Id` pattern; query parameters and fields match model property names.
- [ ] No sensitive customer data in URLs or query path parameters.

### 3. Models, Parameters, and Schema Design
- [ ] All first-class resources expose required reserved properties: id, lifecycleState, compartmentId, timeCreated, displayName, definedTags, freeformTags, systemTags, etc.
- [ ] No alias models, nested models, or naked array/map models; use referenced types.
- [ ] Required/optional schema fields strictly managed; no required-to-optional or vice versa without breaking change process.
- [ ] Parameter types limited to: path, query, header, body (not formData).
- [ ] Enums are case-insensitive; new values can be added without breaking clients.
- [ ] Arrays/maps must specify maxItems/maxProperties; unbounded arrays/maps prohibited.
- [ ] Boolean properties/params use positive auxiliary verbs (isEnabled, hasFoo).

### 4. Operation and CRUD Patterns
- [ ] Each resource has: Create (POST), Get (GET), Update (PUT), Delete (DELETE), List (GET), Patch (optional, PATCH).
- [ ] OperationId format: <Verb><ResourceType> or standard variants (see doc).
- [ ] List APIs use "wrapped array"/Collection response model, not naked arrays.
- [ ] List APIs support filtering (by compartmentId, id, lifecycleState, name/displayName) and sorting (sortBy, sortOrder).
- [ ] List/Analytics APIs implement pagination: 'page' param and 'opc-next-page' header.
- [ ] Delete returns 204 (soft-deleted) or 404 (fully deleted), supports idempotent deletes.
- [ ] Cascading/Scheduled deletes & Cloning use correct operation names (Schedule<Resource>Deletion, CascadingDelete<Resource>, CloneCreate<Resource>Details).
- [ ] Subresources modeled as top-level resources unless singleton/justified exception.

### 5. Responses & Errors
- [ ] Success responses map to correct HTTP status codes (200/201/202/204); return correct schemas.
- [ ] All APIs define error responses: 401, 404, 429, 500 (at minimum); descriptions match standard.
- [ ] Error responses provide OCI error code (string), message (do not leak exceptions/stack, always sanitized).
- [ ] Dry-run (opc-dry-run) supported as no-op with proper 204/202 semantics if implemented.
- [ ] All APIs accept and return application/json content, unless otherwise justified/supported in spec.

### 6. Consistency, Versioning & Change Management
- [ ] Consistency: new APIs match service's own precedent if sensible, otherwise use global guidelines.
- [ ] Versioning: all APIs versioned in URL with date-based path (e.g., /20160918/).
- [ ] Breaking changes only via new version and ECAR-accepted process.

### 7. Cross-Cutting Concerns
- [ ] Optimistic concurrency: all mutable resources implement ETag (header), accept If-Match for update/delete.
- [ ] Time/date fields use RFC3339 date-time, named with time<Action> in past tense.
- [ ] Null/empty/undefined handled per guidelines (e.g., "" → null; fields present as null, not omitted).
- [ ] Tags: freeformTags, definedTags, systemTags present per standard spec include.
- [ ] CORS headers present if browser integration required.
- [ ] Localization: Accept-Language/Content-Language respected for errors/content if supported.

### 8. Exception Management
- [ ] Any deviation/exception from guidelines documented, reviewed, and approved by the API Review Board; tracked per ARB process.

### Evaluation Sections & Sub-Checklists

#### Reserved Names and Properties
- [ ] Is each reserved property (id, name, displayName, compartmentId, lifecycleState, etc) present and correct case/type?
- [ ] Is name unique and immutable? Is displayName mutable and optional?
- [ ] Tag fields formatted as object, never null (empty map if not set).
- [ ] If cross-region or multicloud, do region/properties use canonical region IDs, not region key/airport codes?

#### Operation IDs & Grouping
- [ ] Are operationId patterns correct (CreateX, GetX, UpdateX, DeleteX, ListXs, PatchX)?
- [ ] Is CLI/SDK grouping defined via OpenAPI tags (single word, no spaces)?

#### HTTP Verbs, Paths, Status Codes
- [ ] All CRUD actions use correct verb+path mapping?
- [ ] Actions use POST on resource or `/actions/<actionName>` subpaths only.
- [ ] Response codes: 200/201/202 for create, 204 for delete/no-content, 404 for not found, etc.

#### Models and Enums
- [ ] No naked array or map types; are all wrapped (Collection with `items`, Map with parent property)?
- [ ] Enum types can add new values without breaking clients.
- [ ] All `lifecycleState` enums use only allowed values for that resource class.

#### Parameters
- [ ] Use correct location (path, query, header, body).
- [ ] No redundant/conflicting parameter names in path/body.
- [ ] Required/optional/nullable status matches guideline.
- [ ] All List and Analytics APIs require filtering by at least compartment or similar.

#### Responses, Pagination, Filtering, Sorting
- [ ] List returns wrapped array (Collection object).
- [ ] Pagination with `opc-next-page` and `page` param implemented.
- [ ] Filtering by fields like compartmentId, id, lifecycleState, name/displayName, AD if applicable.
- [ ] Sorting supported with `sortBy` and `sortOrder`, default by timeCreated desc.

#### Errors
- [ ] All operations declare standard error responses.
- [ ] Error responses have sanitized message, never stack trace.
- [ ] Accepts/handles unknown parameters with `400-InvalidParameter`.
- [ ] Returns all required error codes per standard.

#### Consistency, Breaking Changes
- [ ] New/changed APIs evaluated for backward compatibility: no silent breaking changes.
- [ ] No required/optional or type changes to fields except via versioning.

#### Advanced Features
- [ ] Optimistic concurrency: If-Match / ETag for updates/deletes.
- [ ] Supports dry-run (`opc-dry-run`) for creates/updates if advertised.
- [ ] All resource create operations support retry tokens (`opc-retry-token`).
- [ ] Resources can be moved between compartments; compartmentId used everywhere.
- [ ] Resource names allow dashes, must pass regex for identifiers if used.

#### Validation/Automation
- [ ] Spec validated with current validator tool, profile DEFAULT.
- [ ] Spell check enabled, with reviewed suppressions.
- [ ] No deprecated/deleted fields or schema structures.

#### ECAR/Checklist Integration
- [ ] For ECAR/PreCAR, explicitly reference this workflow in architectural/tech review as bar for public API design.
- [ ] Use section mapping/action items for any non-conformance.

## Exception Handling

If any guideline cannot be met:
- Document precise section, reason, proposed alternative.
- Seek API Review Board approval. Track all exceptions in [API guideline exceptions list](https://confluence.oraclecorp.com/confluence/display/DEX/Exceptions+for+API+Consistency+Guidelines).
- No exceptions should be implemented in production w/o explicit ARB sign-off.

## References

- [Full API Consistency Guidelines](https://confluence.oraclecorp.com/confluence/display/DEX/API+Consistency+Guidelines)
- [Swagger Spec Validator Tool](https://confluence.oraclecorp.com/confluence/display/DEX/Swagger+Spec+Validation+Tool)
- [Error Codes List](https://confluence.oraclecorp.com/confluence/display/DEX/Error+Codes)
- [API Review Board Slack](https://oracle.enterprise.slack.com/archives/C7KRG5W6R)
- [API Review Board Process](https://confluence.oraclecorp.com/confluence/display/DEX/API+Review+Board+Weekly+Sync+Agenda)
