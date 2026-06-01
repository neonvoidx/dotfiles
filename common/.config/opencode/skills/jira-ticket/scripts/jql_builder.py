#!/usr/bin/env python3
"""Construct Jira JQL from common structured filters."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from typing import Iterable, Optional


def _jql_quote(value: str) -> str:
    return '"' + (value or "").replace('"', '\\"') + '"'


def _normalize_csv(values: Optional[str]) -> list[str]:
    if not values:
        return []
    return [item.strip() for item in values.split(",") if item.strip()]


def _jql_in(values: Iterable[str]) -> str:
    normalized = [value for value in (values or []) if value]
    if not normalized:
        return "()"
    return "(" + ",".join(_jql_quote(value) for value in normalized) + ")"


@dataclass(frozen=True)
class JqlQueryArgs:
    conditions: list[str]
    order_by: str = "created DESC"


def build_jql(args: JqlQueryArgs) -> str:
    if not args.conditions:
        raise ValueError("at least one condition is required")

    jql = " AND ".join(condition for condition in args.conditions if condition)
    if args.order_by:
        jql += f" ORDER BY {args.order_by}"
    return jql


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Build Jira JQL from common filters")
    parser.add_argument("--project", help="Jira project key, for example TENLS")
    parser.add_argument("--ticket-key", help="Comma-separated Jira ticket keys")
    parser.add_argument("--severity", help="Comma-separated severity values, for example 2,2.5,3")
    parser.add_argument(
        "--severity-field",
        default="Severity",
        help="Jira field name for severity (default: Severity)",
    )
    parser.add_argument("--created-since", help="Created lower bound, for example -7d or 2026-03-01")
    parser.add_argument("--created-until", help="Created upper bound, for example now() or 2026-03-20")
    parser.add_argument("--updated-since", help="Updated lower bound")
    parser.add_argument("--updated-until", help="Updated upper bound")
    parser.add_argument("--status", help="Comma-separated status values")
    parser.add_argument("--assignee", help="Assignee name or account id")
    parser.add_argument("--reporter", help="Reporter name or account id")
    parser.add_argument("--labels", help="Comma-separated Jira labels")
    parser.add_argument("--text", help="Free-text search term")
    parser.add_argument(
        "--raw-condition",
        action="append",
        default=[],
        help="Append an exact JQL clause. Can be supplied multiple times.",
    )
    parser.add_argument(
        "--order-by",
        default=None,
        help="Explicit ORDER BY clause contents, for example 'updated DESC, created DESC'",
    )
    parser.add_argument(
        "--sort-field",
        default="created",
        help="Sort field used when --order-by is not supplied (default: created)",
    )
    parser.add_argument(
        "--sort-order",
        default="DESC",
        choices=["ASC", "DESC", "asc", "desc"],
        help="Sort direction used when --order-by is not supplied (default: DESC)",
    )
    return parser


def main(argv: Optional[list[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    conditions: list[str] = []

    if args.project:
        conditions.append(f"project = {_jql_quote(args.project)}")

    ticket_keys = _normalize_csv(args.ticket_key)
    if len(ticket_keys) == 1:
        conditions.append(f"key = {_jql_quote(ticket_keys[0])}")
    elif ticket_keys:
        conditions.append(f"key in {_jql_in(ticket_keys)}")

    severities = _normalize_csv(args.severity)
    if len(severities) == 1:
        conditions.append(f"{args.severity_field} = {_jql_quote(severities[0])}")
    elif severities:
        conditions.append(f"{args.severity_field} in {_jql_in(severities)}")

    if args.created_since:
        conditions.append(f"created >= {args.created_since}")
    if args.created_until:
        conditions.append(f"created <= {args.created_until}")
    if args.updated_since:
        conditions.append(f"updated >= {args.updated_since}")
    if args.updated_until:
        conditions.append(f"updated <= {args.updated_until}")

    statuses = _normalize_csv(args.status)
    if len(statuses) == 1:
        conditions.append(f"status = {_jql_quote(statuses[0])}")
    elif statuses:
        conditions.append(f"status in {_jql_in(statuses)}")

    if args.assignee:
        conditions.append(f"assignee = {_jql_quote(args.assignee)}")
    if args.reporter:
        conditions.append(f"reporter = {_jql_quote(args.reporter)}")

    labels = _normalize_csv(args.labels)
    if len(labels) == 1:
        conditions.append(f"labels = {_jql_quote(labels[0])}")
    elif labels:
        conditions.append(f"labels in {_jql_in(labels)}")

    if args.text:
        conditions.append(f'text ~ {_jql_quote(args.text)}')

    conditions.extend(clause for clause in args.raw_condition if clause)

    if not conditions:
        raise SystemExit("at least one filter is required")

    order_by = args.order_by or f"{args.sort_field} {args.sort_order.upper()}"
    print(build_jql(JqlQueryArgs(conditions=conditions, order_by=order_by)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
