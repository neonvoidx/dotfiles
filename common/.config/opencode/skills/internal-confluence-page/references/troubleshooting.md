# Troubleshooting

## Missing Chromium

If Playwright says the Chromium executable does not exist, install it with:

```bash
uv run --with playwright playwright install chromium
```

## Missing Python Packages

If imports fail, run the extractor through `uv run` and include the required packages:

```bash
uv run --with playwright --with markdownify --with beautifulsoup4 \
  python3 ~/.codex/skills/internal-confluence-page/scripts/extract_page.py "<URL>"
```

## Repeated Login Prompts

- Use `--refresh-cookies` to force a clean login.
- Confirm the page fully loads before closing the browser window.
- Check whether the target page needs a different Oracle SSO context or VPN posture.
- If the page is a Confluence short link like `/confluence/x/...`, let the browser finish redirecting to the final page before assuming auth failed.

## No Markdown File Produced

- Verify that the extractor printed `Rendered Markdown saved to ...`.
- Check the chosen `--output` path or the default `output/` directory in the current working directory.
- If the user just finished login, poll the running command once more before assuming it failed.
- If Playwright reports a navigation interruption to `about:blank`, retry with refreshed cookies; that usually means SSO redirects raced the initial page load.

## Extracted Content Looks Like A Login Page

- Delete or refresh the cookies file and retry.
- Re-run the extractor and wait for the real page body to appear before the browser closes.
- Confirm the Confluence page itself is accessible to the authenticated user.
