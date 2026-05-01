# Curation Procedures

How to add, review, and remove pack content.

## Adding content

Before adding a new resource:

1. Check whether an existing resource already covers the use case -- extend rather than duplicate.
2. Use the templates and frontmatter conventions in `../authoring-standard.md`.
3. Test the resource in context: run the pack's validation targets and at least one realistic scenario.
4. Decide whether it belongs in the default profile or only in a maintainer/opt-in profile. When in doubt, leave it out of the default.
5. If the pack uses a tier registry, the new resource starts at Tier B (Pilot) until it has evidence.

## Reviewing content

When reviewing existing resources:

- Does this resource get used? If nobody has run it in a month, remove it.
- Is the content still accurate? Outdated procedures are worse than no procedure.
- Is the scope right? Resources that try to cover too much should be split. Resources with heavy overlap should be merged.
- Does it pass the pack's validation targets?
- Apply the quality dimensions from `quality-dimensions.md`.

## Removing content

1. Remove the file from the pack directory.
2. Remove references from any profile that included it.
3. Update cross-references in other resources.
4. Verify the pack still validates cleanly.

## References

- Authoring standard: `../authoring-standard.md`
- Quality dimensions: `quality-dimensions.md`
- Construct guide: `construct-guide.md`
