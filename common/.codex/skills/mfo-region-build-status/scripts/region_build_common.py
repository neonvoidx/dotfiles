#!/usr/bin/env python3
"""Shared helpers for the MFO region-build status skill."""

from __future__ import annotations

import json
from copy import deepcopy
from typing import Any

SCHEMA_VERSION = 1

LOOKUP_STATE_ALIASES = {
    "resolved": "resolved",
    "auth_blocked": "auth_blocked",
    "visibility_blocked": "visibility_blocked",
    "not_found": "not_found",
    "unknown": "unknown",
    "authblocked": "auth_blocked",
    "visibilityblocked": "visibility_blocked",
}


def _coerce_list(value: Any) -> list[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]
    if isinstance(value, str):
        text = value.strip()
        return [text] if text else []
    return [str(value).strip()]


def _first(mapping: dict[str, Any], *keys: str, default: Any = None) -> Any:
    for key in keys:
        if key in mapping and mapping[key] is not None:
            return mapping[key]
    return default


def normalize_lookup_state(value: Any) -> str:
    if value is None:
        return "unknown"
    text = str(value).strip().lower().replace("-", "_").replace(" ", "_")
    return LOOKUP_STATE_ALIASES.get(text, "unknown")


def normalize_producer_ref(raw: Any, fallback_region: str | None = None) -> dict[str, Any]:
    if not isinstance(raw, dict):
        raise ValueError(f"Producer reference must be an object, got {type(raw).__name__}")
    return {
        "project": str(_first(raw, "project", default="")).strip(),
        "flock": str(_first(raw, "flock", default="")).strip(),
        "region": str(_first(raw, "region", default=fallback_region or "")).strip(),
        "phonebook_id": str(_first(raw, "phonebook_id", "phonebookId", default="")).strip(),
        "page_url": str(_first(raw, "page_url", "pageUrl", default="")).strip(),
        "role": str(_first(raw, "role", default="")).strip(),
    }


def normalize_lookup_entry(raw: Any, fallback_region: str | None = None) -> dict[str, Any]:
    if isinstance(raw, list):
        return {
            "lookup_state": "resolved",
            "producers": [normalize_producer_ref(item, fallback_region) for item in raw],
        }
    if not isinstance(raw, dict):
        return {"lookup_state": "unknown", "producers": []}
    producers = _first(raw, "producers", "producer_refs", "producerRefs", default=[])
    return {
        "lookup_state": normalize_lookup_state(
            _first(raw, "lookup_state", "lookupState", "state", default="resolved" if producers else "unknown")
        ),
        "producers": [normalize_producer_ref(item, fallback_region) for item in producers],
    }


def _normalize_state(value: Any) -> str:
    return str(value or "unknown").strip().lower().replace(" ", "_")


def _phase_capabilities_from_consumed(raw: dict[str, Any]) -> tuple[list[str], list[str], list[str]]:
    consumed = _first(raw, "capabilitiesConsumed", "capabilities_consumed", default=None)
    if not isinstance(consumed, list):
        return [], [], []

    satisfied: list[str] = []
    unsatisfied: list[str] = []
    optional: list[str] = []
    for item in consumed:
        if not isinstance(item, dict) or item.get("ignored"):
            continue
        name = str(_first(item, "capabilityName", "capability_name", "name", default="")).strip()
        if not name:
            continue
        if item.get("satisfied"):
            satisfied.append(name)
        elif item.get("required", True):
            unsatisfied.append(name)
        else:
            optional.append(name)
    return satisfied, unsatisfied, optional


def normalize_phase(raw: Any) -> dict[str, Any]:
    if not isinstance(raw, dict):
        raise ValueError(f"Phase must be an object, got {type(raw).__name__}")
    capability_block = _first(raw, "capabilities", "capability_dependencies", "capabilityDependencies", default={})
    if not isinstance(capability_block, dict):
        capability_block = {}
    consumed_satisfied, consumed_unsatisfied, consumed_optional = _phase_capabilities_from_consumed(raw)
    satisfied = _first(raw, "satisfied_capabilities", "satisfiedCapabilities", "satisfied", default=None)
    unsatisfied = _first(raw, "unsatisfied_capabilities", "unsatisfiedCapabilities", "unsatisfied", default=None)
    optional = _first(raw, "optional_capabilities", "optionalCapabilities", "optional", default=None)
    if satisfied is None:
        satisfied = _first(
            capability_block, "satisfied_capabilities", "satisfiedCapabilities", "satisfied", default=consumed_satisfied
        )
    if unsatisfied is None:
        unsatisfied = _first(
            capability_block,
            "unsatisfied_capabilities",
            "unsatisfiedCapabilities",
            "unsatisfied",
            default=consumed_unsatisfied,
        )
    if optional is None:
        optional = _first(
            capability_block, "optional_capabilities", "optionalCapabilities", "optional", default=consumed_optional
        )
    last_pass = _first(raw, "last_pass", "lastPass", default={})
    if not isinstance(last_pass, dict):
        last_pass = {}
    raw_state = _first(raw, "state", "status", default=None)
    last_pass_state = _first(last_pass, "state", "status", default="")
    state = _normalize_state(raw_state or last_pass_state)
    if state == "unknown" and _coerce_list(unsatisfied):
        state = "not_run"
    return {
        "name": str(_first(raw, "name", "phase_name", "phaseName", default="")).strip(),
        "change_type": str(_first(raw, "change_type", "changeType", "type", default="")).strip(),
        "state": state,
        "last_pass_state": _normalize_state(last_pass_state) if last_pass_state else "",
        "satisfied_capabilities": _coerce_list(satisfied),
        "unsatisfied_capabilities": _coerce_list(unsatisfied),
        "optional_capabilities": _coerce_list(optional),
        "produced_capabilities": _coerce_list(
            _first(raw, "produced_capabilities", "producedCapabilities", "capabilitiesProduced", default=[])
        ),
    }


