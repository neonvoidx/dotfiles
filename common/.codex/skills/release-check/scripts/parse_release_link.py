#!/usr/bin/env python3
"""Parse a Shepherd release link into stable identifiers."""

from __future__ import annotations

import json
import re
import sys
from urllib.parse import parse_qs, urlparse


RELEASE_PATH_RE = re.compile(
    r"/shepherd/projects/(?P<project>[^/]+)/flocks/(?P<flock>[^/]+)/releases/(?P<release_id>[0-9a-fA-F-]{36})(?P<suffix>/[^?#]*)?"
)
EXECUTION_TARGET_PATH_RE = re.compile(
    r"/phases/(?P<phase>[^/]+)/executionTargets/(?P<execution_target_id>[^/?#]+)"
)
RELEASE_TARGET_PATH_RE = re.compile(r"/releaseTargets/(?P<release_target_id>[^/?#]+)")


def parse_release_link(raw: str) -> dict[str, object]:
    raw = raw.strip()
    if not raw:
        raise ValueError("expected a Shepherd release link")

    parsed = urlparse(raw)
    path = parsed.path or raw
    query = parse_qs(parsed.query)

    match = RELEASE_PATH_RE.search(path)
    if not match:
        raise ValueError(f"could not parse Shepherd release identifiers from: {raw}")

    result: dict[str, object] = {
        "project": match.group("project"),
        "flock": match.group("flock"),
        "release_id": match.group("release_id"),
    }

    suffix = match.group("suffix") or ""
    execution_target_match = EXECUTION_TARGET_PATH_RE.search(suffix)
    if execution_target_match:
        result["phase"] = execution_target_match.group("phase")
        result["execution_target_id"] = execution_target_match.group(
            "execution_target_id"
        )

    release_target_match = RELEASE_TARGET_PATH_RE.search(suffix)
    if release_target_match:
        result["release_target_id"] = release_target_match.group("release_target_id")
    elif query.get("releaseTargetId"):
        result["release_target_id"] = query["releaseTargetId"][0]

    return result


def main() -> int:
    raw = sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()
    try:
        result = parse_release_link(raw)
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 1

    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
