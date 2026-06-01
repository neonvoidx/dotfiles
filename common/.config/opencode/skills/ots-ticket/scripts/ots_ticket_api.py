#!/usr/bin/env python3
"""Helper for Oracle Ticketing Platform API lookups and comment posting."""

from __future__ import annotations

import argparse
import configparser
import json
import os
from pathlib import Path
import subprocess
import sys
from typing import Any, Dict, Iterable, List, Tuple
from urllib.parse import urlencode, urljoin
from urllib.request import Request, urlopen

BASE_URI = "https://ticketing-platform.us-chicago-1.oci.oraclecloud.com/"
DEFAULT_PROFILE = os.environ.get("OCI_CLI_PROFILE", "oc1")
DEFAULT_API_VERSION = "20180828"
SEARCH_API_VERSION = "20230531"
UNSET = object()


class OtsTicketError(RuntimeError):
    """Raised for recoverable command errors."""


def build_url(path: str, api_version: str | None = None, query: Dict[str, str] | None = None) -> str:
    normalized = path.strip()
    if not normalized:
        raise OtsTicketError("path cannot be empty")

    if normalized.startswith("http://") or normalized.startswith("https://"):
        base = normalized
    else:
        relative = normalized.lstrip("/")
        if not relative[:8].isdigit():
            if not api_version:
                raise OtsTicketError(
                    "relative paths must start with an API version or be used with --api-version"
                )
            relative = f"{api_version}/{relative}"
        base = urljoin(BASE_URI, relative)

    if query:
        separator = "&" if "?" in base else "?"
        return f"{base}{separator}{urlencode(query)}"
    return base


def run_command(command: List[str]) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(command, capture_output=True, text=True, check=False)
    except FileNotFoundError as exc:
        raise OtsTicketError(f"required command not found: {command[0]}") from exc


def validate_session(profile: str) -> None:
    result = run_command(
        ["oci", "--profile", profile, "session", "validate", "--local", "--output", "json"]
    )
    if result.returncode == 0:
        return

    combined = "\n".join(part.strip() for part in (result.stdout, result.stderr) if part.strip())
    lowered = combined.lower()
    if "session has expired" in lowered or "expired" in lowered:
        raise OtsTicketError(
            f"OCI CLI session for profile '{profile}' is expired. "
            f"Run `oci --profile {profile} session refresh` and retry."
        )
    raise OtsTicketError(
        f"unable to validate OCI CLI session for profile '{profile}': {combined or 'unknown error'}"
    )


def read_security_token(profile: str) -> str:
    config = configparser.ConfigParser()
    config_path = (
        os.environ.get("OCI_CLI_CONFIG_FILE")
        or os.environ.get("OCI_CONFIG_FILE")
        or os.path.expanduser("~/.oci/config")
    )
    if not config.read(os.path.expanduser(config_path)):
        raise OtsTicketError(f"OCI config file not found: {config_path}")
    if profile not in config:
        raise OtsTicketError(f"OCI profile '{profile}' not found in {config_path}")

    security_token_file = config[profile].get("security_token_file")
    if not security_token_file:
        raise OtsTicketError(
            f"OCI profile '{profile}' does not define security_token_file for download auth"
        )

    token_path = Path(os.path.expanduser(security_token_file))
    if not token_path.exists():
        raise OtsTicketError(f"security token file not found: {token_path}")
    token = token_path.read_text().strip()
    if not token:
        raise OtsTicketError(f"security token file is empty: {token_path}")
    return token


def raw_json_request(
    profile: str, url: str, *, method: str = "GET", body: Dict[str, Any] | None = None
) -> dict:
    validate_session(profile)
    command = [
        "oci",
        "--profile",
        profile,
        "--auth",
        "security_token",
        "raw-request",
        "--http-method",
        method,
        "--target-uri",
        url,
        "--output",
        "json",
    ]
    if body is not None:
        command.extend(["--request-body", json.dumps(body)])

    result = run_command(
        command
    )

    if result.returncode != 0:
        combined = "\n".join(part.strip() for part in (result.stdout, result.stderr) if part.strip())
        raise OtsTicketError(combined or f"{method} raw-request failed for {url}")

    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        snippet = result.stdout.strip()[:400]
        raise OtsTicketError(f"raw-request returned non-JSON output: {snippet}") from exc


