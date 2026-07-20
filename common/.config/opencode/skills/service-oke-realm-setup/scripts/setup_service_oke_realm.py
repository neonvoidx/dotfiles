#!/usr/bin/env python3
"""Set up service OKE SSH and kubeconfig access from a service OKE TOML config.

The setup command populates missing safe realm metadata back into the TOML by
default, such as alias, compartment_id, and realm_domain. Use
--no-update-config for a read-only config run.
"""

from __future__ import annotations

import argparse
import configparser
import json
import os
import re
import signal
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

try:
    import tomllib
except ModuleNotFoundError:  # pragma: no cover - for older local Python only.
    import tomli as tomllib  # type: ignore[no-redef]


HOME = Path.home()
SKILL_DIR = Path(__file__).resolve().parents[1]
KNOWN_HOSTS = HOME / ".ssh/known_hosts"
KUBE_DIR = HOME / ".kube"
OCI = Path("/opt/homebrew/bin/oci")
KUBECTL = Path("/opt/homebrew/bin/kubectl")
OSSH = Path("/opt/homebrew/bin/ossh")


def run(
    cmd: list[str],
    *,
    check: bool = True,
    capture: bool = True,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess:
    merged_env = os.environ.copy()
    merged_env["PATH"] = f"/opt/homebrew/bin:{merged_env.get('PATH', '')}"
    if env:
        merged_env.update(env)
    print("+ " + " ".join(cmd), file=sys.stderr)
    return subprocess.run(cmd, check=check, text=True, capture_output=capture, env=merged_env)


def oci(args: list[str], profile: str, region: str | None = None) -> dict[str, Any]:
    cmd = [str(OCI), *args, "--profile", profile, "--auth", "security_token", "--output", "json"]
    if region and "--region" not in args:
        cmd.extend(["--region", region])
    proc = run(cmd)
    return json.loads(proc.stdout or "{}")


def norm_slug(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")


class FormatMap(dict[str, str]):
    def __missing__(self, key: str) -> str:
        return "{" + key + "}"


def expand_path(value: str, mapping: dict[str, str]) -> Path:
    expanded = value.format_map(FormatMap(mapping))
    expanded = os.path.expandvars(os.path.expanduser(expanded))
    return Path(expanded)


def load_toml(path: Path) -> dict[str, Any]:
    with path.open("rb") as fh:
        return tomllib.load(fh)


def candidate_config_paths(service: str | None, config: str | None, cwd: Path) -> list[Path]:
    if config:
        return [Path(config).expanduser()]
    names: list[str] = []
    if service:
        names.extend([norm_slug(service), service.lower()])
    else:
        names.append("aat")
    seen: set[str] = set()
    unique_names = []
    for name in names:
        if name and name not in seen:
            seen.add(name)
            unique_names.append(name)
    paths: list[Path] = []
    for name in unique_names:
        paths.append(cwd / ".agents" / "service-oke" / f"{name}.toml")
    for name in unique_names:
        paths.append(SKILL_DIR / "assets" / "service-teams" / f"{name}.toml")
    return paths


def discover_config(service: str | None, config: str | None, cwd: Path) -> tuple[Path, dict[str, Any]]:
    checked = candidate_config_paths(service, config, cwd)
    for path in checked:
        if path.exists():
            return path, load_toml(path)
    if service:
        wanted = norm_slug(service)
        search_dirs = [
            cwd / ".agents" / "service-oke",
            SKILL_DIR / "assets" / "service-teams",
        ]
        for directory in search_dirs:
            for path in sorted(directory.glob("*.toml")) if directory.exists() else []:
                raw = load_toml(path)
                service_cfg = raw.get("service", {})
                aliases = [
                    path.stem,
                    str(service_cfg.get("key") or ""),
                    str(service_cfg.get("display_name") or ""),
                    *(str(alias) for alias in service_cfg.get("aliases", []) or []),
                ]
                if wanted in {norm_slug(alias) for alias in aliases if alias}:
                    return path, raw
    raise SystemExit(
        "Could not find a service OKE config. Checked:\n"
        + "\n".join(f"- {path}" for path in checked)
        + "\nPass --config or create .agents/service-oke/<service_key>.toml."
    )


@dataclass
class ServiceConfig:
    path: Path
    raw: dict[str, Any]
    realm: str
    service_key: str
    service_slug: str
    display_name: str
    tenancy_name: str
    profile: str
    region: str
    alias: str | None
    ssh_config: Path
    kube_backup: Path
    host_prefix: str
    local_oke_port: int
    remote_oke_port: int
    extra_forwards: list[dict[str, Any]]
    compartment_id: str | None
    bastion_compartment_id: str | None
    cluster_id: str | None
    bastion_id: str | None
    realm_domain: str | None
    auto_update_config: bool


def realm_section(raw: dict[str, Any], realm: str) -> dict[str, Any]:
    realms = raw.get("realms", {})
    section = realms.get(realm) or realms.get(realm.lower()) or realms.get(realm.upper())
    return dict(section or {})


def toml_value(value: Any) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int):
        return str(value)
    return json.dumps(str(value))


def update_realm_config(path: Path, realm: str, values: dict[str, Any], *, missing_only: bool = True) -> None:
    clean = {key: value for key, value in values.items() if value not in (None, "")}
    if not clean:
        return
    text = path.read_text() if path.exists() else ""
    header = f"[realms.{realm}]"
    section_re = re.compile(rf"(^\[realms\.{re.escape(realm)}\]\n)(.*?)(?=^\[|\Z)", re.M | re.S)
    match = section_re.search(text)
    if not match:
        addition = "\n" if text.endswith("\n") or not text else "\n\n"
        lines = [header, *(f"{key} = {toml_value(value)}" for key, value in clean.items())]
        path.write_text(text + addition + "\n".join(lines) + "\n")
        print(f"Updated {path}: added {header}", file=sys.stderr)
        return

    body = match.group(2)
    existing_keys = set(re.findall(r"^([A-Za-z0-9_-]+)\s*=", body, re.M))
    new_body = body
    changed = False
    for key, value in clean.items():
        line = f"{key} = {toml_value(value)}"
        if key in existing_keys:
            if not missing_only:
                new_body = re.sub(rf"^{re.escape(key)}\s*=.*$", line, new_body, count=1, flags=re.M)
                changed = True
            continue
        if new_body and not new_body.endswith("\n"):
            new_body += "\n"
        new_body += line + "\n"
        changed = True
    if changed:
        path.write_text(text[:match.start(2)] + new_body + text[match.end(2):])
        print(f"Updated {path}: populated missing {header} values", file=sys.stderr)


def infer_ssh_realm_metadata(cfg: ServiceConfig) -> dict[str, str]:
    if not cfg.ssh_config.exists():
        return {}
    text = cfg.ssh_config.read_text()
    block_match = re.search(
        rf"### {re.escape(cfg.realm.upper())}\b.*?(?=\n(?:#+\n\n###|\[realms\.|####################.*End|$))",
        text,
        re.S,
    )
    if not block_match:
        block_match = re.search(
            rf"### {re.escape(cfg.realm.upper())}\b.*?(?=\n### |\Z)",
            text,
            re.S,
        )
    if not block_match:
        return {}
    block = block_match.group(0)
    metadata: dict[str, str] = {}
    region_match = re.search(rf"### {re.escape(cfg.realm.upper())}[^\n]* - ([a-z0-9-]+)", block)
    if region_match:
        metadata["region"] = region_match.group(1)
    compartment_match = re.search(r"--compartment\s+(\S+)", block)
    if compartment_match:
        metadata["compartment_id"] = compartment_match.group(1)
        metadata["bastion_compartment_id"] = compartment_match.group(1)
    ztb_match = re.search(rf"ztb-internal\.bastion\.{re.escape(cfg.region)}\.oci\.([^\s]+)", block)
    if ztb_match:
        metadata["realm_domain"] = ztb_match.group(1)
    host_match = re.search(rf"Host\s+{re.escape(cfg.host_prefix)}-([a-z0-9]+)-\d+-oke", block)
    if host_match:
        metadata["alias"] = host_match.group(1)
    return metadata


def persist_missing_realm_values(cfg: ServiceConfig, values: dict[str, Any]) -> None:
    if cfg.auto_update_config:
        update_realm_config(cfg.path, cfg.realm, values, missing_only=True)


def resolve_service_config(args: argparse.Namespace, cwd: Path) -> ServiceConfig:
    path, raw = discover_config(args.service, args.config, cwd)
    service = raw.get("service", {})
    profile_cfg = raw.get("profile", {})
    paths = raw.get("paths", {})
    tunnel = raw.get("tunnel", {})
    realm = args.realm.lower()
    realm_cfg = realm_section(raw, realm)

    service_key = str(service.get("key") or args.service or path.stem).lower()
    service_slug = norm_slug(str(service.get("display_name") or service_key))
    display_name = str(service.get("display_name") or service_key)
    tenancy_name = args.tenancy_name or realm_cfg.get("tenancy_name") or service.get("tenancy_name")
    if not tenancy_name:
        raise SystemExit("Missing tenancy name. Add service.tenancy_name to the config or pass --tenancy-name.")

    mapping = {
        "realm": realm,
        "realm_upper": realm.upper(),
        "service_key": service_key,
        "service_slug": service_slug,
    }
    profile_template = str(profile_cfg.get("template") or "{realm}-{service_key}")
    profile = args.profile or realm_cfg.get("profile") or profile_template.format_map(FormatMap(mapping))
    region = args.region or realm_cfg.get("region")
    if not region:
        raise SystemExit("Missing region. Add realms.<realm>.region to the config or pass --region.")
    alias = args.alias or realm_cfg.get("alias")

    ssh_config_template = paths.get("ssh_config")
    kube_template = paths.get("kubeconfig_backup_template")
    if not ssh_config_template:
        raise SystemExit("Missing paths.ssh_config in service OKE config.")
    if not kube_template:
        raise SystemExit("Missing paths.kubeconfig_backup_template in service OKE config.")
    ssh_config = expand_path(str(ssh_config_template), mapping)
    kube_backup = expand_path(str(realm_cfg.get("kubeconfig") or kube_template), mapping)
    host_prefix = str(service.get("host_prefix") or f"{service_key}-service")

    return ServiceConfig(
        path=path,
        raw=raw,
        realm=realm,
        service_key=service_key,
        service_slug=service_slug,
        display_name=display_name,
        tenancy_name=str(tenancy_name),
        profile=str(profile),
        region=str(region),
        alias=str(alias).lower() if alias else None,
        ssh_config=ssh_config,
        kube_backup=kube_backup,
        host_prefix=host_prefix,
        local_oke_port=int(args.local_port or tunnel.get("local_oke_port") or 6443),
        remote_oke_port=int(tunnel.get("remote_oke_port") or 6443),
        extra_forwards=list(tunnel.get("extra_forwards") or []),
        compartment_id=args.compartment_id or realm_cfg.get("compartment_id") or realm_cfg.get("service_compartment_id"),
        bastion_compartment_id=args.bastion_compartment_id or realm_cfg.get("bastion_compartment_id"),
        cluster_id=args.cluster_id or realm_cfg.get("cluster_id"),
        bastion_id=args.bastion_id or realm_cfg.get("bastion_id"),
        realm_domain=args.realm_domain or realm_cfg.get("realm_domain"),
        auto_update_config=not args.no_update_config,
    )


def profile_tenancy(profile: str) -> str:
    cfg = configparser.ConfigParser()
    cfg.read(HOME / ".oci/config")
    if profile not in cfg:
        raise SystemExit(f"OCI profile {profile!r} not found in ~/.oci/config")
    tenancy = cfg[profile].get("tenancy")
    if not tenancy:
        raise SystemExit(f"OCI profile {profile!r} has no tenancy in ~/.oci/config")
    return tenancy


def validate_or_authenticate(cfg: ServiceConfig, authenticate: bool) -> None:
    validate = run([str(OCI), "session", "validate", "--profile", cfg.profile], check=False)
    if validate.returncode == 0:
        print(validate.stdout.strip())
        return
    if not authenticate:
        raise SystemExit(
            f"OCI profile {cfg.profile} is not valid. Run:\n"
            f"{OCI} session authenticate --profile-name {cfg.profile} --region {cfg.region} "
            f"--tenancy-name {cfg.tenancy_name} --session-expiration-in-minutes 60"
        )
    run([
        str(OCI),
        "session",
        "authenticate",
        "--profile-name",
        cfg.profile,
        "--region",
        cfg.region,
        "--tenancy-name",
        cfg.tenancy_name,
        "--session-expiration-in-minutes",
        "60",
    ], capture=False)


def discover_compartment(cfg: ServiceConfig) -> str:
    if cfg.compartment_id:
        return cfg.compartment_id
    inferred = infer_ssh_realm_metadata(cfg)
    if inferred.get("compartment_id"):
        cfg.compartment_id = inferred["compartment_id"]
        cfg.bastion_compartment_id = cfg.bastion_compartment_id or inferred.get("bastion_compartment_id")
        persist_missing_realm_values(cfg, {
            "compartment_id": cfg.compartment_id,
            "bastion_compartment_id": cfg.bastion_compartment_id if cfg.bastion_compartment_id != cfg.compartment_id else None,
        })
        return cfg.compartment_id
    tenancy = profile_tenancy(cfg.profile)
    data = oci([
        "iam",
        "compartment",
        "list",
        "--compartment-id",
        tenancy,
        "--compartment-id-in-subtree",
        "true",
        "--access-level",
        "ACCESSIBLE",
        "--all",
    ], cfg.profile, cfg.region)
    compartments = data.get("data", [])
    tokens = {cfg.service_key, cfg.service_slug, norm_slug(cfg.display_name)}
    tokens.update(norm_slug(alias) for alias in cfg.raw.get("service", {}).get("aliases", []) or [])
    tokens = {token for token in tokens if token}
    candidates = []
    for comp in compartments:
        name = norm_slug(str(comp.get("name") or comp.get("display-name") or ""))
        if comp.get("lifecycle-state") == "DELETED":
            continue
        if any(token in name for token in tokens):
            candidates.append(comp)
    if len(candidates) != 1:
        print(json.dumps(candidates, indent=2), file=sys.stderr)
        raise SystemExit("Could not uniquely discover service compartment. Pass --compartment-id or set realms.<realm>.compartment_id.")
    return candidates[0]["id"]


def one_active(items: list[dict[str, Any]], label: str) -> dict[str, Any]:
    active = [item for item in items if item.get("lifecycle-state") in ("ACTIVE", "AVAILABLE", "RUNNING")]
    if len(active) != 1:
        print(json.dumps(items, indent=2), file=sys.stderr)
        raise SystemExit(f"Could not uniquely identify active {label}.")
    return active[0]


def discover_realm_domain(cfg: ServiceConfig) -> str:
    if cfg.realm_domain:
        return cfg.realm_domain
    inferred = infer_ssh_realm_metadata(cfg)
    if inferred.get("realm_domain"):
        cfg.realm_domain = inferred["realm_domain"]
        persist_missing_realm_values(cfg, {"realm_domain": cfg.realm_domain})
        return cfg.realm_domain
    substrate = HOME / ".ssh/ossh_configs/README.substrate-bastion.md"
    if substrate.exists():
        for line in substrate.read_text().splitlines():
            if f"|{cfg.region}|" in line and ".oci." in line:
                host = line.strip("|").split("|")[-1]
                return host.split(f"{cfg.region}.oci.", 1)[1].rstrip("|")
    raise SystemExit("Could not discover realm domain. Pass --realm-domain or set realms.<realm>.realm_domain.")


def discover_alias(cfg: ServiceConfig) -> str:
    if cfg.alias:
        return cfg.alias
    inferred = infer_ssh_realm_metadata(cfg)
    if inferred.get("alias"):
        cfg.alias = inferred["alias"]
        persist_missing_realm_values(cfg, {"alias": cfg.alias})
        return cfg.alias
    data = oci(["iam", "region", "list", "--all"], cfg.profile, cfg.region)
    for item in data.get("data", []):
        if item.get("name") == cfg.region and item.get("key"):
            cfg.alias = str(item["key"]).lower()
            persist_missing_realm_values(cfg, {"alias": cfg.alias})
            return cfg.alias
    raise SystemExit("Could not discover region alias. Pass --alias or set realms.<realm>.alias.")


def discover_extra_forward(cfg: ServiceConfig, forward: dict[str, Any], compartment: str) -> dict[str, Any]:
    resolved = dict(forward)
    if resolved.get("private_ip"):
        return resolved
    resource_type = str(resolved.get("resource_type") or "").lower()
    if resource_type in ("autonomous_database", "autonomous-database", "adb"):
        display_name = str(resolved.get("display_name") or resolved.get("name") or "").upper()
        dbs = oci(["db", "autonomous-database", "list", "--compartment-id", compartment, "--all"], cfg.profile, cfg.region).get("data", [])
        matches = [
            db for db in dbs
            if db.get("private-endpoint-ip")
            and (not display_name or str(db.get("display-name") or "").upper() == display_name)
        ]
        db = one_active(matches, f"autonomous database {display_name or resolved.get('name', '')}")
        resolved["private_ip"] = db["private-endpoint-ip"]
        return resolved
    if resolved.get("required", False):
        raise SystemExit(f"Extra forward {resolved.get('name')} has no private_ip and unsupported resource_type {resource_type!r}.")
    return resolved


def discover_resources(cfg: ServiceConfig) -> dict[str, Any]:
    compartment = discover_compartment(cfg)
    bastion_compartment = cfg.bastion_compartment_id or compartment
    persist_missing_realm_values(cfg, {
        "region": cfg.region,
        "profile": cfg.profile,
        "compartment_id": compartment,
        "bastion_compartment_id": bastion_compartment if bastion_compartment != compartment else None,
    })

    if cfg.bastion_id:
        bastion = oci(["bastion", "bastion", "get", "--bastion-id", cfg.bastion_id], cfg.profile, cfg.region).get("data", {})
    else:
        bastions = oci(["bastion", "bastion", "list", "--compartment-id", bastion_compartment, "--all"], cfg.profile, cfg.region).get("data", [])
        bastion = one_active([b for b in bastions if "zerotrust" in str(b.get("name") or "").lower()] or bastions, "bastion")

    if cfg.cluster_id:
        cluster = oci(["ce", "cluster", "get", "--cluster-id", cfg.cluster_id], cfg.profile, cfg.region).get("data", {})
        cluster_id = cfg.cluster_id
    else:
        clusters = oci(["ce", "cluster", "list", "--compartment-id", compartment, "--all"], cfg.profile, cfg.region).get("data", [])
        cluster = one_active(clusters, "OKE cluster")
        cluster_id = cluster["id"]
        cluster = oci(["ce", "cluster", "get", "--cluster-id", cluster_id], cfg.profile, cfg.region).get("data", {})
    private_endpoint = cluster.get("endpoints", {}).get("private-endpoint")
    if not private_endpoint:
        raise SystemExit("OKE cluster has no private endpoint.")
    oke_ip = private_endpoint.split(":", 1)[0]

    nodes = []
    pools = oci(["ce", "node-pool", "list", "--compartment-id", compartment, "--cluster-id", cluster_id, "--all"], cfg.profile, cfg.region).get("data", [])
    for pool in pools:
        detail = oci(["ce", "node-pool", "get", "--node-pool-id", pool["id"]], cfg.profile, cfg.region).get("data", {})
        for node in detail.get("nodes", []) or []:
            if node.get("lifecycle-state") == "ACTIVE" and node.get("private-ip"):
                nodes.append({"name": node.get("name"), "ip": node["private-ip"]})
    if not nodes:
        instances = oci(["compute", "instance", "list", "--compartment-id", compartment, "--all"], cfg.profile, cfg.region).get("data", [])
        nodes = [{"name": inst.get("display-name"), "ip": inst.get("private-ip")} for inst in instances if inst.get("lifecycle-state") == "RUNNING" and inst.get("private-ip")]
    if not nodes:
        raise SystemExit("Could not discover active OKE node private IPs.")

    alias = discover_alias(cfg)
    realm_domain = discover_realm_domain(cfg)
    persist_missing_realm_values(cfg, {
        "alias": alias,
        "realm_domain": realm_domain,
    })
    extra_forwards = [discover_extra_forward(cfg, forward, compartment) for forward in cfg.extra_forwards]
    return {
        "realm": cfg.realm,
        "realm_upper": cfg.realm.upper(),
        "region": cfg.region,
        "profile": cfg.profile,
        "service_key": cfg.service_key,
        "host_prefix": cfg.host_prefix,
        "alias": alias,
        "compartment_id": compartment,
        "bastion_compartment_id": bastion_compartment,
        "bastion_id": bastion["id"],
        "cluster_id": cluster_id,
        "oke_endpoint_ip": oke_ip,
        "ztb_dns": f"ztb-internal.bastion.{cfg.region}.oci.{realm_domain}",
        "nodes": sorted(nodes, key=lambda n: n["name"] or n["ip"]),
        "extra_forwards": extra_forwards,
        "local_oke_port": cfg.local_oke_port,
        "remote_oke_port": cfg.remote_oke_port,
    }


def ssh_block(resources: dict[str, Any]) -> tuple[str, str]:
    nodes = resources["nodes"]
    host_prefix = resources["host_prefix"]
    first_host = f"{host_prefix}-{resources['alias']}-0-oke"
    lines = [
        "#####################################################",
        "",
        f"### {resources['realm_upper']} (Overlay bastion / OKE) - {resources['region']}",
        "",
        "#####################################################",
        "",
        "# JumpHost",
        "",
        f"Host {host_prefix}-{resources['alias']}-jump",
        f"    HostName {resources['bastion_id']}-{nodes[0]['ip']}",
        f"    ProxyCommand ossh proxy -u %r --overlay-bastion --region {resources['region']} --compartment {resources['bastion_compartment_id']} -- ssh -A -p 22 {resources['ztb_dns']} -s proxy:%h:%p",
        "",
        "# Service Nodes",
        "",
    ]
    for idx, node in enumerate(nodes):
        host = f"{host_prefix}-{resources['alias']}-{idx}-oke"
        lines.extend([
            f"Host {host}",
            f"    HostName {resources['bastion_id']}-{node['ip']}",
            f"    ProxyCommand ossh proxy -u %r --overlay-bastion --region {resources['region']} --compartment {resources['bastion_compartment_id']} -- ssh -A -p 22 {resources['ztb_dns']} -s proxy:%h:%p",
            "",
        ])
    tunnel_parts = [f"-L {resources['local_oke_port']}:{resources['oke_endpoint_ip']}:{resources['remote_oke_port']}"]
    for forward in resources["extra_forwards"]:
        private_ip = forward.get("private_ip")
        if private_ip:
            tunnel_parts.append(f"-L {forward['local_port']}:{private_ip}:{forward['remote_port']}")
    lines.extend([
        f"# ssh {' '.join(tunnel_parts)} {first_host}",
        "",
    ])
    return "\n".join(lines), first_host


def replace_or_append_ssh_config(cfg: ServiceConfig, resources: dict[str, Any]) -> str:
    cfg.ssh_config.parent.mkdir(parents=True, exist_ok=True)
    text = cfg.ssh_config.read_text() if cfg.ssh_config.exists() else ""
    block, first_host = ssh_block(resources)
    marker_re = re.compile(
        rf"#####################################################\n\n### {re.escape(resources['realm_upper'])} .*?(?=\n(?:#####################################################\n\n###|####################.*End|$))",
        re.S,
    )
    if marker_re.search(text):
        text = marker_re.sub(block.rstrip(), text, count=1)
    elif "####################" in text and "End" in text:
        end_match = re.search(r"^####################.*End.*$", text, re.M)
        assert end_match
        text = text[:end_match.start()] + block + text[end_match.start():]
    else:
        if text and not text.endswith("\n"):
            text += "\n"
        text += block
    cfg.ssh_config.write_text(text)
    return first_host


def add_known_host(ztb_dns: str) -> None:
    KNOWN_HOSTS.parent.mkdir(parents=True, exist_ok=True)
    scan = run(["ssh-keyscan", "-t", "ecdsa", ztb_dns], check=False)
    if scan.returncode == 0 and scan.stdout:
        existing = KNOWN_HOSTS.read_text() if KNOWN_HOSTS.exists() else ""
        if ztb_dns not in existing:
            with KNOWN_HOSTS.open("a") as fh:
                fh.write(scan.stdout)


def port_listening(port: int) -> bool:
    proc = run(["lsof", "-nP", f"-iTCP:{port}", "-sTCP:LISTEN"], check=False)
    return proc.returncode == 0 and "LISTEN" in proc.stdout


def port_owners(ports: list[int]) -> dict[int, list[dict[str, str]]]:
    owners: dict[int, list[dict[str, str]]] = {}
    for port in ports:
        proc = run(["lsof", "-nP", f"-iTCP:{port}", "-sTCP:LISTEN"], check=False)
        rows = []
        for line in proc.stdout.splitlines()[1:]:
            parts = line.split()
            if len(parts) >= 2:
                rows.append({"command": parts[0], "pid": parts[1], "line": line})
        owners[port] = rows
    return owners


def clear_tunnel_ports(resources: dict[str, Any], replace_existing: bool) -> None:
    ports = [int(resources["local_oke_port"])]
    ports.extend(int(f["local_port"]) for f in resources["extra_forwards"] if f.get("private_ip"))
    owners = port_owners(ports)
    active = [(port, row) for port, rows in owners.items() for row in rows]
    if not active:
        return
    for port, row in active:
        print(f"Port {port} is owned by: {row['line']}", file=sys.stderr)
    if not replace_existing:
        raise SystemExit("Tunnel ports are already in use. Re-run with --replace-existing-tunnel to kill existing ssh tunnel owners.")
    pids = {int(row["pid"]) for _, row in active if row["command"] == "ssh"}
    non_ssh = [(port, row) for port, row in active if row["command"] != "ssh"]
    if non_ssh:
        raise SystemExit("A non-ssh process owns a tunnel port; refusing to kill it automatically.")
    for pid in sorted(pids):
        print(f"Killing existing ssh tunnel PID {pid}", file=sys.stderr)
        os.kill(pid, signal.SIGTERM)
    for _ in range(20):
        if not any(port_owners(ports).values()):
            return
        subprocess.run(["sleep", "0.2"], check=False)
    raise SystemExit("Tunnel ports are still in use after killing existing ssh tunnel owners.")


def tunnel_command(cfg: ServiceConfig, resources: dict[str, Any], host: str) -> list[str]:
    cmd = [
        "ssh",
        "-fN",
        "-F",
        str(cfg.ssh_config),
        "-o",
        "ExitOnForwardFailure=yes",
        "-o",
        "ServerAliveInterval=30",
        "-o",
        "ServerAliveCountMax=3",
        "-L",
        f"{resources['local_oke_port']}:{resources['oke_endpoint_ip']}:{resources['remote_oke_port']}",
    ]
    for forward in resources["extra_forwards"]:
        private_ip = forward.get("private_ip")
        if private_ip:
            cmd.extend(["-L", f"{forward['local_port']}:{private_ip}:{forward['remote_port']}"])
    cmd.append(host)
    return cmd


def run_ssh_tunnel(cmd: list[str], region: str | None = None) -> None:
    proc = run(cmd, check=False, capture=True)
    if proc.returncode == 0:
        return
    output = f"{proc.stdout or ''}\n{proc.stderr or ''}"
    if region and ("download-pki-certs" in output or "certificate is not trusted" in output):
        print(output, file=sys.stderr)
        run([str(OSSH), "download-pki-certs", region], capture=False)
        run(cmd, capture=False)
        return
    if output.strip():
        print(output, file=sys.stderr)
    raise subprocess.CalledProcessError(proc.returncode, cmd, output=proc.stdout, stderr=proc.stderr)


def start_tunnel(cfg: ServiceConfig, resources: dict[str, Any], host: str, replace_existing: bool) -> None:
    clear_tunnel_ports(resources, replace_existing)
    add_known_host(resources["ztb_dns"])
    run_ssh_tunnel(tunnel_command(cfg, resources, host), resources["region"])


def create_kube_backup(cfg: ServiceConfig, resources: dict[str, Any]) -> Path:
    cfg.kube_backup.parent.mkdir(parents=True, exist_ok=True)
    run([
        str(OCI),
        "ce",
        "cluster",
        "create-kubeconfig",
        "--profile",
        cfg.profile,
        "--auth",
        "security_token",
        "--cluster-id",
        resources["cluster_id"],
        "--file",
        str(cfg.kube_backup),
        "--region",
        cfg.region,
        "--token-version",
        "2.0.0",
        "--kube-endpoint",
        "PRIVATE_ENDPOINT",
        "--overwrite",
        "--with-auth-context",
    ], capture=False)
    text = cfg.kube_backup.read_text()
    text = text.replace(
        f"server: https://{resources['oke_endpoint_ip']}:{resources['remote_oke_port']}",
        f"server: https://127.0.0.1:{resources['local_oke_port']}",
    )
    text = text.replace("command: oci", f"command: {OCI}")
    text = text.replace("security-token", "security_token")
    cfg.kube_backup.write_text(text)
    return cfg.kube_backup


def activate_kubeconfig(cfg: ServiceConfig) -> Path:
    if not cfg.kube_backup.exists():
        raise SystemExit(f"Missing {cfg.kube_backup}; run setup first.")
    dst = KUBE_DIR / "config"
    KUBE_DIR.mkdir(parents=True, exist_ok=True)
    if dst.exists():
        snapshot = KUBE_DIR / f"config.before-{cfg.realm}-{subprocess.check_output(['date', '+%Y%m%d-%H%M%S'], text=True).strip()}"
        shutil.copy2(dst, snapshot)
        print(f"Saved previous kubeconfig to {snapshot}", file=sys.stderr)
    shutil.copy2(cfg.kube_backup, dst)
    return dst


def verify(cfg: ServiceConfig) -> None:
    if not port_listening(cfg.local_oke_port):
        raise SystemExit(f"Local port {cfg.local_oke_port} is not listening; start or repair the SSH tunnel before kubectl.")
    run([str(KUBECTL), "get", "pods"], capture=False)


def cmd_setup(args: argparse.Namespace) -> None:
    cfg = resolve_service_config(args, Path.cwd())
    validate_or_authenticate(cfg, args.authenticate)
    if OSSH.exists():
        run([str(OSSH), "init-regions-config"], check=False, capture=False)
    resources = discover_resources(cfg)
    host = replace_or_append_ssh_config(cfg, resources)
    create_kube_backup(cfg, resources)
    activate_kubeconfig(cfg)
    if args.start_tunnel:
        start_tunnel(cfg, resources, host, args.replace_existing_tunnel)
    print(json.dumps(resources, indent=2))
    if args.verify:
        verify(cfg)


def cmd_plan(args: argparse.Namespace) -> None:
    cfg = resolve_service_config(args, Path.cwd())
    print(json.dumps({
        "config": str(cfg.path),
        "service_key": cfg.service_key,
        "display_name": cfg.display_name,
        "realm": cfg.realm,
        "region": cfg.region,
        "profile": cfg.profile,
        "tenancy_name": cfg.tenancy_name,
        "ssh_config": str(cfg.ssh_config),
        "kube_backup": str(cfg.kube_backup),
        "host_prefix": cfg.host_prefix,
        "local_oke_port": cfg.local_oke_port,
        "extra_forwards": cfg.extra_forwards,
        "compartment_id": cfg.compartment_id,
        "bastion_compartment_id": cfg.bastion_compartment_id,
    }, indent=2))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)

    setup = sub.add_parser("setup", help="Run full live-OCI setup for a service realm.")
    setup.add_argument("--realm", required=True)
    setup.add_argument("--service", help="Service key or slug. Defaults to aat when omitted.")
    setup.add_argument("--config", help="Explicit service OKE TOML config path.")
    setup.add_argument("--region")
    setup.add_argument("--profile")
    setup.add_argument("--tenancy-name")
    setup.add_argument("--alias")
    setup.add_argument("--local-port", type=int)
    setup.add_argument("--compartment-id")
    setup.add_argument("--bastion-compartment-id")
    setup.add_argument("--cluster-id")
    setup.add_argument("--bastion-id")
    setup.add_argument("--realm-domain")
    setup.add_argument("--authenticate", action="store_true")
    setup.add_argument("--replace-existing-tunnel", action="store_true")
    setup.add_argument("--start-tunnel", action="store_true")
    setup.add_argument("--verify", action="store_true")
    setup.add_argument("--no-update-config", action="store_true", help="Do not populate missing realms.<realm> values back into the service TOML.")
    setup.set_defaults(func=cmd_setup)

    plan = sub.add_parser("plan", help="Resolve config and print the derived setup plan without OCI calls.")
    plan.add_argument("--realm", required=True)
    plan.add_argument("--service", help="Service key, slug, display name, or alias. Defaults to aat when omitted.")
    plan.add_argument("--config", help="Explicit service OKE TOML config path.")
    plan.add_argument("--region")
    plan.add_argument("--profile")
    plan.add_argument("--tenancy-name")
    plan.add_argument("--alias")
    plan.add_argument("--local-port", type=int)
    plan.add_argument("--compartment-id")
    plan.add_argument("--bastion-compartment-id")
    plan.add_argument("--cluster-id")
    plan.add_argument("--bastion-id")
    plan.add_argument("--realm-domain")
    plan.add_argument("--no-update-config", action="store_true", help=argparse.SUPPRESS)
    plan.set_defaults(func=cmd_plan)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
