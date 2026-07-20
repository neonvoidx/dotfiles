#!/usr/bin/env python3
"""Trace normalized region-build capability dependencies."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any

from region_build_common import dump_json, node_key, normalize_graph


TERMINAL_PRIORITY = {
    "orchestration error": 8,
    "cycle detected": 7,
    "producer failed": 6,
    "auth/visibility blocked": 5,
    "upstream capability missing": 4,
    "producer blocked": 3,
    "producer in progress": 2,
    "not triggered": 1,
    "published": 0,
}

FAILED_STATES = {
    "aborted",
    "canceled",
    "cancelled",
    "error",
    "errored",
    "failed",
    "failure",
    "timed_out",
    "timeout",
}

IN_PROGRESS_STATES = {
    "active",
    "building",
    "deploying",
    "executing",
    "in_progress",
    "inprogress",
    "pending",
    "processing",
    "queued",
    "running",
    "scheduled",
    "started",
    "triggered",
}


@dataclass
class Graph:
    nodes: dict[str, dict[str, Any]]

    @classmethod
    def from_payload(cls, payload: dict[str, Any]) -> "Graph":
        return cls({node_key(node): node for node in payload["nodes"]})

    def get(self, ref: dict[str, Any]) -> dict[str, Any] | None:
        return self.nodes.get(node_key(ref))


def aggregate_capabilities(phases: list[dict[str, Any]], key: str) -> list[str]:
    values: list[str] = []
    seen: set[str] = set()
    for phase in phases:
        for capability in phase.get(key, []):
            if capability not in seen:
                seen.add(capability)
                values.append(capability)
    return values


def is_ignored_phase(phase: dict[str, Any], include_ohe_vibe: bool = False) -> bool:
    if include_ohe_vibe:
        return False
    return str(phase.get("name", "")).lower().startswith("ohe_vibe")


def reportable_phases(phases: list[dict[str, Any]], include_ohe_vibe: bool = False) -> list[dict[str, Any]]:
    return [phase for phase in phases if not is_ignored_phase(phase, include_ohe_vibe)]


def phase_label(phase: dict[str, Any]) -> str:
    change_type = phase.get("change_type")
    if change_type:
        return f"{phase['name']} {change_type}"
    return phase["name"]


def format_capabilities(values: list[str], limit: int | None = None) -> str:
    if not values:
        return "none"
    shown = values if limit is None else values[:limit]
    suffix = "" if limit is None or len(values) <= limit else f", +{len(values) - limit} more"
    return ", ".join(f"`{value}`" for value in shown) + suffix


def format_ref(ref: dict[str, Any] | None) -> str:
    if not ref:
        return "none"
    project = ref.get("project") or "unknown-project"
    flock = ref.get("flock") or "unknown-flock"
    return f"`{project} / {flock}`"


def phase_has_successful_publication(phase: dict[str, Any], capability: str) -> bool:
    return capability in phase.get("produced_capabilities", []) and phase.get("state") in {"successful", "ready", "succeeded"}


def node_has_published_capability(node: dict[str, Any], capability: str) -> bool:
    if capability in node.get("produced_capabilities", []):
        return True
    return any(phase_has_successful_publication(phase, capability) for phase in reportable_phases(node["phases"]))


def markdown_row(values: list[str]) -> str:
    return "| " + " | ".join(value.replace("\n", " ").replace("|", "\\|") for value in values) + " |"


def normalize_status_token(value: Any) -> str:
    return str(value or "").strip().lower().replace("-", "_").replace(" ", "_")


def node_state_terms(node: dict[str, Any], phases: list[dict[str, Any]] | None = None) -> set[str]:
    if phases is None:
        phases = reportable_phases(node["phases"])
    terms = {
        normalize_status_token(node.get("overall_state")),
        normalize_status_token(node.get("flock_status")),
        normalize_status_token(node.get("completion_status")),
    }
    for phase in phases:
        terms.add(normalize_status_token(phase.get("state")))
        terms.add(normalize_status_token(phase.get("last_pass_state")))
    return {term for term in terms if term}


def classify_node_state(node: dict[str, Any]) -> str:
    phases = reportable_phases(node["phases"])
    terms = node_state_terms(node, phases)
    if normalize_status_token(node.get("overall_state")) == "not_triggered":
        return "not triggered"
    if terms & {"auth_blocked", "visibility_blocked"}:
        return "auth/visibility blocked"
    if terms & FAILED_STATES:
        return "failed"
    if any(phase.get("unsatisfied_capabilities") for phase in phases):
        return "blocked"
    if terms & IN_PROGRESS_STATES:
        return "in progress"
    if phases and all(normalize_status_token(phase.get("state")) == "not_triggered" for phase in phases):
        return "not triggered"
    return "ready"


def classify_producer_state(node: dict[str, Any]) -> str:
    phases = reportable_phases(node["phases"])
    terms = node_state_terms(node, phases)
    if normalize_status_token(node.get("overall_state")) == "not_triggered":
        return "not triggered"
    if terms & {"auth_blocked", "visibility_blocked"}:
        return "auth/visibility blocked"
    if terms & FAILED_STATES:
        return "failed"
    if terms & IN_PROGRESS_STATES:
        return "in progress"
    if any(phase.get("unsatisfied_capabilities") for phase in phases):
        return "blocked"
    if phases and all(normalize_status_token(phase.get("state")) == "not_triggered" for phase in phases):
        return "not triggered"
    return "ready"


def trace_capability(
    graph: Graph,
    current_node: dict[str, Any],
    capability: str,
    phase_refs: list[dict[str, str]],
    capability_stack: list[str],
    node_stack: list[str],
) -> dict[str, Any]:
    current_key = node_key(current_node)
    branch: dict[str, Any] = {
        "capability": capability,
        "start_phase_names": [phase["name"] for phase in phase_refs],
        "start_phases": phase_refs,
        "source_node": {
            "project": current_node["project"],
            "flock": current_node["flock"],
            "region": current_node["region"],
            "phonebook_id": current_node["phonebook_id"],
        },
    }
    if capability in capability_stack:
        branch["terminal_reason"] = "cycle detected"
        branch["trace"] = [{"cycle_capability": capability, "cycle_path": capability_stack + [capability]}]
        return branch

    lookup = current_node.get("producer_capabilities", {}).get(capability, {"lookup_state": "unknown", "producers": []})
    trace_steps: list[dict[str, Any]] = [
        {
            "from_project": current_node["project"],
            "from_flock": current_node["flock"],
            "from_region": current_node["region"],
            "capability": capability,
            "lookup_state": lookup["lookup_state"],
        }
    ]
    producers = lookup.get("producers", [])
    if lookup["lookup_state"] in {"auth_blocked", "visibility_blocked"}:
        branch["terminal_reason"] = "auth/visibility blocked"
        branch["trace"] = trace_steps
        return branch
    if len(producers) > 1:
        branch["terminal_reason"] = "orchestration error"
        branch["trace"] = trace_steps + [{"producers": producers}]
        return branch
    if not producers:
        branch["terminal_reason"] = "auth/visibility blocked" if lookup["lookup_state"] in {"unknown", "not_found"} else "producer blocked"
        branch["trace"] = trace_steps
        return branch

    producer_ref = producers[0]
    trace_steps.append({"producer": producer_ref})
    producer_key = node_key(producer_ref)
    if producer_key in node_stack:
        branch["terminal_reason"] = "cycle detected"
        branch["trace"] = trace_steps + [{"cycle_node": producer_ref}]
        return branch

    producer_node = graph.get(producer_ref)
    if producer_node is None:
        branch["terminal_reason"] = "producer blocked"
        branch["next_target"] = producer_ref
        branch["trace"] = trace_steps
        return branch

    producer_state = classify_producer_state(producer_node)
    trace_steps.append(
        {
            "producer_state": producer_state,
            "producer_state_terms": sorted(node_state_terms(producer_node)),
            "producer_published_capabilities": producer_node["produced_capabilities"],
            "producer_pending_published_capabilities": producer_node["pending_published_capabilities"],
            "producer_unsatisfied_capabilities": aggregate_capabilities(
                reportable_phases(producer_node["phases"]), "unsatisfied_capabilities"
            ),
        }
    )

    if node_has_published_capability(producer_node, capability):
        branch["terminal_reason"] = "published"
        branch["terminal_node"] = {
            "project": producer_node["project"],
            "flock": producer_node["flock"],
            "region": producer_node["region"],
        }
        branch["trace"] = trace_steps
        return branch

    if producer_state == "failed":
        branch["terminal_reason"] = "producer failed"
        branch["terminal_node"] = {
            "project": producer_node["project"],
            "flock": producer_node["flock"],
            "region": producer_node["region"],
        }
        branch["trace"] = trace_steps
        return branch

    if producer_state == "in progress":
        branch["terminal_reason"] = "producer in progress"
        branch["terminal_node"] = {
            "project": producer_node["project"],
            "flock": producer_node["flock"],
            "region": producer_node["region"],
        }
        branch["trace"] = trace_steps
        return branch

    if producer_state == "not triggered":
        branch["terminal_reason"] = "not triggered"
        branch["terminal_node"] = {
            "project": producer_node["project"],
            "flock": producer_node["flock"],
            "region": producer_node["region"],
        }
        branch["trace"] = trace_steps
        return branch

    if producer_state == "auth/visibility blocked":
        branch["terminal_reason"] = "auth/visibility blocked"
        branch["terminal_node"] = {
            "project": producer_node["project"],
            "flock": producer_node["flock"],
            "region": producer_node["region"],
        }
        branch["trace"] = trace_steps
        return branch

    upstream_phases = reportable_phases(producer_node["phases"])
    upstream_unsatisfied = aggregate_capabilities(upstream_phases, "unsatisfied_capabilities")
    if upstream_unsatisfied:
        branch["terminal_reason"] = "upstream capability missing"
        branch["upstream_blockers"] = [
            trace_capability(
                graph,
                producer_node,
                upstream_capability,
                [
                    {"name": phase["name"], "change_type": phase.get("change_type", "")}
                    for phase in upstream_phases
                    if upstream_capability in phase["unsatisfied_capabilities"]
                ],
                capability_stack + [capability],
                node_stack + [current_key],
            )
            for upstream_capability in upstream_unsatisfied
        ]
        branch["trace"] = trace_steps
        return branch

    branch["terminal_reason"] = "producer blocked"
    branch["trace"] = trace_steps
    return branch


def worst_terminal_reason(branches: list[dict[str, Any]]) -> str:
    best_reason = "published"
    best_priority = -1
    for branch in branches:
        reason = branch["terminal_reason"]
        priority = TERMINAL_PRIORITY.get(reason, -1)
        if priority > best_priority:
            best_priority = priority
            best_reason = reason
        for child in branch.get("upstream_blockers", []):
            child_reason = worst_terminal_reason([child])
            child_priority = TERMINAL_PRIORITY.get(child_reason, -1)
            if child_priority > best_priority:
                best_priority = child_priority
                best_reason = child_reason
    return best_reason


def phase_status(phase: dict[str, Any]) -> str:
    state = str(phase.get("state", "unknown"))
    if state == "successful":
        return "Successful"
    if state in {"ready", "succeeded"}:
        return "Ready"
    if state in {"not_run", "unknown"} and phase.get("unsatisfied_capabilities"):
        return "Waiting / not run"
    if state in {"not_triggered", "nottriggered"}:
        return "Not triggered"
    if state in FAILED_STATES:
        return "Failed"
    if state in IN_PROGRESS_STATES:
        return "In progress"
    if state in {"auth_blocked", "visibility_blocked"}:
        return "Auth/visibility blocked"
    if state == "blocked":
        return "Blocked"
    return state.replace("_", " ").title()


def version_set_summary(value: Any) -> str:
    if not isinstance(value, dict) or not value:
        return "unknown"
    scope = value.get("scope") or value.get("name") or "unknown"
    published_at = value.get("publishedAt") or value.get("published_at")
    if published_at:
        return f"{scope}, published {published_at}"
    return str(scope)


def producer_from_branch(branch: dict[str, Any]) -> dict[str, Any] | None:
    for step in branch.get("trace", []):
        if step.get("producer"):
            return step["producer"]
    return branch.get("next_target")


def producer_waiting_on(branch: dict[str, Any], limit: int = 5) -> str:
    blockers = [child["capability"] for child in branch.get("upstream_blockers", [])]
    if not blockers:
        for step in branch.get("trace", []):
            blockers = step.get("producer_unsatisfied_capabilities") or []
            if blockers:
                break
    return format_capabilities(blockers, limit=limit)


def producer_status(branch: dict[str, Any]) -> str:
    for step in branch.get("trace", []):
        if step.get("producer_state"):
            return str(step["producer_state"])
    return branch["terminal_reason"]


def next_inspect(branch: dict[str, Any]) -> str:
    producer = producer_from_branch(branch)
    if not producer:
        return "browser/UI producer lookup"
    phase_names: list[str] = []
    for child in branch.get("upstream_blockers", []):
        for phase in child.get("start_phases", []):
            label = phase.get("name", "")
            if phase.get("change_type"):
                label = f"{label} {phase['change_type']}"
            if label and label not in phase_names:
                phase_names.append(label)
    if phase_names:
        return f"{format_ref(producer)}, phase `{phase_names[0]}`"
    return format_ref(producer)


def render_dependency_chain(branches: list[dict[str, Any]], indent: str = "  ") -> list[str]:
    lines: list[str] = []
    for branch in branches:
        start_phases = branch.get("start_phases") or [{"name": name, "change_type": ""} for name in branch.get("start_phase_names", [])]
        phase_text = ", ".join(
            f"{phase.get('name')}{' ' + phase.get('change_type') if phase.get('change_type') else ''}"
            for phase in start_phases
        ) or "unknown phase"
        lines.append(f"{indent}{phase_text} waits on {branch['capability']}")
        producer = producer_from_branch(branch)
        if producer:
            lines.append(f"{indent}  producer: {producer.get('project')} / {producer.get('flock')}")
        else:
            lines.append(f"{indent}  producer: not visible from current API evidence")
        lines.append(f"{indent}  terminal reason: {branch['terminal_reason']}")
        waiting_on = producer_waiting_on(branch, limit=5)
        if waiting_on != "none":
            lines.append(f"{indent}  producer waits on: {waiting_on}")
        child_lines = render_dependency_chain(branch.get("upstream_blockers", [])[:3], indent + "  ")
        lines.extend(child_lines)
    return lines


def render_text_report(report: dict[str, Any]) -> str:
    request = report["request"]
    metadata = report.get("metadata", {})
    lines = [
        "# MFO Region Build Status",
        "",
        "## Target",
        f"- Region: `{request['region']}`",
        f"- Project: `{request['project']}`",
        f"- Flock: `{request['flock']}`",
        f"- Phonebook: `{request['phonebook_id'] or 'unknown'}`",
        f"- Entry URL: {report['entry_url'] or 'unknown'}",
        f"- Checked At: `{report.get('checked_at', 'unknown')}`",
        "",
        "## Overall Status",
        f"- Overall: `{report['overall_status']}`",
        f"- Flock Status: `{metadata.get('flock_status') or 'unknown'}`",
        f"- Completion Status: `{metadata.get('completion_status') or 'unknown'}`",
        f"- Infrastructure Version Set: `{version_set_summary(metadata.get('infrastructure_version_set'))}`",
        f"- Application Version Set: `{version_set_summary(metadata.get('application_version_set'))}`",
        "",
        "## Phase Summary",
        markdown_row(
            [
                "Phase",
                "Type",
                "Status",
                "Published / Will Publish",
                "Pending Required Capabilities",
                "Pending Optional Capabilities",
            ]
        ),
        markdown_row(["---", "---", "---", "---", "---", "---"]),
    ]
    for phase in report["per_phase_summary"]:
        lines.append(
            markdown_row(
                [
                    f"`{phase['name']}`",
                    phase.get("change_type") or "unknown",
                    phase_status(phase),
                    format_capabilities(phase.get("produced_capabilities", []), limit=5),
                    format_capabilities(phase.get("unsatisfied_capabilities", []), limit=7),
                    format_capabilities(phase.get("optional_capabilities", []), limit=7),
                ]
            )
        )

    lines.extend(
        [
            "",
            "## Pending Capability Producers",
            markdown_row(["Pending Capability", "Needed By Phase", "Producer", "Producer Status", "Producer Is Waiting On", "Next Inspect"]),
            markdown_row(["---", "---", "---", "---", "---", "---"]),
        ]
    )
    if not report["blocking_capabilities"]:
        lines.append(markdown_row(["none", "none", "none", "published", "none", "none"]))
    for blocker in report["blocking_capabilities"]:
        needed_by = ", ".join(
            f"`{phase.get('name')}{' ' + phase.get('change_type') if phase.get('change_type') else ''}`"
            for phase in blocker.get("start_phases", [])
        ) or ", ".join(f"`{name}`" for name in blocker.get("start_phase_names", []))
        lines.append(
            markdown_row(
                [
                    f"`{blocker['capability']}`",
                    needed_by or "unknown",
                    format_ref(producer_from_branch(blocker)) if producer_from_branch(blocker) else "no visible producer",
                    producer_status(blocker),
                    producer_waiting_on(blocker),
                    next_inspect(blocker),
                ]
            )
        )

    lines.extend(["", "## Dependency Chain", f"{request['project']} / {request['flock']}"])
    chain_lines = render_dependency_chain(report["blocking_capabilities"])
    lines.extend(chain_lines or ["  no blocking capabilities"])

    if report["next_targets"]:
        lines.extend(["", "## Next Targets"])
        for target in report["next_targets"]:
            lines.append(f"- {format_ref(target)} in `{target.get('region', request['region'])}`")
    return "\n".join(lines) + "\n"


def build_report(
    payload: dict[str, Any],
    start_project: str,
    start_flock: str,
    start_region: str | None,
    include_ohe_vibe: bool = False,
) -> dict[str, Any]:
    graph = Graph.from_payload(payload)
    candidates = [
        node
        for node in payload["nodes"]
        if node["project"] == start_project and node["flock"] == start_flock and (not start_region or node["region"] == start_region)
    ]
    if not candidates:
        raise ValueError("Starting flock was not found in the normalized graph")
    start_node = candidates[0]
    phases = reportable_phases(start_node["phases"], include_ohe_vibe)
    blocked_phases = [
        phase_label(phase)
        for phase in phases
        if phase["unsatisfied_capabilities"] or phase["state"] in {"blocked", "not_triggered", "auth_blocked", "visibility_blocked"}
    ]
    unsatisfied_by_capability: dict[str, list[dict[str, str]]] = {}
    for phase in phases:
        for capability in phase["unsatisfied_capabilities"]:
            unsatisfied_by_capability.setdefault(capability, []).append(
                {"name": phase["name"], "change_type": phase.get("change_type", "")}
            )

    blocking_capabilities = [
        trace_capability(graph, start_node, capability, phase_refs, [], [])
        for capability, phase_refs in unsatisfied_by_capability.items()
    ]
    discovered_related = []
    next_targets = []
    seen_related = set()
    seen_targets = set()

    def collect(branch: dict[str, Any]) -> None:
        for step in branch.get("trace", []):
            producer = step.get("producer")
            if producer:
                key = node_key(producer)
                if key not in seen_related and key != node_key(start_node):
                    seen_related.add(key)
                    discovered_related.append(producer)
            cycle_node = step.get("cycle_node")
            if cycle_node:
                key = node_key(cycle_node)
                if key not in seen_related and key != node_key(start_node):
                    seen_related.add(key)
                    discovered_related.append(cycle_node)
        next_target = branch.get("next_target")
        if next_target:
            key = node_key(next_target)
            if key not in seen_targets:
                seen_targets.add(key)
                next_targets.append(next_target)
        for child in branch.get("upstream_blockers", []):
            collect(child)

    for branch in blocking_capabilities:
        collect(branch)

    overall_status = classify_node_state(start_node)
    worst_reason = worst_terminal_reason(blocking_capabilities) if blocking_capabilities else "published"
    if worst_reason == "orchestration error":
        overall_status = "orchestration_error"
    elif worst_reason == "producer failed":
        overall_status = "producer_failed"
    elif worst_reason == "producer in progress":
        overall_status = "producer_in_progress"
    elif worst_reason == "auth/visibility blocked":
        overall_status = "auth/visibility_blocked" if overall_status == "auth/visibility blocked" else "blocked"
    elif overall_status == "ready" and not blocking_capabilities:
        overall_status = "ready"
    elif overall_status == "not triggered":
        overall_status = "not_triggered"
    elif overall_status == "failed":
        overall_status = "failed"
    elif overall_status == "in progress":
        overall_status = "in_progress"
    else:
        overall_status = "blocked"

    return {
        "request": {
            "region": start_node["region"],
            "project": start_node["project"],
            "flock": start_node["flock"],
            "phonebook_id": start_node["phonebook_id"],
        },
        "checked_at": datetime.now().astimezone().isoformat(timespec="seconds"),
        "entry_url": start_node["page_url"],
        "evidence_urls": [
            url for url in dict.fromkeys([node["page_url"] for node in payload["nodes"] if node["page_url"]]) if url
        ],
        "metadata": {
            "flock_status": start_node.get("flock_status", ""),
            "completion_status": start_node.get("completion_status", ""),
            "infrastructure_version_set": start_node.get("infrastructure_version_set", {}),
            "application_version_set": start_node.get("application_version_set", {}),
        },
        "overall_status": overall_status,
        "per_phase_summary": phases,
        "blocked_phases": blocked_phases,
        "satisfied_capabilities": aggregate_capabilities(phases, "satisfied_capabilities"),
        "unsatisfied_capabilities": aggregate_capabilities(phases, "unsatisfied_capabilities"),
        "optional_capabilities": aggregate_capabilities(phases, "optional_capabilities"),
        "blocking_capabilities": blocking_capabilities,
        "discovered_related_flocks": discovered_related,
        "next_targets": next_targets,
    }


def load_payload(path: str) -> dict[str, Any]:
    raw = json.loads(Path(path).read_text())
    return normalize_graph(raw)


def run_self_test() -> int:
    scenarios = [
        (
            "nairobi-upstream-chain",
            {
                "nodes": [
                    {
                        "project": "service-registry",
                        "flock": "tenancy-creator",
                        "region": "af-nairobi-1",
                        "phonebookId": "Itm",
                        "page_url": "https://devops.oci.oraclecorp.com/region-build/regions/af-nairobi-1/flocks?flocksFilter=flockName%20%3D%20tenancy-creator",
                        "phases": [
                            {
                                "name": "vibe-af-nairobi-1",
                                "state": "blocked",
                                "satisfied": ["base_networking_ready"],
                                "unsatisfied": ["tenancy_lifecycle_service_bootstrapped_in_vibe"],
                                "optional": [],
                            }
                        ],
                        "producer_capabilities": {
                            "tenancy_lifecycle_service_bootstrapped_in_vibe": [
                                {
                                    "project": "service-registry",
                                    "flock": "tenancy-lifecycle-service",
                                    "region": "af-nairobi-1",
                                }
                            ]
                        },
                    },
                    {
                        "project": "service-registry",
                        "flock": "tenancy-lifecycle-service",
                        "region": "af-nairobi-1",
                        "phonebookId": "Itm",
                        "page_url": "https://example/producer",
                        "phases": [
                            {
                                "name": "af-nairobi-1",
                                "state": "blocked",
                                "satisfied": [],
                                "unsatisfied": ["tenant_service_schema_ready"],
                                "optional": [],
                            }
                        ],
                        "pending_published_capabilities": ["tenancy_lifecycle_service_bootstrapped_in_vibe"],
                        "producer_capabilities": {
                            "tenant_service_schema_ready": [
                                {
                                    "project": "identity-platform",
                                    "flock": "tenant-service-schema",
                                    "region": "af-nairobi-1",
                                }
                            ]
                        },
                    },
                    {
                        "project": "identity-platform",
                        "flock": "tenant-service-schema",
                        "region": "af-nairobi-1",
                        "produced_capabilities": ["tenant_service_schema_ready"],
                        "phases": [{"name": "af-nairobi-1", "state": "ready", "satisfied": [], "unsatisfied": [], "optional": []}],
                    },
                ]
            },
            "blocked",
        ),
        (
            "all-satisfied",
            {
                "nodes": [
                    {
                        "project": "demo",
                        "flock": "ready-flock",
                        "region": "us-ashburn-1",
                        "phases": [{"name": "prod", "state": "ready", "satisfied": ["cap_a"], "unsatisfied": [], "optional": []}],
                    }
                ]
            },
            "ready",
        ),
        (
            "not-triggered",
            {
                "nodes": [
                    {
                        "project": "demo",
                        "flock": "waiting-flock",
                        "region": "us-phoenix-1",
                        "overall_state": "not_triggered",
                        "phases": [{"name": "prod", "state": "not_triggered", "satisfied": [], "unsatisfied": ["cap_x"], "optional": []}],
                        "producer_capabilities": {
                            "cap_x": [{"project": "demo", "flock": "source-flock", "region": "us-phoenix-1"}]
                        },
                    },
                    {
                        "project": "demo",
                        "flock": "source-flock",
                        "region": "us-phoenix-1",
                        "overall_state": "not_triggered",
                        "phases": [{"name": "prod", "state": "not_triggered", "satisfied": [], "unsatisfied": [], "optional": []}],
                    },
                ]
            },
            "not_triggered",
        ),
        (
            "producer-failed",
            {
                "nodes": [
                    {
                        "project": "demo",
                        "flock": "consumer",
                        "region": "r1",
                        "phases": [{"name": "prod", "state": "blocked", "satisfied": [], "unsatisfied": ["cap_x"], "optional": []}],
                        "producer_capabilities": {
                            "cap_x": [{"project": "demo", "flock": "producer", "region": "r1"}]
                        },
                    },
                    {
                        "project": "demo",
                        "flock": "producer",
                        "region": "r1",
                        "overall_state": "failed",
                        "flockCompletionStatus": "FAILED",
                        "phases": [{"name": "prod", "state": "failed", "satisfied": [], "unsatisfied": [], "optional": []}],
                    },
                ]
            },
            "producer_failed",
        ),
        (
            "producer-in-progress",
            {
                "nodes": [
                    {
                        "project": "demo",
                        "flock": "consumer",
                        "region": "r1",
                        "phases": [{"name": "prod", "state": "blocked", "satisfied": [], "unsatisfied": ["cap_x"], "optional": []}],
                        "producer_capabilities": {
                            "cap_x": [{"project": "demo", "flock": "producer", "region": "r1"}]
                        },
                    },
                    {
                        "project": "demo",
                        "flock": "producer",
                        "region": "r1",
                        "flockCompletionStatus": "BUILDING",
                        "phases": [
                            {
                                "name": "prod",
                                "state": "building",
                                "satisfied": [],
                                "unsatisfied": ["cap_y"],
                                "optional": [],
                            }
                        ],
                        "producer_capabilities": {
                            "cap_y": [{"project": "demo", "flock": "upstream", "region": "r1"}]
                        },
                    },
                    {
                        "project": "demo",
                        "flock": "upstream",
                        "region": "r1",
                        "produced_capabilities": ["cap_y"],
                        "phases": [{"name": "prod", "state": "ready", "satisfied": [], "unsatisfied": [], "optional": []}],
                    },
                ]
            },
            "producer_in_progress",
        ),
        (
            "published-capability-wins-over-producer-progress",
            {
                "nodes": [
                    {
                        "project": "demo",
                        "flock": "consumer",
                        "region": "r1",
                        "phases": [{"name": "prod", "state": "blocked", "satisfied": [], "unsatisfied": ["cap_x"], "optional": []}],
                        "producer_capabilities": {
                            "cap_x": [{"project": "demo", "flock": "producer", "region": "r1"}]
                        },
                    },
                    {
                        "project": "demo",
                        "flock": "producer",
                        "region": "r1",
                        "flockCompletionStatus": "BUILDING",
                        "phases": [
                            {
                                "name": "prod",
                                "state": "successful",
                                "satisfied": [],
                                "unsatisfied": [],
                                "optional": [],
                                "produced_capabilities": ["cap_x"],
                            },
                            {"name": "followup", "state": "building", "satisfied": [], "unsatisfied": [], "optional": []},
                        ],
                    },
                ]
            },
            "blocked",
        ),
        (
            "cycle",
            {
                "nodes": [
                    {
                        "project": "demo",
                        "flock": "a",
                        "region": "r1",
                        "phases": [{"name": "prod", "state": "blocked", "satisfied": [], "unsatisfied": ["cap_a"], "optional": []}],
                        "producer_capabilities": {"cap_a": [{"project": "demo", "flock": "b", "region": "r1"}]},
                    },
                    {
                        "project": "demo",
                        "flock": "b",
                        "region": "r1",
                        "phases": [{"name": "prod", "state": "blocked", "satisfied": [], "unsatisfied": ["cap_a"], "optional": []}],
                        "pending_published_capabilities": ["cap_a"],
                        "producer_capabilities": {"cap_a": [{"project": "demo", "flock": "a", "region": "r1"}]},
                    },
                ]
            },
            "blocked",
        ),
        (
            "multi-producer-error",
            {
                "nodes": [
                    {
                        "project": "demo",
                        "flock": "a",
                        "region": "r1",
                        "phases": [{"name": "prod", "state": "blocked", "satisfied": [], "unsatisfied": ["cap_shared"], "optional": []}],
                        "producer_capabilities": {
                            "cap_shared": [
                                {"project": "demo", "flock": "b", "region": "r1"},
                                {"project": "demo", "flock": "c", "region": "r1"},
                            ]
                        },
                    }
                ]
            },
            "orchestration_error",
        ),
    ]

    for name, payload, expected_status in scenarios:
        normalized = normalize_graph(payload)
        start = normalized["nodes"][0]
        report = build_report(normalized, start["project"], start["flock"], start["region"])
        if report["overall_status"] != expected_status:
            raise AssertionError(f"{name}: expected {expected_status}, got {report['overall_status']}")
        if name == "producer-failed":
            reason = worst_terminal_reason(report["blocking_capabilities"])
            if reason != "producer failed":
                raise AssertionError(f"{name}: expected producer failed terminal reason, got {reason}")
        if name == "producer-in-progress":
            reason = worst_terminal_reason(report["blocking_capabilities"])
            if reason != "producer in progress":
                raise AssertionError(f"{name}: expected producer in progress terminal reason, got {reason}")
        if name == "published-capability-wins-over-producer-progress":
            reason = worst_terminal_reason(report["blocking_capabilities"])
            if reason != "published":
                raise AssertionError(f"{name}: expected published terminal reason, got {reason}")
    print(f"Self-test passed for {len(scenarios)} scenarios.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Trace normalized MFO region-build dependency graphs.")
    parser.add_argument("--input", help="Normalized or raw graph JSON file.")
    parser.add_argument("--project", help="Starting project name.")
    parser.add_argument("--flock", help="Starting flock name.")
    parser.add_argument("--region", help="Starting region.")
    parser.add_argument(
        "--report-format",
        choices=("json", "text"),
        default="json",
        help="Output format.",
    )
    parser.add_argument(
        "--include-ohe-vibe-phases",
        action="store_true",
        help="Include ohe_vibe* phases in reports. They are hidden by default.",
    )
    parser.add_argument("--self-test", action="store_true", help="Run built-in deterministic scenarios.")
    args = parser.parse_args()

    if args.self_test:
        return run_self_test()

    if not args.input or not args.project or not args.flock:
        parser.error("--input, --project, and --flock are required unless --self-test is used")

    payload = load_payload(args.input)
    report = build_report(payload, args.project, args.flock, args.region, include_ohe_vibe=args.include_ohe_vibe_phases)
    if args.report_format == "text":
        sys.stdout.write(render_text_report(report))
    else:
        sys.stdout.write(dump_json(report))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