def response_data(response: dict, *, context: str) -> Dict[str, Any]:
    payload = response.get("data")
    if not isinstance(payload, dict):
        raise OtsTicketError(f"{context} returned an unexpected payload shape")
    return payload


def normalize_label_names(raw_labels: Any) -> List[str]:
    if raw_labels is None:
        return []
    if not isinstance(raw_labels, list):
        raise OtsTicketError("ticket labels payload had an unexpected shape")

    normalized: List[str] = []
    for label in raw_labels:
        if isinstance(label, str):
            normalized.append(label)
        elif isinstance(label, dict) and isinstance(label.get("name"), str):
            normalized.append(label["name"])
        else:
            raise OtsTicketError("ticket labels payload had an unsupported entry")
    return normalized


def normalize_csv_labels(values: str | None) -> List[str]:
    if not values:
        return []
    seen: set[str] = set()
    ordered: List[str] = []
    for value in values.split(","):
        normalized = value.strip()
        if not normalized or normalized in seen:
            continue
        seen.add(normalized)
        ordered.append(normalized)
    return ordered


def resolve_ots_label_mutation(
    current_labels: List[str],
    *,
    add_labels: List[str] | None = None,
    remove_labels: List[str] | None = None,
    set_labels: List[str] | None = None,
) -> Dict[str, Any]:
    if set_labels is not None:
        return {
            "changed": set_labels != current_labels,
            "resolvedLabels": set_labels,
        }

    add_labels = add_labels or []
    remove_labels = remove_labels or []
    current_set = set(current_labels)
    remove_set = set(label for label in remove_labels if label in current_set)
    add_ops = [label for label in add_labels if label not in current_set]
    resolved_labels = [label for label in current_labels if label not in remove_set] + add_ops

    return {
        "changed": bool(add_ops or remove_set),
        "resolvedLabels": resolved_labels,
        "appliedAdd": add_ops,
        "appliedRemove": [label for label in current_labels if label in remove_set],
    }


def build_ticket_update_body(
    ticket_data: Dict[str, Any],
    *,
    status: str | None = None,
    labels: List[str] | None = None,
    root_cause_description: Any = UNSET,
    resolution_description: Any = UNSET,
    status_update: Any = UNSET,
) -> Dict[str, Any]:
    project = ticket_data.get("project")
    project_key = ticket_data.get("projectKey")
    if project_key is None and isinstance(project, dict):
        project_key = project.get("key")

    required_fields = {
        "title": ticket_data.get("title"),
        "issueType": ticket_data.get("issueType"),
        "projectKey": project_key,
        "severity": ticket_data.get("severity"),
        "status": status or ticket_data.get("status"),
        "labels": labels if labels is not None else normalize_label_names(ticket_data.get("labels")),
        "projectFields": ticket_data.get("projectFields") or [],
    }
    missing = [key for key, value in required_fields.items() if value is None]
    if missing:
        raise OtsTicketError(
            "ticket payload is missing required fields for ticket update: "
            + ", ".join(sorted(missing))
        )

    description = ticket_data.get("description")
    if description is not None:
        required_fields["description"] = description

    optional_ticket_fields = {
        "rootCauseDescription": (
            ticket_data.get("rootCauseDescription")
            if root_cause_description is UNSET
            else root_cause_description
        ),
        "resolutionDescription": (
            ticket_data.get("resolutionDescription")
            if resolution_description is UNSET
            else resolution_description
        ),
        "statusUpdate": ticket_data.get("statusUpdate") if status_update is UNSET else status_update,
    }
    for key, value in optional_ticket_fields.items():
        if value is not None:
            required_fields[key] = value

    return required_fields


