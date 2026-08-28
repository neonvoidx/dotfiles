#!/usr/bin/env python3
from __future__ import annotations

import argparse
import configparser
import os
import re
import shlex
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Sequence


DEFAULT_OP_TOKEN_COMMAND = (
    "ssh",
    "operator-access-token.svc.ad1.r2",
    "generate",
    "--mode",
    "jwt",
)
JWT_RE = re.compile(r"^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$")


@dataclass
class CommandResult:
    returncode: int
    stdout: str
    stderr: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Shared helper for refreshing OP_TOKEN values and OCI session-backed profiles."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    op_token = subparsers.add_parser(
        "op-token",
        help="Refresh OP_TOKEN and optionally write it into one or more dotenv files.",
    )
    op_token.add_argument(
        "--env-file",
        action="append",
        default=[],
        help="Dotenv file to update with OP_TOKEN=<token>. Repeat to update multiple files.",
    )
    op_token.add_argument(
        "--token-command",
        help=(
            "Override the token generation command. "
            "Defaults to: ssh operator-access-token.svc.ad1.r2 generate --mode jwt"
        ),
    )
    op_token.add_argument(
        "--print-token",
        action="store_true",
        help="Print the refreshed token after completing any file updates.",
    )

    oci_session = subparsers.add_parser(
        "oci-session",
        help="Validate an OCI session-backed profile and refresh it if needed.",
    )
    oci_session.add_argument("--profile", required=True, help="OCI CLI profile name.")
    oci_session.add_argument(
        "--region",
        help="Session bootstrap region. Defaults to the profile region in ~/.oci/config when available.",
    )
    oci_session.add_argument(
        "--config-file",
        default="~/.oci/config",
        help="Path to the OCI CLI config file. Default: ~/.oci/config",
    )
    oci_session.add_argument(
        "--local",
        action="store_true",
        help="Use `oci ... session validate --local` before deciding whether to refresh.",
    )
    oci_session.add_argument(
        "--validate-only",
        action="store_true",
        help="Only validate the session. Do not run authenticate when validation fails.",
    )
    oci_session.add_argument(
        "--oci-bin",
        default="oci",
        help="OCI CLI executable to use. Default: oci",
    )

    return parser.parse_args()


def run_command(
    args: Sequence[str], *, check: bool = False, capture_output: bool = True
) -> CommandResult:
    completed = subprocess.run(
        list(args),
        check=False,
        capture_output=capture_output,
        text=True,
    )
    result = CommandResult(
        returncode=completed.returncode,
        stdout=completed.stdout or "",
        stderr=completed.stderr or "",
    )
    if check and result.returncode != 0:
        raise subprocess.CalledProcessError(
            result.returncode,
            list(args),
            output=result.stdout,
            stderr=result.stderr,
        )
    return result


def parse_command(raw_command: str | None) -> list[str]:
    if not raw_command:
        return list(DEFAULT_OP_TOKEN_COMMAND)
    return shlex.split(raw_command)


def extract_jwt_token(command_result: CommandResult) -> str:
    combined_lines = [
        line.strip()
        for line in (command_result.stdout + "\n" + command_result.stderr).splitlines()
        if line.strip()
    ]
    for line in reversed(combined_lines):
        if JWT_RE.match(line):
            return line
    raise RuntimeError(
        "Token generator did not emit a JWT-looking value. "
        "Inspect the command output and refresh the token manually if needed."
    )


def backup_existing_file(path: Path) -> Path | None:
    if not path.exists():
        return None
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    backup_path = path.with_name(f"{path.name}.bak.{timestamp}")
    backup_path.write_text(path.read_text(encoding="utf-8"), encoding="utf-8")
    return backup_path


def update_env_file(path: Path, key: str, value: str) -> Path | None:
    path = path.expanduser().resolve()
    path.parent.mkdir(parents=True, exist_ok=True)
    original_text = path.read_text(encoding="utf-8") if path.exists() else ""
    lines = original_text.splitlines()
    replacement = f"{key}={value}"
    replaced = False
    updated_lines: list[str] = []
    for line in lines:
        if line.startswith(f"{key}="):
            updated_lines.append(replacement)
            replaced = True
        else:
            updated_lines.append(line)
    if not replaced:
        updated_lines.append(replacement)

    new_text = "\n".join(updated_lines).rstrip() + "\n"
    backup_path = backup_existing_file(path)
    path.write_text(new_text, encoding="utf-8")
    return backup_path


