#!/usr/bin/env python3
"""Normalize MFO region-build snapshots into the tracer schema."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from region_build_common import dump_json, normalize_graph


def load_payload(path: str | None) -> object:
    if not path or path == "-":
        return json.load(sys.stdin)
    return json.loads(Path(path).read_text())


def main() -> int:
    parser = argparse.ArgumentParser(description="Normalize MFO region-build snapshot payloads.")
    parser.add_argument("input", nargs="?", default="-", help="Input JSON file, or stdin when omitted.")
    parser.add_argument(
        "--output",
        help="Optional output path. Defaults to stdout.",
    )
    args = parser.parse_args()

    normalized = normalize_graph(load_payload(args.input))
    rendered = dump_json(normalized)
    if args.output:
        Path(args.output).write_text(rendered)
    else:
        sys.stdout.write(rendered)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
