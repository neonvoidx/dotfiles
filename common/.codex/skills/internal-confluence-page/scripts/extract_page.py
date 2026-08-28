#!/usr/bin/env python3
import argparse
import json
import os
import re
import tempfile
import time
from datetime import datetime
from urllib.parse import parse_qs, urlparse

from bs4 import BeautifulSoup
from markdownify import markdownify as md
from playwright.sync_api import Error as PlaywrightError
from playwright.sync_api import sync_playwright


DEFAULT_COOKIES_FILE = os.path.expanduser("~/.codex/internal-confluence-cookies.json")
CONTENT_SELECTORS = [
    "div.wiki-content",
    "div#content",
    "div#content-body",
    'div[data-test-id="page.content"]',
    "article",
]


def load_cookies(cookie_file):
    if not os.path.exists(cookie_file):
        return None
    try:
        with open(cookie_file, "r", encoding="utf-8") as handle:
            return json.load(handle)
    except (json.JSONDecodeError, OSError) as exc:
        print(f"Cookie file {cookie_file} is unreadable or malformed: {exc}. Re-authenticating.")
        return None


def save_cookies(page, filename):
    os.makedirs(os.path.dirname(filename) or ".", exist_ok=True)
    cookies = page.context.cookies()
    fd, temp_path = tempfile.mkstemp(dir=os.path.dirname(filename) or ".", prefix=".cookies.", text=True)
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(cookies, handle, indent=2)
        os.replace(temp_path, filename)
    except Exception:
        try:
            os.unlink(temp_path)
        except OSError:
            pass
        raise
    print(f"Saved {len(cookies)} cookies to {filename}")


def is_auth_url(url):
    parsed = urlparse(url or "")
    path = parsed.path.lower()
    query = parsed.query.lower()
    return any(
        signal in path or signal in query
        for signal in [
            "/login.action",
            "/plugins/servlet/samlsso",
            "permissionviolation=true",
            "os_destination=",
        ]
    )


def need_refresh(html, current_url=""):
    soup = BeautifulSoup(html, "html.parser")
    title = (soup.title.string or "").lower() if soup.title else ""
    text = soup.get_text(" ", strip=True).lower()
    login_form = bool(
        soup.find("input", {"type": "password"})
        or soup.find("form", action=re.compile(r"login|saml|auth", re.IGNORECASE))
    )
    signals = [
        "please log in",
        "please sign in",
        "sign in to continue",
        "enter your username",
        "enter your password",
        "session expired",
        "your session has expired",
    ]
    if is_auth_url(current_url):
        return True
    if login_form:
        return True
    if "login" in title or "403" in title or "401" in title:
        return True
    return any(signal in text for signal in signals)


def slugify(value):
    slug = re.sub(r"\s+", "_", value.strip())
    slug = re.sub(r"[^A-Za-z0-9._-]", "", slug)
    slug = re.sub(r"_+", "_", slug).strip("._-")
    return slug or "confluence_page"


def clean_title(title):
    title = title or ""
    title = re.sub(r"\s*[-|]\s*Confluence.*$", "", title, flags=re.IGNORECASE)
    return title.strip()


def url_fallback_slug(url):
    parsed = urlparse(url)
    page_id = parse_qs(parsed.query).get("pageId")
    if page_id and page_id[0]:
        return f"confluence_{page_id[0]}"
    path_parts = [part for part in parsed.path.split("/") if part]
    if path_parts:
        return slugify(path_parts[-1])
    return "confluence_page"


def extract_visible_markdown(html):
    soup = BeautifulSoup(html, "html.parser")
    for tag in soup(["script", "style"]):
        tag.decompose()
    return md(str(soup), heading_style="ATX").strip()


def navigate_with_redirect_resilience(page, url, timeout_ms):
    try:
        page.goto(url, wait_until="domcontentloaded", timeout=timeout_ms)
    except PlaywrightError as exc:
        if "interrupted by another navigation" not in str(exc):
            raise
        page.wait_for_timeout(1500)


def wait_for_confluence_content(page, timeout_ms=120000):
    deadline = time.time() + (timeout_ms / 1000)
    try:
        page.wait_for_function('document.readyState === "complete"', timeout=min(timeout_ms, 30000))
    except PlaywrightError:
        pass

    while time.time() < deadline:
        if not is_auth_url(page.url):
            for selector in CONTENT_SELECTORS:
                try:
                    if page.locator(selector).first.is_visible():
                        return True
                except PlaywrightError:
                    pass
        page.wait_for_timeout(1000)

    return False


