---
name: permissions-yaml-generator
description: Generate authz resourceOperations YAML for OCI services from SPLAT spec permissions and permissions documentation. Use when creating or updating ID-*.yaml permission files and resource families.
---

# Permissions YAML Generator

Use this skill to generate an `ID-*.yaml` permissions file in the [authz format](https://confluence.oraclecorp.com/confluence/display/IDOCI/Permissions+and+Attributes+for+Services).

## Required Questions Before Any Generation

Ask these first and wait for answers:

1. `What is the Identity AuthZ Enablement ticket ID?`  
   Example: `ID-54712` (this must be used as the output file name: `ID-54712.yaml`)
2. `What is the full path to the API spec location?`  
   Example: `/Users/<user>/Repos/<service>/<spec-root>/src/specs/`
3. `What is the permissions confluence page URL?`  
   Example: `https://confluence.oraclecorp.com/confluence/display/IDOCI/Permissions+of+Splat`
4. `Do you want to add resource spelling aliases to support both singular and plural policy terms?`  
   Example answers: `yes` or `no`

Do not generate YAML until all answers are provided.
Ask these questions one at a time in sequence. Do not ask the next question until the user answers the current one.

If the confluence page cannot be accessed, ask the user to provide either:
- A local `.md` file path containing the page content, or
- The page content pasted directly in markdown.

## Workflow

1. Inspect existing YAML examples in the target repo (for format and conventions).
2. Parse spec files under the provided spec path and extract permission tokens from SPLAT `permissions` arrays.
3. Read permissions guidance from the confluence page (or provided markdown fallback).
4. Output a mapping table before generating YAML. The table must include:
    - `permission`
    - `resourceName`
    - `metaverb`
    - `source` (`spec` or `confluence`)
5. Ask the user to confirm the mapping table before proceeding.
6. If the user provides corrections, apply them and output a revised mapping table.
7. Repeat until the user explicitly confirms the mapping table is correct.
8. If any permission does not match mapping rules or lacks clear mapping, stop and ask the user for the metaverb for those permissions.
9. Build resource blocks in this structure:
    - `resourceName`
    - `operationList`
    - `ADD_RESOURCE` (`serviceName`, `owner`)
    - `ADD_PERMISSION` (`permissionMap`)
10. Build family block only if the confluence content explicitly defines a family for this service/resource set.
- Use the family name from confluence (do not infer).
- Add `ADD_RESOURCE_FAMILY` with the appropriate `sourceResources`.
- If confluence does not define a family, do not add a family block.
11. If the user wants plural aliases, add:
- `ADD_SPELLING`
- `parameters.altSpellings` (plural forms)
12. Write output file using ticket-based naming: `<ticket-id>.yaml`.

## Mapping Rules

- Infer base CRUD permissions by suffix:
    - `_INSPECT` -> `INSPECT`
    - `_READ` -> `READ`
    - `_USE` -> `USE`
    - `_UPDATE` -> `MANAGE`
    - `_CREATE`, `_DELETE`, `_MOVE` -> `MANAGE`
- If spec and confluence disagree, follow confluence and call out the override explicitly.

## Output Contract

Produce:

1. Mapping table (`permission`, `resourceName`, `metaverb`, `source`) shown before YAML generation.
2. User-confirmed mapping table before YAML generation (iterate until confirmed).
3. Generated YAML file named from the ticket ID (`<ticket-id>.yaml`).
4. Short summary of:
    - Permissions found only in spec
    - Permissions found only in confluence
    - Any assumptions made (serviceName, owner, family name, plural spellings)