def download_with_bearer(profile: str, url: str, destination: str, accept: str | None) -> None:
    validate_session(profile)
    token = read_security_token(profile)
    headers = {"Authorization": f"Bearer {token}"}
    if accept:
        headers["Accept"] = accept
    request = Request(url, headers=headers, method="GET")

    try:
        with urlopen(request, timeout=60) as response:
            payload = response.read()
    except Exception as exc:  # pragma: no cover - network failures are environment-specific
        raise OtsTicketError(f"download failed for {url}: {exc}") from exc

    output_path = Path(destination).expanduser()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(payload)


def parse_query_items(items: Iterable[str]) -> Dict[str, str]:
    query: Dict[str, str] = {}
    for item in items:
        if "=" not in item:
            raise OtsTicketError(f"invalid query parameter '{item}'; expected key=value")
        key, value = item.split("=", 1)
        key = key.strip()
        if not key:
            raise OtsTicketError(f"invalid query parameter '{item}'; key cannot be empty")
        query[key] = value
    return query


def read_comment_text(args: argparse.Namespace) -> str:
    text_sources = [
        args.text is not None,
        bool(args.text_file),
        args.stdin,
    ]
    if sum(text_sources) != 1:
        raise OtsTicketError("provide exactly one of --text, --text-file, or --stdin")

    if args.text is not None:
        text = args.text
    elif args.text_file:
        path = Path(args.text_file).expanduser()
        if not path.exists():
            raise OtsTicketError(f"text file not found: {path}")
        text = path.read_text()
    else:
        text = sys.stdin.read()

    if not text.strip():
        raise OtsTicketError("comment text cannot be empty")
    return text


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Read Oracle Ticketing Platform resources and create comments with an OCI CLI session-backed profile."
    )
    parser.add_argument("--profile", default=DEFAULT_PROFILE, help="OCI CLI profile to use")
    parser.add_argument(
        "--envelope",
        action="store_true",
        help="Print the full raw-request envelope instead of only the data payload",
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    ticket = subparsers.add_parser("ticket", help="Fetch one ticket by id or OCID")
    ticket.add_argument("ticket_id")
    ticket.add_argument("--api-version", default=DEFAULT_API_VERSION)

    project = subparsers.add_parser("project", help="Fetch one project by key")
    project.add_argument("project")
    project.add_argument("--api-version", default=DEFAULT_API_VERSION)

    comments = subparsers.add_parser("comments", help="List ticket comments")
    comments.add_argument("ticket_id")
    comments.add_argument("--limit", type=int, default=20)
    comments.add_argument("--api-version", default=DEFAULT_API_VERSION)

    comment_create = subparsers.add_parser("comment-create", help="Create one ticket comment")
    comment_create.add_argument("ticket_id")
    comment_text = comment_create.add_mutually_exclusive_group(required=True)
    comment_text.add_argument("--text", help="Comment text to post")
    comment_text.add_argument("--text-file", help="Read comment text from a file")
    comment_text.add_argument("--stdin", action="store_true", help="Read comment text from stdin")
    comment_create.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the resolved request body without posting the comment",
    )
    comment_create.add_argument("--api-version", default=DEFAULT_API_VERSION)

    status_transition = subparsers.add_parser(
        "status-transition",
        help="Transition a ticket to a new status using raw-request",
    )
    status_transition.add_argument("ticket_id")
    status_transition.add_argument("--status", required=True, help="Target ticket status")
    status_transition.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the resolved PUT request body without sending the transition",
    )
    status_transition.add_argument("--api-version", default=DEFAULT_API_VERSION)

    labels_add = subparsers.add_parser(
        "labels-add",
        help="Add one or more OTS ticket labels without disturbing existing labels",
    )
    labels_add.add_argument("ticket_id")
    labels_add.add_argument("--labels", required=True, help="Comma-separated OTS labels to add")
    labels_add.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the resolved PUT request body without sending the label update",
    )
    labels_add.add_argument("--api-version", default=DEFAULT_API_VERSION)

    labels_remove = subparsers.add_parser(
        "labels-remove",
        help="Remove one or more OTS ticket labels when present",
    )
    labels_remove.add_argument("ticket_id")
    labels_remove.add_argument("--labels", required=True, help="Comma-separated OTS labels to remove")
    labels_remove.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the resolved PUT request body without sending the label update",
    )
    labels_remove.add_argument("--api-version", default=DEFAULT_API_VERSION)

    labels_set = subparsers.add_parser(
        "labels-set",
        help="Replace OTS ticket labels with an exact comma-separated set",
    )
    labels_set.add_argument("ticket_id")
    labels_set.add_argument(
        "--labels",
        default="",
        help="Comma-separated OTS labels to keep; an empty value clears all labels",
    )
    labels_set.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the resolved PUT request body without sending the label update",
    )
    labels_set.add_argument("--api-version", default=DEFAULT_API_VERSION)

    resolution_details = subparsers.add_parser(
        "resolution-details-update",
        help="Update the short OTS resolution summary fields without replacing the full ticket comment flow",
    )
    resolution_details.add_argument("ticket_id")
    resolution_details.add_argument(
        "--root-cause-description",
        help="Brief root cause summary for the ticket's Resolution Details field",
    )
    resolution_details.add_argument(
        "--resolution-description",
        help="Brief remediation or resolution summary for the ticket's Resolution Details field",
    )
    resolution_details.add_argument(
        "--status-update",
        help="Brief current-status summary for the ticket's Resolution Details field",
    )
    resolution_details.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the resolved PUT request body without sending the resolution-details update",
    )
    resolution_details.add_argument("--api-version", default=DEFAULT_API_VERSION)

    activities = subparsers.add_parser("activities", help="List ticket activity history")
    activities.add_argument("ticket_id")
    activities.add_argument("--limit", type=int, default=20)
    activities.add_argument("--sort-order", default="DESC", choices=["ASC", "DESC"])
    activities.add_argument("--resource", default="")
    activities.add_argument("--api-version", default=DEFAULT_API_VERSION)

    linked = subparsers.add_parser("linked-tickets", help="List linked tickets for a ticket")
    linked.add_argument("ticket_id")
    linked.add_argument("--api-version", default=DEFAULT_API_VERSION)

    tql = subparsers.add_parser("tql", help="Run a TQL ticket search")
    tql.add_argument("expression")
    tql.add_argument("--limit", type=int, default=60)
    tql.add_argument("--api-version", default=SEARCH_API_VERSION)

    dashboards = subparsers.add_parser("dashboards", help="List dashboards")
    dashboards.add_argument("--page", type=int, default=1)
    dashboards.add_argument("--api-version", default=DEFAULT_API_VERSION)

    subqueries = subparsers.add_parser("subqueries", help="List saved subqueries")
    subqueries.add_argument("--limit", type=int, default=5)
    subqueries.add_argument("--api-version", default=SEARCH_API_VERSION)

    request = subparsers.add_parser(
        "request",
        help="Fetch a relative path or absolute URL, optionally downloading the response",
    )
    request.add_argument("path")
    request.add_argument("--api-version", default=DEFAULT_API_VERSION)
    request.add_argument("--query", action="append", default=[], help="Query parameter in key=value form")
    request.add_argument("--download", help="Write the raw response body to a file")
    request.add_argument("--accept", help="Optional Accept header for download mode")

    return parser