def normalize_node(raw: Any) -> dict[str, Any]:
    if not isinstance(raw, dict):
        raise ValueError(f"Node must be an object, got {type(raw).__name__}")
    region = str(_first(raw, "region", "publicRegionName", default="")).strip()
    phases = [normalize_phase(item) for item in _first(raw, "phases", default=[])]
    producer_capabilities_raw = _first(
        raw, "producer_capabilities", "producers_by_capability", "producersByCapability", default={}
    )
    if not isinstance(producer_capabilities_raw, dict):
        producer_capabilities_raw = {}
    producer_capabilities = {
        str(capability).strip(): normalize_lookup_entry(entry, region)
        for capability, entry in producer_capabilities_raw.items()
        if str(capability).strip()
    }
    notes = _coerce_list(_first(raw, "notes", default=[]))
    discovered_roles = _coerce_list(_first(raw, "discovered_roles", "discoveredRoles", default=[]))
    node = {
        "project": str(_first(raw, "project", "projectName", default="")).strip(),
        "flock": str(_first(raw, "flock", "flockName", default="")).strip(),
        "region": region,
        "phonebook_id": str(_first(raw, "phonebook_id", "phonebookId", default="")).strip(),
        "page_url": str(_first(raw, "page_url", "pageUrl", default="")).strip(),
        "overall_state": _normalize_state(
            _first(raw, "overall_state", "overallState", "state", "flockStatus", default="unknown")
        ),
        "flock_status": str(_first(raw, "flock_status", "flockStatus", default="")).strip(),
        "completion_status": str(
            _first(raw, "completion_status", "flockCompletionStatus", "flock_completion_status", default="")
        ).strip(),
        "infrastructure_version_set": _first(
            raw, "infrastructure_version_set", "infrastructureVersionSet", default={}
        ),
        "application_version_set": _first(raw, "application_version_set", "applicationVersionSet", default={}),
        "phases": phases,
        "produced_capabilities": _coerce_list(
            _first(raw, "produced_capabilities", "producedCapabilities", default=[])
        ),
        "pending_published_capabilities": _coerce_list(
            _first(raw, "pending_published_capabilities", "pendingPublishedCapabilities", default=[])
        ),
        "producer_capabilities": producer_capabilities,
        "discovered_roles": discovered_roles,
        "notes": notes,
    }
    return node


def normalize_graph(raw: Any) -> dict[str, Any]:
    if isinstance(raw, list):
        graph = {"schema_version": SCHEMA_VERSION, "nodes": raw}
    elif isinstance(raw, dict):
        graph = deepcopy(raw)
    else:
        raise ValueError(f"Graph payload must be an object or list, got {type(raw).__name__}")

    nodes_raw = _first(graph, "nodes", default=None)
    if nodes_raw is None:
        nodes_raw = [graph]
    if not isinstance(nodes_raw, list):
        raise ValueError("Graph `nodes` must be a list")

    request_raw = _first(graph, "request", default={})
    if not isinstance(request_raw, dict):
        request_raw = {}

    normalized_nodes = [normalize_node(item) for item in nodes_raw]
    normalized = {
        "schema_version": SCHEMA_VERSION,
        "request": {
            "region": str(_first(request_raw, "region", default="")).strip(),
            "project": str(_first(request_raw, "project", default="")).strip(),
            "flock": str(_first(request_raw, "flock", default="")).strip(),
            "phonebook_id": str(_first(request_raw, "phonebook_id", "phonebookId", default="")).strip(),
        },
        "nodes": normalized_nodes,
    }
    return normalized


def node_key(node_or_ref: dict[str, Any]) -> str:
    project = str(node_or_ref.get("project", "")).strip()
    flock = str(node_or_ref.get("flock", "")).strip()
    region = str(node_or_ref.get("region", "")).strip()
    return f"{project}|{flock}|{region}"


def dump_json(data: Any) -> str:
    return json.dumps(data, indent=2, sort_keys=False) + "\n"
