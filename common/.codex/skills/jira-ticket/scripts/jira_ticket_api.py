#!/usr/bin/env python3
"""Read and write Jira ticket data using configured Jira auth."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import sys
from typing import Any, Dict, Iterable, Optional
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen


DEFAULT_SEARCH_FIELDS = "summary,status,priority,labels,created,updated"
DEFAULT_TICKET_FIELDS = "*all"
DEFAULT_COMMENT_PAGE_SIZE = 100
DEFAULT_SEARCH_PAGE_SIZE = 100
JIRA_INSTANCE_ENV = {
    "sd": {
        "name": "Jira-SD",
        "env_file": "~/.env",
        "env_file_env": "JIRA_SD_ENV_FILE",
        "url": ("JIRA_URL",),
        "token": ("JIRA_PERSONAL_TOKEN", "JIRA_TOKEN"),
    },
    "oci": {
        "name": "Jira OCI",
        "env_file": "~/.env.jira-oci",
        "env_file_env": "JIRA_OCI_ENV_FILE",
        "url": ("JIRA_URL",),
        "token": ("JIRA_PERSONAL_TOKEN", "JIRA_TOKEN"),
    },
}
JIRA_RESOLUTION_DETAIL_FIELDS = {
    "rootCauseDescription": "Root Cause Description",
    "resolutionDescription": "Resolution Description",
    "statusUpdate": "Status Update",
}


class JiraTicketError(RuntimeError):
    """Raised for recoverable Jira helper errors."""


def _json_dump(payload: Any) -> None:
    print(json.dumps(payload, indent=2, sort_keys=True))


def _resolve_jira_env_file(instance: str, raw_env_file: Optional[str]) -> Path:
    instance_config = JIRA_INSTANCE_ENV[instance]
    env_file_env = instance_config["env_file_env"]
    return Path(
        raw_env_file
        or os.environ.get(env_file_env)
        or os.environ.get("JIRA_TICKET_ENV_FILE")
        or instance_config["env_file"]
    ).expanduser()


def _read_dotenv_file(path: Path, *, required: bool = False) -> dict[str, str]:
    if not path.exists():
        if required:
            raise JiraTicketError(f"Jira env file not found: {path}")
        return {}
    if path.is_dir():
        raise JiraTicketError(f"Jira env file is a directory: {path}")

    values: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        stripped = raw_line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if stripped.startswith("export "):
            stripped = stripped[len("export ") :].strip()
        if "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        key = key.strip()
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
            value = value[1:-1]
        if key:
            values[key] = value
    return values


def _read_configured_value(
    explicit_value: Optional[str],
    env_names: tuple[str, ...],
    env_file_values: dict[str, str],
    *,
    env_file: Path,
    instance_name: str,
    value_label: str,
) -> str:
    if explicit_value:
        return explicit_value

    for env_name in env_names:
        value = (env_file_values.get(env_name) or "").strip()
        if value:
            return value

    for env_name in env_names:
        value = (os.environ.get(env_name) or "").strip()
        if value:
            return value

    names = " or ".join(env_names)
    raise JiraTicketError(
        f"{instance_name} {value_label} missing. Set {names} in {env_file}, "
        f"export one of those variables, or pass --{value_label.replace('_', '-')}."
    )


def _resolve_jira_auth(
    *,
    instance: str,
    base_url: Optional[str],
    token: Optional[str],
    env_file: Optional[str],
) -> tuple[str, str]:
    instance_config = JIRA_INSTANCE_ENV[instance]
    env_path = _resolve_jira_env_file(instance, env_file)
    env_file_values = _read_dotenv_file(env_path, required=env_file is not None)
    instance_name = instance_config["name"]

    resolved_base_url = _read_configured_value(
        base_url,
        instance_config["url"],
        env_file_values,
        env_file=env_path,
        instance_name=instance_name,
        value_label="base_url",
    )
    resolved_token = _read_configured_value(
        token,
        instance_config["token"],
        env_file_values,
        env_file=env_path,
        instance_name=instance_name,
        value_label="token",
    )
    return resolved_base_url, resolved_token


def _normalize_csv(values: Optional[str]) -> list[str]:
    if not values:
        return []
    return [value.strip() for value in values.split(",") if value.strip()]


def _dedupe_preserve_order(values: Iterable[str]) -> list[str]:
    seen: set[str] = set()
    ordered: list[str] = []
    for value in values:
        if value in seen:
            continue
        seen.add(value)
        ordered.append(value)
    return ordered


def _csv_join(values: Iterable[str]) -> str:
    return ",".join(value for value in _dedupe_preserve_order(values) if value)


def _read_comment_text(args: argparse.Namespace) -> str:
    modes = [args.text is not None, bool(args.text_file), args.stdin]
    if sum(modes) != 1:
        raise JiraTicketError("provide exactly one of --text, --text-file, or --stdin")

    if args.text is not None:
        text = args.text
    elif args.text_file:
        path = Path(args.text_file).expanduser()
        if not path.exists():
            raise JiraTicketError(f"text file not found: {path}")
        text = path.read_text(encoding="utf-8")
    else:
        text = sys.stdin.read()

    if not text.strip():
        raise JiraTicketError("comment text cannot be empty")
    return text


def _field_map_by_name(field_defs: list[dict]) -> dict[str, str]:
    mapping: dict[str, str] = {}
    for field in field_defs:
        if not isinstance(field, dict):
            continue
        field_id = str(field.get("id") or "").strip()
        field_name = str(field.get("name") or "").strip()
        if field_id and field_name:
            mapping[field_id] = field_name
    return mapping


def _issue_fields_by_name(fields: dict[str, Any], field_map: dict[str, str]) -> dict[str, Any]:
    named: dict[str, Any] = {}
    for field_id, value in (fields or {}).items():
        field_name = field_map.get(field_id)
        if field_name and field_name not in named:
            named[field_name] = value
    return named


class JiraClient:
    def __init__(self, *, base_url: str, token: str) -> None:
        self.base_url = base_url.rstrip("/")
        self.token = token

    def _headers(self) -> dict[str, str]:
        return {
            "Authorization": f"Bearer {self.token}",
            "Accept": "application/json",
            "Content-Type": "application/json",
        }

    def _request(
        self,
        method: str,
        path: str,
        *,
        params: Optional[dict[str, Any]] = None,
        body: Optional[dict[str, Any]] = None,
    ) -> Any:
        query = urlencode({k: v for k, v in (params or {}).items() if v is not None and v != ""}, doseq=True)
        url = f"{self.base_url}{path}"
        if query:
            url = f"{url}?{query}"

        data = None
        if body is not None:
            data = json.dumps(body).encode("utf-8")

        request = Request(url, data=data, headers=self._headers(), method=method.upper())
        try:
            with urlopen(request, timeout=60) as response:
                raw = response.read().decode("utf-8", errors="replace")
        except HTTPError as exc:
            snippet = exc.read().decode("utf-8", errors="replace")[:800]
            raise JiraTicketError(f"{method.upper()} {url} failed ({exc.code}): {snippet}") from exc
        except URLError as exc:
            raise JiraTicketError(f"{method.upper()} {url} failed: {exc.reason}") from exc

        if not raw.strip():
            return {}
        try:
            return json.loads(raw)
        except json.JSONDecodeError as exc:
            raise JiraTicketError(f"{method.upper()} {url} returned non-JSON output") from exc

    def list_fields(self) -> list[dict]:
        payload = self._request("GET", "/rest/api/2/field")
        return payload if isinstance(payload, list) else []

    def search(self, *, jql: str, fields: str, max_results: int) -> dict[str, Any]:
        if max_results < 0:
            raise JiraTicketError("max_results must be >= 0")

        start_at = 0
        fetched: list[dict[str, Any]] = []
        total: Optional[int] = None

        while True:
            page_size = DEFAULT_SEARCH_PAGE_SIZE if max_results == 0 else min(DEFAULT_SEARCH_PAGE_SIZE, max_results - len(fetched))
            if page_size <= 0:
                break

            payload = self._request(
                "GET",
                "/rest/api/2/search",
                params={
                    "jql": jql,
                    "startAt": start_at,
                    "maxResults": page_size,
                    "fields": fields,
                },
            )
            issues = payload.get("issues", []) if isinstance(payload, dict) else []
            if not isinstance(issues, list):
                issues = []

            if total is None and isinstance(payload, dict):
                try:
                    total = int(payload.get("total"))
                except Exception:
                    total = None

            fetched.extend(issue for issue in issues if isinstance(issue, dict))
            start_at += len(issues)

            if not issues:
                break
            if total is not None and start_at >= total:
                break
            if len(issues) < page_size:
                break

        return {
            "jql": jql,
            "issues": fetched,
            "startAt": 0,
            "maxResults": len(fetched),
            "total": total if total is not None else len(fetched),
        }

    def get_issue(self, key: str, *, fields: str = DEFAULT_TICKET_FIELDS, expand: str = "changelog") -> dict[str, Any]:
        payload = self._request(
            "GET",
            f"/rest/api/2/issue/{key}",
            params={"fields": fields, "expand": expand},
        )
        if not isinstance(payload, dict):
            raise JiraTicketError(f"issue payload for {key} was not an object")
        return payload

    def get_editmeta(self, key: str) -> dict[str, Any]:
        payload = self._request("GET", f"/rest/api/2/issue/{key}/editmeta")
        if not isinstance(payload, dict):
            raise JiraTicketError(f"edit metadata payload for {key} was not an object")
        return payload

    def get_comment(self, key: str, comment_id: str) -> dict[str, Any]:
        payload = self._request("GET", f"/rest/api/2/issue/{key}/comment/{comment_id}")
        if not isinstance(payload, dict):
            raise JiraTicketError(f"comment payload for {key}/{comment_id} was not an object")
        return payload

    def get_comments(self, key: str, *, max_results: int = 0) -> dict[str, Any]:
        start_at = 0
        fetched: list[dict[str, Any]] = []
        total: Optional[int] = None

        while True:
            page_size = DEFAULT_COMMENT_PAGE_SIZE if max_results == 0 else min(DEFAULT_COMMENT_PAGE_SIZE, max_results - len(fetched))
            if page_size <= 0:
                break

            payload = self._request(
                "GET",
                f"/rest/api/2/issue/{key}/comment",
                params={"startAt": start_at, "maxResults": page_size},
            )
            comments = payload.get("comments", []) if isinstance(payload, dict) else []
            if not isinstance(comments, list):
                comments = []

            if total is None and isinstance(payload, dict):
                try:
                    total = int(payload.get("total"))
                except Exception:
                    total = None

            fetched.extend(comment for comment in comments if isinstance(comment, dict))
            start_at += len(comments)

            if not comments:
                break
            if total is not None and start_at >= total:
                break
            if len(comments) < page_size:
                break

        return {
            "issueKey": key,
            "comments": fetched,
            "startAt": 0,
            "maxResults": len(fetched),
            "total": total if total is not None else len(fetched),
        }

    def add_comment(self, key: str, *, text: str) -> dict[str, Any]:
        payload = self._request("POST", f"/rest/api/2/issue/{key}/comment", body={"body": text})
        if not isinstance(payload, dict):
            raise JiraTicketError(f"comment create payload for {key} was not an object")
        return payload

    def update_issue(self, key: str, *, body: dict[str, Any]) -> dict[str, Any]:
        payload = self._request("PUT", f"/rest/api/2/issue/{key}", body=body)
        if not isinstance(payload, dict):
            raise JiraTicketError(f"issue update payload for {key} was not an object")
        return payload

    def get_transitions(self, key: str) -> list[dict[str, Any]]:
        payload = self._request("GET", f"/rest/api/2/issue/{key}/transitions")
        transitions = payload.get("transitions", []) if isinstance(payload, dict) else []
        return transitions if isinstance(transitions, list) else []

    def transition_issue(self, key: str, *, transition_id: str) -> dict[str, Any]:
        payload = self._request(
            "POST",
            f"/rest/api/2/issue/{key}/transitions",
            body={"transition": {"id": transition_id}},
        )
        if not isinstance(payload, dict):
            raise JiraTicketError(f"transition payload for {key} was not an object")
        return payload


def _normalize_status_name(value: str) -> str:
    return " ".join(value.lower().split())


def _find_transition_for_status(
    transitions: list[dict[str, Any]], target_status: str
) -> Optional[dict[str, Any]]:
    normalized_target = _normalize_status_name(target_status)
    for transition in transitions:
        if not isinstance(transition, dict):
            continue
        to_payload = transition.get("to", {})
        to_name = to_payload.get("name") if isinstance(to_payload, dict) else None
        transition_name = transition.get("name")
        candidates = [to_name, transition_name]
        for candidate in candidates:
            if isinstance(candidate, str) and _normalize_status_name(candidate) == normalized_target:
                return transition
    return None


def _augment_issue_with_field_names(issue: dict[str, Any], field_map: dict[str, str]) -> dict[str, Any]:
    fields = issue.get("fields", {})
    if isinstance(fields, dict):
        issue["_named_fields"] = _issue_fields_by_name(fields, field_map)
    issue["_field_map"] = field_map
    return issue


def _comment_reply_body(reference_comment: dict[str, Any], reply_text: str, quote_original: bool) -> str:
    author = (
        reference_comment.get("author", {}).get("displayName")
        if isinstance(reference_comment.get("author"), dict)
        else None
    )
    created = reference_comment.get("created")
    comment_id = reference_comment.get("id")

    header = f"Replying to comment {comment_id}"
    if author:
        header += f" by {author}"
    if created:
        header += f" from {created}"

    body = f"{header}:\n\n{reply_text}"
    if quote_original:
        original = str(reference_comment.get("body") or "").strip()
        if original:
            body += f"\n\nQuoted original comment:\n\n{original}"
    return body


def _issue_labels(issue: dict[str, Any]) -> list[str]:
    fields = issue.get("fields", {})
    labels = fields.get("labels", []) if isinstance(fields, dict) else []
    if not isinstance(labels, list):
        raise JiraTicketError("issue labels field had an unexpected shape")
    normalized = [str(label).strip() for label in labels if str(label).strip()]
    return _dedupe_preserve_order(normalized)


def _resolve_jira_label_mutation(
    current_labels: list[str],
    *,
    add_labels: Optional[list[str]] = None,
    remove_labels: Optional[list[str]] = None,
    set_labels: Optional[list[str]] = None,
) -> dict[str, Any]:
    add_labels = _dedupe_preserve_order(add_labels or [])
    remove_labels = _dedupe_preserve_order(remove_labels or [])

    if set_labels is not None:
        resolved_labels = _dedupe_preserve_order(set_labels)
        return {
            "body": {"fields": {"labels": resolved_labels}},
            "changed": resolved_labels != current_labels,
            "resolvedLabels": resolved_labels,
        }

    current_set = set(current_labels)
    add_ops = [label for label in add_labels if label not in current_set]
    remove_ops = [label for label in remove_labels if label in current_set]
    resolved_labels = [label for label in current_labels if label not in set(remove_ops)] + add_ops

    return {
        "body": {
            "update": {
                "labels": [{"remove": label} for label in remove_ops]
                + [{"add": label} for label in add_ops]
            }
        },
        "changed": bool(add_ops or remove_ops),
        "resolvedLabels": resolved_labels,
        "appliedAdd": add_ops,
        "appliedRemove": remove_ops,
    }


def _label_editmeta(editmeta: dict[str, Any]) -> dict[str, Any]:
    fields = editmeta.get("fields", {})
    if not isinstance(fields, dict):
        raise JiraTicketError("issue edit metadata had an unexpected shape")
    label_meta = fields.get("labels")
    if not isinstance(label_meta, dict):
        raise JiraTicketError(
            "Jira issue labels are not editable for this ticket. "
            "The labels field is not present in the issue edit metadata."
        )

    operations = label_meta.get("operations", [])
    if not isinstance(operations, list):
        operations = []
    normalized_operations = [str(operation).strip().lower() for operation in operations if str(operation).strip()]
    if not any(operation in {"add", "set", "remove"} for operation in normalized_operations):
        raise JiraTicketError(
            "Jira issue labels are not editable for this ticket. "
            "The labels field does not expose add/set/remove operations."
        )
    return label_meta


def _editable_named_field_meta(editmeta: dict[str, Any], field_name: str) -> dict[str, Any]:
    fields = editmeta.get("fields", {})
    if not isinstance(fields, dict):
        raise JiraTicketError("issue edit metadata had an unexpected shape")

    match_field_id: Optional[str] = None
    match_meta: Optional[dict[str, Any]] = None
    for field_id, field_meta in fields.items():
        if not isinstance(field_meta, dict):
            continue
        if str(field_meta.get("name") or "").strip() != field_name:
            continue
        match_field_id = field_id
        match_meta = field_meta
        break

    if match_field_id is None or match_meta is None:
        raise JiraTicketError(
            f"Jira issue field '{field_name}' is not editable for this ticket. "
            "The field is not present in the issue edit metadata."
        )

    operations = match_meta.get("operations", [])
    if not isinstance(operations, list):
        operations = []
    normalized_operations = [str(operation).strip().lower() for operation in operations if str(operation).strip()]
    if "set" not in normalized_operations:
        raise JiraTicketError(
            f"Jira issue field '{field_name}' is not editable for this ticket. "
            "The field does not expose set operations."
        )

    return {
        "fieldId": match_field_id,
        "fieldName": field_name,
        "operations": operations,
        "required": match_meta.get("required"),
        "schema": match_meta.get("schema"),
    }


def _resolve_jira_resolution_details_mutation(
    editmeta: dict[str, Any],
    current_issue_fields: dict[str, Any],
    *,
    root_cause_description: Optional[str] = None,
    resolution_description: Optional[str] = None,
    status_update: Optional[str] = None,
) -> dict[str, Any]:
    requested_updates = {
        "rootCauseDescription": root_cause_description,
        "resolutionDescription": resolution_description,
        "statusUpdate": status_update,
    }
    requested_updates = {key: value for key, value in requested_updates.items() if value is not None}
    if not requested_updates:
        raise JiraTicketError(
            "provide at least one of --root-cause-description, "
            "--resolution-description, or --status-update"
        )

    body_fields: dict[str, Any] = {}
    current_values: dict[str, Any] = {}
    resolved_values: dict[str, Any] = {}
    field_map: dict[str, Any] = {}

    for logical_name, requested_value in requested_updates.items():
        jira_field_name = JIRA_RESOLUTION_DETAIL_FIELDS[logical_name]
        field_meta = _editable_named_field_meta(editmeta, jira_field_name)
        field_id = str(field_meta["fieldId"])
        current_value = current_issue_fields.get(field_id)

        body_fields[field_id] = requested_value
        current_values[logical_name] = current_value
        resolved_values[logical_name] = requested_value
        field_map[logical_name] = field_meta

    return {
        "body": {"fields": body_fields},
        "changed": any(
            current_issue_fields.get(field_id) != requested_value
            for field_id, requested_value in body_fields.items()
        ),
        "currentValues": current_values,
        "resolvedValues": resolved_values,
        "requestedUpdates": requested_updates,
        "fieldMap": field_map,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Read and write Jira issues using configured Jira auth")
    parser.add_argument("--jira-instance", choices=sorted(JIRA_INSTANCE_ENV), help="Jira target, default sd")
    parser.add_argument("--env-file", help="Jira dotenv file override; defaults to ~/.env for sd and ~/.env.jira-oci for oci")
    parser.add_argument("--base-url", help="Jira base URL override")
    parser.add_argument("--token", help="Jira token override")

    auth_parent = argparse.ArgumentParser(add_help=False)
    auth_parent.add_argument(
        "--jira-instance",
        choices=sorted(JIRA_INSTANCE_ENV),
        default=argparse.SUPPRESS,
        help="Jira target, default sd",
    )
    auth_parent.add_argument(
        "--env-file",
        default=argparse.SUPPRESS,
        help="Jira dotenv file override; defaults to ~/.env for sd and ~/.env.jira-oci for oci",
    )
    auth_parent.add_argument("--base-url", default=argparse.SUPPRESS, help="Jira base URL override")
    auth_parent.add_argument("--token", default=argparse.SUPPRESS, help="Jira token override")

    subparsers = parser.add_subparsers(dest="command", required=True)

    search = subparsers.add_parser("search", parents=[auth_parent], help="Search Jira with JQL")
    search.add_argument("--jql", required=True, help="JQL expression to run")
    search.add_argument("--fields", default=DEFAULT_SEARCH_FIELDS, help="Comma-separated Jira fields")
    search.add_argument("--max-results", type=int, default=100, help="0 fetches all pages")
    search.add_argument(
        "--include-field-map",
        action="store_true",
        help="Resolve Jira field ids and attach _field_map and _named_fields to each issue",
    )

    ticket = subparsers.add_parser("ticket", parents=[auth_parent], help="Fetch one Jira issue with all fields")
    ticket.add_argument("ticket_key")
    ticket.add_argument("--fields", default=DEFAULT_TICKET_FIELDS, help="Jira fields spec, default *all")
    ticket.add_argument("--expand", default="changelog", help="Issue expansion, default changelog")

    comments = subparsers.add_parser("comments", parents=[auth_parent], help="List Jira comments for an issue")
    comments.add_argument("ticket_key")
    comments.add_argument("--max-results", type=int, default=0, help="0 fetches all pages")

    activities = subparsers.add_parser("activities", parents=[auth_parent], help="Read Jira changelog histories for an issue")
    activities.add_argument("ticket_key")

    bundle = subparsers.add_parser("bundle", parents=[auth_parent], help="Fetch issue, comments, and activities in one payload")
    bundle.add_argument("ticket_key")
    bundle.add_argument("--fields", default=DEFAULT_TICKET_FIELDS, help="Jira fields spec, default *all")

    comment_add = subparsers.add_parser("comment-add", parents=[auth_parent], help="Add a new Jira comment")
    comment_add.add_argument("ticket_key")
    comment_group = comment_add.add_mutually_exclusive_group(required=True)
    comment_group.add_argument("--text", help="Comment body text")
    comment_group.add_argument("--text-file", help="Read comment body from a file")
    comment_group.add_argument("--stdin", action="store_true", help="Read comment body from stdin")
    comment_add.add_argument("--dry-run", action="store_true", help="Show request payload without posting")

    comment_reply = subparsers.add_parser(
        "comment-reply",
        parents=[auth_parent],
        help="Post a reply-style Jira comment that references an existing comment id",
    )
    comment_reply.add_argument("ticket_key")
    comment_reply.add_argument("--comment-id", required=True, help="Existing Jira comment id to reference")
    reply_group = comment_reply.add_mutually_exclusive_group(required=True)
    reply_group.add_argument("--text", help="Reply body text")
    reply_group.add_argument("--text-file", help="Read reply body from a file")
    reply_group.add_argument("--stdin", action="store_true", help="Read reply body from stdin")
    comment_reply.add_argument(
        "--quote-original",
        action="store_true",
        help="Append the original comment body to the generated reply text",
    )
    comment_reply.add_argument("--dry-run", action="store_true", help="Show request payload without posting")

    transition_status = subparsers.add_parser(
        "transition-status",
        parents=[auth_parent],
        help="Transition a Jira issue to a target status when a matching workflow transition exists",
    )
    transition_status.add_argument("ticket_key")
    transition_status.add_argument("--target-status", required=True, help="Target Jira status name, for example 'In Progress'")
    transition_status.add_argument("--dry-run", action="store_true", help="Show the resolved transition without posting")

    labels_add = subparsers.add_parser(
        "labels-add",
        parents=[auth_parent],
        help="Add one or more Jira labels without disturbing existing labels",
    )
    labels_add.add_argument("ticket_key")
    labels_add.add_argument("--labels", required=True, help="Comma-separated Jira labels to add")
    labels_add.add_argument("--dry-run", action="store_true", help="Show the resolved update without posting")

    labels_remove = subparsers.add_parser(
        "labels-remove",
        parents=[auth_parent],
        help="Remove one or more Jira labels when present",
    )
    labels_remove.add_argument("ticket_key")
    labels_remove.add_argument("--labels", required=True, help="Comma-separated Jira labels to remove")
    labels_remove.add_argument("--dry-run", action="store_true", help="Show the resolved update without posting")

    labels_set = subparsers.add_parser(
        "labels-set",
        parents=[auth_parent],
        help="Replace Jira labels with an exact comma-separated set",
    )
    labels_set.add_argument("ticket_key")
    labels_set.add_argument(
        "--labels",
        default="",
        help="Comma-separated Jira labels to keep; an empty value clears all labels",
    )
    labels_set.add_argument("--dry-run", action="store_true", help="Show the resolved update without posting")

    resolution_details = subparsers.add_parser(
        "resolution-details-update",
        parents=[auth_parent],
        help="Update short Jira investigation summary fields when the issue exposes editable companion fields",
    )
    resolution_details.add_argument("ticket_key")
    resolution_details.add_argument(
        "--root-cause-description",
        help="Brief root cause summary for the Jira Root Cause Description field",
    )
    resolution_details.add_argument(
        "--resolution-description",
        help="Brief remediation or resolution summary for the Jira Resolution Description field",
    )
    resolution_details.add_argument(
        "--status-update",
        help="Brief current-status summary for the Jira Status Update field",
    )
    resolution_details.add_argument(
        "--dry-run",
        action="store_true",
        help="Show the resolved field update without posting",
    )

    return parser


def main(argv: Optional[list[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    base_url, token = _resolve_jira_auth(
        instance=args.jira_instance or "sd",
        base_url=args.base_url,
        token=args.token,
        env_file=args.env_file,
    )
    client = JiraClient(base_url=base_url, token=token)

    if args.command == "search":
        payload = client.search(jql=args.jql, fields=args.fields, max_results=args.max_results)
        if args.include_field_map:
            field_map = _field_map_by_name(client.list_fields())
            for issue in payload.get("issues", []) or []:
                if isinstance(issue, dict):
                    _augment_issue_with_field_names(issue, field_map)
        _json_dump(payload)
        return 0

    if args.command == "ticket":
        issue = client.get_issue(args.ticket_key, fields=args.fields, expand=args.expand)
        field_map = _field_map_by_name(client.list_fields())
        _json_dump(_augment_issue_with_field_names(issue, field_map))
        return 0

    if args.command == "comments":
        _json_dump(client.get_comments(args.ticket_key, max_results=args.max_results))
        return 0

    if args.command == "activities":
        issue = client.get_issue(args.ticket_key, fields="summary,status,updated", expand="changelog")
        payload = {
            "issueKey": issue.get("key"),
            "issueId": issue.get("id"),
            "changelog": issue.get("changelog", {}),
        }
        _json_dump(payload)
        return 0

    if args.command == "bundle":
        issue = client.get_issue(args.ticket_key, fields=args.fields, expand="changelog")
        field_map = _field_map_by_name(client.list_fields())
        comments = client.get_comments(args.ticket_key, max_results=0)
        payload = {
            "issue": _augment_issue_with_field_names(issue, field_map),
            "comments": comments,
            "activities": issue.get("changelog", {}),
        }
        _json_dump(payload)
        return 0

    if args.command == "comment-add":
        text = _read_comment_text(args)
        payload = {"issueKey": args.ticket_key, "body": text}
        if args.dry_run:
            _json_dump({"dry_run": True, "request": payload})
            return 0
        _json_dump(client.add_comment(args.ticket_key, text=text))
        return 0

    if args.command == "comment-reply":
        reply_text = _read_comment_text(args)
        reference_comment = client.get_comment(args.ticket_key, args.comment_id)
        body = _comment_reply_body(reference_comment, reply_text, args.quote_original)
        payload = {
            "issueKey": args.ticket_key,
            "commentId": args.comment_id,
            "body": body,
        }
        if args.dry_run:
            payload["dry_run"] = True
            _json_dump(payload)
            return 0
        _json_dump(client.add_comment(args.ticket_key, text=body))
        return 0

    if args.command == "transition-status":
        issue = client.get_issue(args.ticket_key, fields="summary,status,updated", expand="")
        current_status = (
            issue.get("fields", {}).get("status", {}).get("name")
            if isinstance(issue.get("fields"), dict)
            else None
        )
        payload: dict[str, Any] = {
            "issueKey": args.ticket_key,
            "currentStatus": current_status,
            "targetStatus": args.target_status,
        }
        if isinstance(current_status, str) and _normalize_status_name(current_status) == _normalize_status_name(args.target_status):
            payload["noop"] = True
            payload["reason"] = "issue already in target status"
            _json_dump(payload)
            return 0

        transitions = client.get_transitions(args.ticket_key)
        match = _find_transition_for_status(transitions, args.target_status)
        payload["availableTransitions"] = [
            {
                "id": transition.get("id"),
                "name": transition.get("name"),
                "to": transition.get("to", {}).get("name") if isinstance(transition.get("to"), dict) else None,
            }
            for transition in transitions
            if isinstance(transition, dict)
        ]
        if not match:
            raise JiraTicketError(
                f"no Jira transition to status '{args.target_status}' was found for {args.ticket_key}"
            )
        payload["resolvedTransition"] = {
            "id": match.get("id"),
            "name": match.get("name"),
            "to": match.get("to", {}).get("name") if isinstance(match.get("to"), dict) else None,
        }
        if args.dry_run:
            payload["dry_run"] = True
            _json_dump(payload)
            return 0
        client.transition_issue(args.ticket_key, transition_id=str(match.get("id")))
        payload["transitioned"] = True
        _json_dump(payload)
        return 0

    if args.command in {"labels-add", "labels-remove", "labels-set"}:
        issue = client.get_issue(args.ticket_key, fields="summary,status,labels,updated", expand="")
        editmeta = client.get_editmeta(args.ticket_key)
        label_meta = _label_editmeta(editmeta)
        current_labels = _issue_labels(issue)
        payload: dict[str, Any] = {
            "issueKey": args.ticket_key,
            "currentLabels": current_labels,
            "labelOperations": label_meta.get("operations", []),
        }

        requested_labels = _normalize_csv(args.labels)
        if args.command == "labels-add":
            mutation = _resolve_jira_label_mutation(current_labels, add_labels=requested_labels)
            payload["requestedAdd"] = requested_labels
        elif args.command == "labels-remove":
            mutation = _resolve_jira_label_mutation(current_labels, remove_labels=requested_labels)
            payload["requestedRemove"] = requested_labels
        else:
            mutation = _resolve_jira_label_mutation(current_labels, set_labels=requested_labels)
            payload["requestedLabels"] = requested_labels

        payload["resolvedLabels"] = mutation["resolvedLabels"]
        if "appliedAdd" in mutation:
            payload["appliedAdd"] = mutation["appliedAdd"]
        if "appliedRemove" in mutation:
            payload["appliedRemove"] = mutation["appliedRemove"]

        if not mutation["changed"]:
            payload["noop"] = True
            payload["reason"] = "issue labels already match requested mutation"
            _json_dump(payload)
            return 0

        if args.dry_run:
            payload["dry_run"] = True
            payload["request"] = {
                "method": "PUT",
                "path": f"/rest/api/2/issue/{args.ticket_key}",
                "body": mutation["body"],
            }
            _json_dump(payload)
            return 0

        client.update_issue(args.ticket_key, body=mutation["body"])
        payload["updated"] = True
        _json_dump(payload)
        return 0

    if args.command == "resolution-details-update":
        editmeta = client.get_editmeta(args.ticket_key)
        requested_field_meta = []
        for logical_name, jira_field_name in JIRA_RESOLUTION_DETAIL_FIELDS.items():
            requested_value = {
                "rootCauseDescription": args.root_cause_description,
                "resolutionDescription": args.resolution_description,
                "statusUpdate": args.status_update,
            }[logical_name]
            if requested_value is None:
                continue
            requested_field_meta.append(_editable_named_field_meta(editmeta, jira_field_name))

        issue_fields = _csv_join(
            ["summary", "status", "updated"]
            + [str(field_meta["fieldId"]) for field_meta in requested_field_meta]
        )
        issue = client.get_issue(args.ticket_key, fields=issue_fields, expand="")
        issue_fields_payload = issue.get("fields", {})
        if not isinstance(issue_fields_payload, dict):
            raise JiraTicketError("issue fields payload had an unexpected shape")

        mutation = _resolve_jira_resolution_details_mutation(
            editmeta,
            issue_fields_payload,
            root_cause_description=args.root_cause_description,
            resolution_description=args.resolution_description,
            status_update=args.status_update,
        )
        current_status = (
            issue_fields_payload.get("status", {}).get("name")
            if isinstance(issue_fields_payload.get("status"), dict)
            else None
        )
        payload = {
            "issueKey": args.ticket_key,
            "currentStatus": current_status,
            "requestedUpdates": mutation["requestedUpdates"],
            "currentValues": mutation["currentValues"],
            "resolvedValues": mutation["resolvedValues"],
            "fieldMap": mutation["fieldMap"],
        }

        if not mutation["changed"]:
            payload["noop"] = True
            payload["reason"] = "issue resolution detail fields already match requested values"
            _json_dump(payload)
            return 0

        if args.dry_run:
            payload["dry_run"] = True
            payload["request"] = {
                "method": "PUT",
                "path": f"/rest/api/2/issue/{args.ticket_key}",
                "body": mutation["body"],
            }
            _json_dump(payload)
            return 0

        client.update_issue(args.ticket_key, body=mutation["body"])
        payload["updated"] = True
        _json_dump(payload)
        return 0

    raise JiraTicketError(f"unsupported command: {args.command}")


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except JiraTicketError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