def resolve_request(args: argparse.Namespace) -> Tuple[str, Dict[str, str]]:
    if args.command == "ticket":
        return f"{args.api_version}/tickets/{args.ticket_id}", {}
    if args.command == "project":
        return f"{args.api_version}/projects/{args.project}", {}
    if args.command == "comments":
        return f"{args.api_version}/tickets/{args.ticket_id}/comments", {"limit": str(args.limit)}
    if args.command == "comment-create":
        return f"{args.api_version}/tickets/{args.ticket_id}/comments", {}
    if args.command == "activities":
        return (
            f"{args.api_version}/tickets/{args.ticket_id}/activityHistory",
            {
                "resource": args.resource,
                "limit": str(args.limit),
                "sortOrder": args.sort_order,
            },
        )
    if args.command == "linked-tickets":
        return f"{args.api_version}/tickets/{args.ticket_id}/linkTickets", {}
    if args.command == "tql":
        return f"{args.api_version}/tickets", {"tql": args.expression, "limit": str(args.limit)}
    if args.command == "dashboards":
        return f"{args.api_version}/dashboards", {"page": str(args.page)}
    if args.command == "subqueries":
        return f"{args.api_version}/subQueries", {"limit": str(args.limit)}
    if args.command == "request":
        return args.path, parse_query_items(args.query)
    raise OtsTicketError(f"unsupported command: {args.command}")


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    try:
        if args.command in {
            "status-transition",
            "labels-add",
            "labels-remove",
            "labels-set",
            "resolution-details-update",
        }:
            path = f"{args.api_version}/tickets/{args.ticket_id}"
            url = build_url(path, args.api_version, {})
            ticket_response = raw_json_request(args.profile, url)
            ticket_data = response_data(ticket_response, context="ticket lookup")
            current_labels = normalize_label_names(ticket_data.get("labels"))

            if args.command == "status-transition":
                body = build_ticket_update_body(ticket_data, status=args.status)

                if args.dry_run:
                    print(
                        json.dumps(
                            {
                                "command": args.command,
                                "current_status": ticket_data.get("status"),
                                "method": "PUT",
                                "url": url,
                                "body": body,
                                "noop": ticket_data.get("status") == args.status,
                            },
                            indent=2,
                            sort_keys=True,
                        )
                    )
                    return 0

                if ticket_data.get("status") == args.status:
                    payload = {
                        "message": f"ticket {args.ticket_id} is already in status '{args.status}'",
                        "noop": True,
                        "status": ticket_data.get("status"),
                        "ticketId": args.ticket_id,
                    }
                    print(json.dumps(payload, indent=2, sort_keys=True))
                    return 0

                response = raw_json_request(args.profile, url, method="PUT", body=body)
                payload = response if args.envelope else response.get("data")
                print(json.dumps(payload, indent=2, sort_keys=True))
                return 0

            if args.command == "resolution-details-update":
                requested_updates = {
                    "rootCauseDescription": args.root_cause_description,
                    "resolutionDescription": args.resolution_description,
                    "statusUpdate": args.status_update,
                }
                if all(value is None for value in requested_updates.values()):
                    raise OtsTicketError(
                        "provide at least one of --root-cause-description, "
                        "--resolution-description, or --status-update"
                    )

                root_cause_description = (
                    UNSET if args.root_cause_description is None else args.root_cause_description
                )
                resolution_description = (
                    UNSET if args.resolution_description is None else args.resolution_description
                )
                status_update = UNSET if args.status_update is None else args.status_update

                body = build_ticket_update_body(
                    ticket_data,
                    root_cause_description=root_cause_description,
                    resolution_description=resolution_description,
                    status_update=status_update,
                )
                current_values = {
                    "rootCauseDescription": ticket_data.get("rootCauseDescription"),
                    "resolutionDescription": ticket_data.get("resolutionDescription"),
                    "statusUpdate": ticket_data.get("statusUpdate"),
                }
                resolved_values = {key: body.get(key) for key in current_values}
                noop = all(
                    requested_updates[key] is None or requested_updates[key] == current_values.get(key)
                    for key in requested_updates
                )

                if args.dry_run:
                    print(
                        json.dumps(
                            {
                                "command": args.command,
                                "current_values": current_values,
                                "requested_updates": requested_updates,
                                "resolved_values": resolved_values,
                                "method": "PUT",
                                "url": url,
                                "body": body,
                                "noop": noop,
                            },
                            indent=2,
                            sort_keys=True,
                        )
                    )
                    return 0

                if noop:
                    payload = {
                        "message": "ticket resolution details already match the requested values",
                        "noop": True,
                        "resolvedValues": resolved_values,
                        "ticketId": args.ticket_id,
                    }
                    print(json.dumps(payload, indent=2, sort_keys=True))
                    return 0

                response = raw_json_request(args.profile, url, method="PUT", body=body)
                payload = {
                    "updated": True,
                    "ticketId": args.ticket_id,
                    "resolvedValues": resolved_values,
                }
                if args.envelope:
                    payload["response"] = response
                else:
                    payload["response"] = response.get("data")
                print(json.dumps(payload, indent=2, sort_keys=True))
                return 0

            requested_labels = normalize_csv_labels(args.labels)
            label_payload: Dict[str, Any] = {
                "command": args.command,
                "currentLabels": current_labels,
                "ticketId": args.ticket_id,
            }
            if args.command == "labels-add":
                mutation = resolve_ots_label_mutation(current_labels, add_labels=requested_labels)
                label_payload["requestedAdd"] = requested_labels
            elif args.command == "labels-remove":
                mutation = resolve_ots_label_mutation(current_labels, remove_labels=requested_labels)
                label_payload["requestedRemove"] = requested_labels
            else:
                mutation = resolve_ots_label_mutation(current_labels, set_labels=requested_labels)
                label_payload["requestedLabels"] = requested_labels

            label_payload["resolvedLabels"] = mutation["resolvedLabels"]
            if "appliedAdd" in mutation:
                label_payload["appliedAdd"] = mutation["appliedAdd"]
            if "appliedRemove" in mutation:
                label_payload["appliedRemove"] = mutation["appliedRemove"]

            if not mutation["changed"]:
                label_payload["noop"] = True
                label_payload["reason"] = "ticket labels already match requested mutation"
                print(json.dumps(label_payload, indent=2, sort_keys=True))
                return 0

            body = build_ticket_update_body(ticket_data, labels=mutation["resolvedLabels"])
            if args.dry_run:
                label_payload["dry_run"] = True
                label_payload["request"] = {
                    "body": body,
                    "method": "PUT",
                    "url": url,
                }
                print(json.dumps(label_payload, indent=2, sort_keys=True))
                return 0

            response = raw_json_request(args.profile, url, method="PUT", body=body)
            label_payload["updated"] = True
            if args.envelope:
                label_payload["response"] = response
            else:
                label_payload["response"] = response.get("data")
            print(json.dumps(label_payload, indent=2, sort_keys=True))
            return 0

        path, query = resolve_request(args)
        url = build_url(path, getattr(args, "api_version", None), query)
        if args.command == "comment-create":
            body = {"text": read_comment_text(args)}
            if args.dry_run:
                print(
                    json.dumps(
                        {
                            "command": args.command,
                            "method": "POST",
                            "url": url,
                            "body": body,
                        },
                        indent=2,
                        sort_keys=True,
                    )
                )
                return 0
            response = raw_json_request(args.profile, url, method="POST", body=body)
            payload = response if args.envelope else response.get("data")
            print(json.dumps(payload, indent=2, sort_keys=True))
            return 0
        if args.command == "request" and args.download:
            download_with_bearer(args.profile, url, args.download, args.accept)
            print(json.dumps({"downloaded_to": str(Path(args.download).expanduser()), "url": url}, indent=2))
            return 0

        response = raw_json_request(args.profile, url)
        payload = response if args.envelope else response.get("data")
        print(json.dumps(payload, indent=2, sort_keys=True))
        return 0
    except OtsTicketError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
