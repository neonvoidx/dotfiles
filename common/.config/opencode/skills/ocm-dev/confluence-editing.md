# Confluence Page Editing

## Two Formats — Use the Right One

| Format | When to use | Preserves |
|--------|------------|-----------|
| **Markdown** | Pages with only text, tables, links | Everything — no Confluence-specific features |
| **Storage (XHTML)** | Pages with user links, macros, dates, or Confluence features | User mentions (`<ac:link><ri:user>`), macros, all formatting |

If the page has user mentions or macros and you edit in markdown, those features will be destroyed.

## Storage Format Workflow

Scripts live in `.scratch/confluence/` in your working directory. Create `confluence-fmt.sh` and `confluence-compact.sh` there if they do not exist (see the ocm-ops-tools repo for examples).

### Download and format for editing

```bash
# Download from Confluence in storage format
mcp__atlassian__confluence_download_page_to_file \
  page_id=<id> \
  file_path=.scratch/confluence/<name>.xhtml \
  content_format=storage

# Format for readability (newlines after block elements)
./.scratch/confluence/confluence-fmt.sh .scratch/confluence/<name>.xhtml
```

### Edit locally, then publish

```bash
# Compact back to single-line before upload
./.scratch/confluence/confluence-compact.sh .scratch/confluence/<name>.xhtml

# MUTATION: Publish with storage format — confirm before executing
mcp__atlassian__confluence_publish_page_from_file \
  page_id=<id> \
  file_path=.scratch/confluence/<name>.xhtml \
  content_format=storage \
  expected_version=<current_version>

# Re-format for continued local editing
./.scratch/confluence/confluence-fmt.sh .scratch/confluence/<name>.xhtml
```

### Round-trip verification

Format → compact → diff against original download = identical. This proves the format/compact cycle is lossless.

## Markdown Workflow

Simpler — no format/compact needed:

```bash
# Download
mcp__atlassian__confluence_download_page_to_file \
  page_id=<id> \
  file_path=.scratch/confluence/<name>.md \
  content_format=markdown

# MUTATION: Publish — confirm before executing
mcp__atlassian__confluence_publish_page_from_file \
  page_id=<id> \
  file_path=.scratch/confluence/<name>.md \
  content_format=markdown \
  expected_version=<current_version>
```

## Decision Tree

1. Does the page have user mentions, macros, or dates? → Storage format
2. Is this a new page with only text/tables/links? → Markdown
3. Unsure? → Download in storage format, inspect for `<ac:` tags
   - `<ac:` tags present → Storage
   - No `<ac:` tags → Markdown is safe
