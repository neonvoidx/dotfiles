---
name: internal-confluence-page
description: Extract, authenticate, and summarize internal Confluence pages by rendering the visible page content to Markdown first and then working from the saved file. Use when a user shares an internal Confluence URL and asks for a summary, technical review, or other text analysis that requires SSO, cookie refresh, or reproducible output files.
---

# Internal Confluence Page

Use this skill when the task starts from an internal Confluence URL instead of pasted page text.

## Workflow

1. Extract the page to Markdown before doing any analysis.
2. If Playwright is not installed or Chromium is missing, install the browser runtime first.
3. If the browser-backed extractor fails because of sandbox or profile access restrictions, rerun only that browser command with per-command elevated permissions instead of asking for full-access sandbox for the whole session.
4. Prefer temporary browser profiles, cookie jars, and output paths in writable locations when possible.
5. If the extractor opens a browser for authentication, pause and ask the user to complete login and MFA, then continue once the page finishes loading.
6. Save the extracted Markdown in `output/` with a traceable filename.
7. Perform the requested work on the saved Markdown file, not on raw HTML.
8. Save each processed result next to the source Markdown with operation metadata.

## Extract The Page

Run the bundled extractor with managed dependencies:

```bash
uv run --with playwright --with markdownify --with beautifulsoup4 \
  python3 ~/.codex/skills/internal-confluence-page/scripts/extract_page.py \
  "<CONFLUENCE_URL>"
```

The script:

- Uses a persistent cookie jar at `~/.codex/internal-confluence-cookies.json` by default.
- Reuses existing cookies when possible.
- Opens a visible browser window when cookies are missing or expired.
- Saves Markdown to `output/<slug>_<timestamp>.md` unless `--output` is supplied.
- Prefers a slug derived from the page title and falls back to the page ID or URL path.

Use `--output` when the user or repo has a required naming convention.

If a browser launch needs extra host access, prefer a single scoped elevated retry for that command. Do not switch the entire session to full-access mode just to open the authentication browser.

## Summarize Or Review

After extraction, read the saved Markdown file and do the requested task from that file only.

Save outputs in `output/` with names like:

- `<source_stem>_summary_<timestamp>.md`
- `<source_stem>_tech_review_<timestamp>.md`
- `<source_stem>_keywords_<timestamp>.md`

Include:

- Source URL
- Source Markdown path
- Operation name
- Generated timestamp

Retain the original extracted Markdown alongside all derived outputs.

## Interaction Pattern

- If authentication is required, tell the user that a browser window was opened and that you are waiting for them to finish login and MFA.
- After they confirm login, check whether the extractor wrote the Markdown file before proceeding.
- If the task is only a quick summary, return the key points in chat and still keep the saved source file for traceability.

## Troubleshooting

Read [references/troubleshooting.md](references/troubleshooting.md) when:

- Playwright reports that Chromium is missing.
- The extractor keeps returning a login page or empty content.
- Cookies appear stale or malformed.
- The user completed login but no output file was produced.
- The browser process cannot start in the default sandbox; retry with scoped command-level escalation before requesting broader access.