def capture_page_state(page):
    try:
        html = page.content()
    except PlaywrightError:
        html = ""
    try:
        title = clean_title(page.title())
    except PlaywrightError:
        title = ""
    return html, title, page.url


def interactive_login_and_save_cookies(url, cookies_file, timeout_ms=600000):
    print("\nCookies missing or expired. Launching browser to refresh authentication...")
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=False)
        context = browser.new_context()
        page = context.new_page()
        print(f"\nOpening {url} for interactive login (complete any MFA).")
        navigate_with_redirect_resilience(page, url, timeout_ms)
        print("\nWaiting for Confluence SSO and full page load. Do not close the browser.")
        if not wait_for_confluence_content(page, timeout_ms=timeout_ms):
            print("Timed out waiting for Confluence to fully load. Saving auth state anyway.")
        save_cookies(page, cookies_file)
        html, title, final_url = capture_page_state(page)
        page.wait_for_timeout(2000)
        browser.close()
    return html, title, final_url


def fetch_page_html(page, selectors):
    for selector in selectors:
        try:
            element = page.query_selector(selector)
            if element:
                try:
                    return element.inner_html()
                except PlaywrightError:
                    return page.content()
        except PlaywrightError:
            try:
                page.wait_for_load_state("networkidle", timeout=60000)
            except PlaywrightError:
                pass
    try:
        return page.content()
    except PlaywrightError:
        return ""


def extract_confluence_markdown(url, cookies_file, refresh_on_fail=True):
    cookies = load_cookies(cookies_file)
    selectors = CONTENT_SELECTORS + ["body"]

    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True)
        context = browser.new_context()
        if cookies:
            try:
                context.add_cookies(cookies)
            except Exception:
                browser.close()
                html, title, final_url = interactive_login_and_save_cookies(url, cookies_file)
                if need_refresh(html, final_url):
                    raise RuntimeError(
                        f"Interactive login completed but the page still looks unauthenticated: {final_url}"
                    )
                return extract_visible_markdown(html), title
        page = context.new_page()
        navigate_with_redirect_resilience(page, url, 120000)
        wait_for_confluence_content(page, timeout_ms=120000)

        html = fetch_page_html(page, selectors)
        title = clean_title(page.title())
        final_url = page.url
        browser.close()

    if need_refresh(html, final_url):
        if not refresh_on_fail:
            raise RuntimeError(
                f"Authenticated extraction did not reach page content and still appears to require login: {final_url}"
            )
        html, title, final_url = interactive_login_and_save_cookies(url, cookies_file)
        if need_refresh(html, final_url):
            raise RuntimeError(
                f"Interactive login completed but the page still looks unauthenticated: {final_url}"
            )
        return extract_visible_markdown(html), title

    markdown = extract_visible_markdown(html)
    return markdown, title


def default_output_path(url, title, output_dir):
    timestamp = datetime.now().strftime("%Y%m%d_%H%M")
    slug = slugify(title) if title else url_fallback_slug(url)
    return os.path.join(output_dir, f"{slug}_{timestamp}.md")


def main():
    parser = argparse.ArgumentParser(
        description="Extract visible Confluence page content to Markdown with cookie refresh."
    )
    parser.add_argument("url", help="Confluence URL to extract")
    parser.add_argument("--output", help="Output Markdown path")
    parser.add_argument("--output-dir", default="output", help="Directory for auto-named output files")
    parser.add_argument(
        "--refresh-cookies",
        action="store_true",
        help="Force interactive login before extraction",
    )
    parser.add_argument(
        "--cookies-file",
        default=DEFAULT_COOKIES_FILE,
        help="Path to the persistent cookies file",
    )
    args = parser.parse_args()

    if args.refresh_cookies or not os.path.exists(args.cookies_file):
        interactive_login_and_save_cookies(args.url, args.cookies_file)

    markdown, title = extract_confluence_markdown(args.url, args.cookies_file)
    output_path = args.output or default_output_path(args.url, title, args.output_dir)
    os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as handle:
        handle.write(markdown + "\n")

    print(f"Rendered Markdown saved to {output_path}")


if __name__ == "__main__":
    main()