def load_profile_config(config_file: Path, profile: str) -> tuple[str | None, bool]:
    parser = configparser.ConfigParser()
    parser.read(config_file)
    if profile not in parser:
        return None, False
    section = parser[profile]
    return section.get("region"), "security_token_file" in section


def emit_command_output(result: CommandResult) -> None:
    if result.stdout:
        print(result.stdout, end="" if result.stdout.endswith("\n") else "\n")
    if result.stderr:
        print(result.stderr, end="" if result.stderr.endswith("\n") else "\n", file=sys.stderr)


def refresh_op_token(args: argparse.Namespace) -> int:
    command = parse_command(args.token_command)
    try:
        result = run_command(command, check=True)
    except FileNotFoundError:
        print(f"Token command not found: {command[0]}", file=sys.stderr)
        return 2
    except subprocess.CalledProcessError as exc:
        if exc.output:
            print(exc.output, end="" if exc.output.endswith("\n") else "\n")
        if exc.stderr:
            print(exc.stderr, end="" if exc.stderr.endswith("\n") else "\n", file=sys.stderr)
        print("Failed to refresh OP_TOKEN.", file=sys.stderr)
        return exc.returncode or 1

    try:
        token = extract_jwt_token(result)
    except RuntimeError as exc:
        emit_command_output(result)
        print(str(exc), file=sys.stderr)
        return 1

    env_files = [Path(raw_path).expanduser() for raw_path in args.env_file]
    for env_file in env_files:
        backup_path = update_env_file(env_file, "OP_TOKEN", token)
        print(f"Updated OP_TOKEN in {env_file.resolve()}")
        if backup_path:
            print(f"Backup created: {backup_path.resolve()}")

    if not env_files or args.print_token:
        print(token)

    return 0


def validate_oci_session(oci_bin: str, profile: str, local: bool) -> CommandResult:
    command = [oci_bin, "--profile", profile, "session", "validate"]
    if local:
        command.append("--local")
    return run_command(command)


def authenticate_oci_session(oci_bin: str, profile: str, region: str) -> CommandResult:
    command = [
        oci_bin,
        "session",
        "authenticate",
        "--profile-name",
        profile,
        "--region",
        region,
    ]
    return run_command(command, capture_output=False)


def refresh_oci_session(args: argparse.Namespace) -> int:
    config_file = Path(args.config_file).expanduser().resolve()
    profile_region, uses_security_token = load_profile_config(config_file, args.profile)
    try:
        validate_result = validate_oci_session(args.oci_bin, args.profile, args.local)
    except FileNotFoundError:
        print(f"OCI CLI not found: {args.oci_bin}", file=sys.stderr)
        return 2
    if validate_result.returncode == 0:
        print(f"OCI session is valid for profile {args.profile}.")
        if profile_region:
            print(f"Profile region: {profile_region}")
        if uses_security_token:
            print("Profile uses security_token_file. Remember `--auth security_token` on OCI API calls.")
        return 0

    emit_command_output(validate_result)
    if args.validate_only:
        print(f"OCI session validation failed for profile {args.profile}.", file=sys.stderr)
        return validate_result.returncode or 1

    region = args.region or profile_region
    if not region:
        print(
            "OCI session validation failed and no session region is available. "
            "Pass --region or set region in the target profile in ~/.oci/config.",
            file=sys.stderr,
        )
        return 2

    if profile_region and not args.region:
        print(f"Using profile region from {config_file}: {profile_region}")

    print(
        "Refreshing OCI session. If the CLI prints a login URL, open it manually and "
        "keep this command running until the localhost callback completes."
    )
    try:
        auth_result = authenticate_oci_session(args.oci_bin, args.profile, region)
    except FileNotFoundError:
        print(f"OCI CLI not found: {args.oci_bin}", file=sys.stderr)
        return 2

    if auth_result.returncode != 0:
        print("OCI session refresh failed.", file=sys.stderr)
        return auth_result.returncode or 1

    final_validation = validate_oci_session(args.oci_bin, args.profile, args.local)
    if final_validation.returncode != 0:
        emit_command_output(final_validation)
        print("OCI session authenticate completed, but validation still fails.", file=sys.stderr)
        return final_validation.returncode or 1

    print(f"OCI session is valid for profile {args.profile}.")
    print(f"Session region: {region}")
    if uses_security_token:
        print("Profile uses security_token_file. Remember `--auth security_token` on OCI API calls.")
    return 0


def main() -> int:
    args = parse_args()
    if args.command == "op-token":
        return refresh_op_token(args)
    if args.command == "oci-session":
        return refresh_oci_session(args)
    print(f"Unsupported command: {args.command}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
