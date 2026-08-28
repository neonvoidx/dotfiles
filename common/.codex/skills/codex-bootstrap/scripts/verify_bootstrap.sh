#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../../.." && pwd)"
python_bin="${PYTHON_BIN:-python3}"
tmp_root="${TMPDIR:-/tmp}"

complete_home="$(mktemp -d "${tmp_root%/}/codex-bootstrap-complete.XXXXXX")"
copy_home="$(mktemp -d "${tmp_root%/}/codex-bootstrap-copy.XXXXXX")"
shared_home="$(mktemp -d "${tmp_root%/}/codex-bootstrap-shared.XXXXXX")"
browser_home="$(mktemp -d "${tmp_root%/}/codex-bootstrap-browser.XXXXXX")"
test_home="$(mktemp -d "${tmp_root%/}/codex-bootstrap-test.XXXXXX")"
undo_home="$(mktemp -d "${tmp_root%/}/codex-bootstrap-undo.XXXXXX")"
complete_home_real="$(cd "${complete_home}" && pwd -P)"
shared_home_real="$(cd "${shared_home}" && pwd -P)"

cleanup() {
  rm -rf "${complete_home}" "${copy_home}" "${shared_home}" "${browser_home}" "${test_home}" "${undo_home}"
}

write_skill_auth_helpers() {
  local target_dir="$1"
  local home_dir="${target_dir}/home"
  mkdir -p "${home_dir}"
  cat > "${target_dir}/bitbucket-pr.env" <<'EOF'
export BASE_URL="https://bitbucket.example.com"
export BITBUCKET_TOKEN="bitbucket-verify-token"
EOF
  cat > "${home_dir}/.env" <<'EOF'
JIRA_URL="https://jira-sd.mc1.oracleiaas.com"
JIRA_PERSONAL_TOKEN="jira-sd-verify-token"
EOF
  cat > "${home_dir}/.env.jira-oci" <<'EOF'
JIRA_URL="https://jira.oci.oraclecorp.com"
JIRA_PERSONAL_TOKEN="jira-oci-verify-token"
EOF
}

trap cleanup EXIT

"${python_bin}" -m py_compile "${script_dir}/bootstrap_codex.py"

cat > "${test_home}/team-sqlcl.toml" <<'EOF'
[[team]]
name = "Accounts Service"

[team.sqlcl]
connection_name = "Accounts-phx-sqlcl"
connect_string = "//localhost:10803/s_bling_accounts.r2"
username = "blingAccountRO[Readonlyuser]"
password_env_var = "ACCOUNTS_SQLCL_PASSWORD"
password_env_file = "sqlcl.env"
EOF

cat > "${test_home}/team-sqlcl-existing.toml" <<'EOF'
[[team]]
name = "Existing SQLcl Service"

[team.sqlcl]
connection_name = "Accounts-phx-sqlcl"
tunnel_command = "ssh -L 10803:service-host:1521 bastion.example.com"
notes = "Run the tunnel first."
EOF

cat > "${test_home}/sqlcl.env" <<'EOF'
export ACCOUNTS_SQLCL_PASSWORD="accounts-secret"
EOF

"${python_bin}" - <<'PY' "${script_dir}/bootstrap_codex.py" "${test_home}/team-sqlcl.toml" "${test_home}/team-sqlcl-existing.toml" "${test_home}/sqlcl.env"
import importlib.util
import pathlib
import sys

module_path = pathlib.Path(sys.argv[1])
config_path = pathlib.Path(sys.argv[2])
existing_config_path = pathlib.Path(sys.argv[3])
env_path = pathlib.Path(sys.argv[4]).resolve()
spec = importlib.util.spec_from_file_location("bootstrap_codex", module_path)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

assert module.list_sqlcl_team_names(config_path) == ["Accounts Service"]
sqlcl_config = module.load_sqlcl_team_connection_config(config_path, "Accounts Service")
assert sqlcl_config["connection_name"] == "Accounts-phx-sqlcl"
assert sqlcl_config["setup_mode"] == "bootstrap"
password, resolved_env_path = module.resolve_sqlcl_password(sqlcl_config, team_config_path=config_path)
assert password == "accounts-secret"
assert resolved_env_path == env_path
script = module.render_sqlcl_connection_setup_script(sqlcl_config, password)
assert 'connect -save "Accounts-phx-sqlcl" -savepwd' in script
assert '-user "blingAccountRO[Readonlyuser]"' in script
assert '-url "//localhost:10803/s_bling_accounts.r2"' in script

existing_config = module.load_sqlcl_team_connection_config(existing_config_path, "Existing SQLcl Service")
assert existing_config["connection_name"] == "Accounts-phx-sqlcl"
assert existing_config["setup_mode"] == "existing"
summary, notes = module.configure_sqlcl_saved_connection(
    module.argparse.Namespace(
        sqlcl_team_config=str(existing_config_path),
        sqlcl_team_name="Existing SQLcl Service",
    ),
    {"home_dir": str(existing_config_path.parent)},
)
assert summary == "Using existing SQLcl saved connection for Existing SQLcl Service: Accounts-phx-sqlcl"
assert notes == [
    "SQLcl tunnel helper: ssh -L 10803:service-host:1521 bastion.example.com",
    "SQLcl notes: Run the tunnel first.",
]
PY

write_skill_auth_helpers "${complete_home}"
write_skill_auth_helpers "${copy_home}"
write_skill_auth_helpers "${shared_home}"
write_skill_auth_helpers "${browser_home}"
write_skill_auth_helpers "${undo_home}"

"${python_bin}" "${script_dir}/bootstrap_codex.py" \
  --repo-root "${repo_root}" \
  --codex-home "${complete_home}" \
  --output "${complete_home}/config.toml" \
  --workspace-parent "$(dirname "${repo_root}")" \
  --m2-repository "${HOME}/.m2/repository" \
  --agents-mode symlink \
  --agents-target "${complete_home}/AGENTS.md" \
  --bitbucket-auth-state ready \
  --bitbucket-env-file "${complete_home}/bitbucket-pr.env" \
  --jira-auth-state ready \
  --env-file "${complete_home}/mcp.env" \
  --generate-mcp-env stlm-mcp \
  --generate-mcp-env mcp-dope \
  --home-dir "${complete_home}/home" \
  --log-directory "${complete_home}/log"

test -f "${complete_home}/config.toml"
test -f "${complete_home}/AGENTS.md"
test -f "${complete_home}/bitbucket-pr.env"
test -f "${complete_home}/home/.env"
test -f "${complete_home}/home/.env.jira-oci"
test -f "${complete_home}/mcp.env"
! test -e "${complete_home}/stlm.env"
! test -e "${complete_home}/dope.env"
! test -L "${complete_home}/AGENTS.md"
! rg -n '/ABSOLUTE/PATH/TO|<your-' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings 'model = "gpt-5.5"' "${complete_home}/config.toml" >/dev/null
! rg -n '^profile\s*=|^\[profiles' "${complete_home}/config.toml" >/dev/null
! rg -n --fixed-strings '[[skills.config]]' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings '[marketplaces.devplat-plugins]' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings 'source = "ssh://git@bitbucket.oci.oraclecorp.com:7999/dpai/devplat-plugins.git"' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings '[plugins."mcp-gateway-plugin@devplat-plugins"]' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings '[plugins."mcp-gateway-plugin@devplat-plugins".mcp_servers.devplat_mcp_gateway.tools.devplat_mcp_gateway__use]' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings 'approval_mode = "approve"' "${complete_home}/config.toml" >/dev/null
! rg -n --fixed-strings 'last_revision' "${complete_home}/config.toml" >/dev/null
! rg -n --fixed-strings 'last_updated' "${complete_home}/config.toml" >/dev/null
for skill_name in authZ-permissions-yaml-generator bitbucket-pr cm-review codex-bootstrap create-module-knowledge-skills internal-confluence-page jira-ticket mfo-region-build-status object-store oncall-investigation ots-ticket pr-description release-check repository-version-preflight scm-pr; do
  test -L "${complete_home}/skills/${skill_name}"
  test -f "${complete_home}/skills/${skill_name}/SKILL.md"
done
rg -n --fixed-strings "\"${HOME}/.m2/repository\"" "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings "\"${complete_home_real}/home/.oci\"" "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings "\"${complete_home_real}/home/.env\"" "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings "\"${complete_home_real}/home/.env.jira-oci\"" "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings "\"${complete_home_real}/mcp.env\"" "${complete_home}/config.toml" >/dev/null
rg -n 'LOG_DIRECTORY = ".*/log"' "${complete_home}/config.toml" >/dev/null
test -f "${complete_home}/agents/software-architect.toml"
rg -n 'agents/software-architect\.toml"' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings 'model = "gpt-5.5"' "${complete_home}/agents/software-architect.toml" >/dev/null
rg -n --fixed-strings 'model_reasoning_effort = "high"' "${complete_home}/agents/software-architect.toml" >/dev/null
for mcp_name in chrome-devtools sqlcl mcp-atlassian-jira-sd mcp-atlassian-jira-oci centralconfluence playwright ots mcp_shepherd lts-mcp; do
  rg -n --fixed-strings "[mcp_servers.${mcp_name}]" "${complete_home}/config.toml" >/dev/null
done
rg -n --fixed-strings -- '--channel=canary' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings "\"${complete_home_real}/home/Downloads/sqlcl/bin/sql\"" "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings 'url = "https://emcp.oracle.com/atlassian/centralconfluence/v2"' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings 'https://artifactory.oci.oraclecorp.com/api/pypi/ticketing-fe-repository-dev-pypi-local/simple' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings '"mcp-atlassian"' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings 'READ_ONLY_MODE = "false"' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings '"https://jira-sd.mc1.oracleiaas.com"' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings '"https://jira.oci.oraclecorp.com"' "${complete_home}/config.toml" >/dev/null
! rg -n --fixed-strings 'ghcr.io/sooperset/mcp-atlassian' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings "\"${complete_home_real}/home/.oci/config\"" "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings 'OCI_CLI_AUTH = "security_token"' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings 'OCI_SESSION_AUTO_REFRESH = "true"' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings 'OCI_SESSION_AUTO_INTERACTIVE_AUTH = "true"' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings 'OCI_SESSION_AUTH_REGION = "us-ashburn-1"' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings 'OCI_SESSION_TENANCY_NAME = "bmc_operator_access"' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings 'OCI_SESSION_EXPIRATION_MINUTES = "60"' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings 'OCI_SESSION_REFRESH_TIMEOUT_SECONDS = "600"' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings 'https://artifactory.oci.oraclecorp.com/api/pypi/global-release-pypi/simple/' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings 'lts-mcp@latest' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings 'LTS_ENDPOINT = "https://load-testing.us-westjordan-1.ocp.oraclecloud16.com"' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings 'LTS_AUTH = "oci"' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings 'OCI_PROFILE = "DEFAULT"' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings 'OCI_SESSION_AUTH_REGION = "us-westjordan-1"' "${complete_home}/config.toml" >/dev/null
rg -n --fixed-strings 'Generated by Codex bootstrap for mcp-dope.' "${complete_home}/mcp.env" >/dev/null
rg -n --fixed-strings "python3 ${repo_root}/skills/codex-bootstrap/scripts/refresh_auth.py op-token --env-file <this-file>" "${complete_home}/mcp.env" >/dev/null
! rg -n --fixed-strings 'Generated by Codex bootstrap for stlm-mcp.' "${complete_home}/mcp.env" >/dev/null
! rg -n --fixed-strings 'OCI_CONFIG_FILE=' "${complete_home}/mcp.env" >/dev/null
! rg -n --fixed-strings 'OCI_PROFILE=' "${complete_home}/mcp.env" >/dev/null
! rg -n --fixed-strings 'OCI_CLI_AUTH=security_token' "${complete_home}/mcp.env" >/dev/null
! rg -n '/ABSOLUTE/PATH/TO|<your-' "${complete_home}/mcp.env" >/dev/null
rg -n --fixed-strings 'export BASE_URL="https://bitbucket.example.com"' "${complete_home}/bitbucket-pr.env" >/dev/null
rg -n --fixed-strings 'export BITBUCKET_TOKEN="bitbucket-verify-token"' "${complete_home}/bitbucket-pr.env" >/dev/null
rg -n --fixed-strings 'JIRA_URL="https://jira-sd.mc1.oracleiaas.com"' "${complete_home}/home/.env" >/dev/null
rg -n --fixed-strings 'JIRA_PERSONAL_TOKEN="jira-sd-verify-token"' "${complete_home}/home/.env" >/dev/null
rg -n --fixed-strings 'JIRA_URL="https://jira.oci.oraclecorp.com"' "${complete_home}/home/.env.jira-oci" >/dev/null
rg -n --fixed-strings 'JIRA_PERSONAL_TOKEN="jira-oci-verify-token"' "${complete_home}/home/.env.jira-oci" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/codex-bootstrap/SKILL.md\`" "${complete_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/ots-ticket/SKILL.md\`" "${complete_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/jira-ticket/SKILL.md\`" "${complete_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/cm-review/SKILL.md\`" "${complete_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/create-module-knowledge-skills/SKILL.md\`" "${complete_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/internal-confluence-page/SKILL.md\`" "${complete_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/oncall-investigation/SKILL.md\`" "${complete_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/object-store/SKILL.md\`" "${complete_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/repository-version-preflight/SKILL.md\`" "${complete_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/mfo-region-build-status/SKILL.md\`" "${complete_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/release-check/SKILL.md\`" "${complete_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/authZ-permissions-yaml-generator/SKILL.md\`" "${complete_home}/AGENTS.md" >/dev/null

"${python_bin}" "${script_dir}/bootstrap_codex.py" \
  --repo-root "${repo_root}" \
  --codex-home "${shared_home}" \
  --output "${shared_home}/config.toml" \
  --workspace-parent "$(dirname "${repo_root}")" \
  --agents-mode copy \
  --agents-target "${shared_home}/AGENTS.md" \
  --bitbucket-auth-state ready \
  --bitbucket-env-file "${shared_home}/bitbucket-pr.env" \
  --jira-auth-state ready \
  --env-file "${shared_home}/shared.env" \
  --generate-mcp-env stlm-mcp \
  --generate-mcp-env mcp-dope \
  --home-dir "${shared_home}/home" \
  --log-directory "${shared_home}/log" >/dev/null

test -f "${shared_home}/shared.env"
for skill_name in authZ-permissions-yaml-generator bitbucket-pr cm-review codex-bootstrap create-module-knowledge-skills internal-confluence-page jira-ticket mfo-region-build-status object-store oncall-investigation ots-ticket pr-description release-check repository-version-preflight scm-pr; do
  test -L "${shared_home}/skills/${skill_name}"
  test -f "${shared_home}/skills/${skill_name}/SKILL.md"
done
rg -n --fixed-strings "\"${shared_home_real}/home/.env\"" "${shared_home}/config.toml" >/dev/null
rg -n --fixed-strings "\"${shared_home_real}/home/.env.jira-oci\"" "${shared_home}/config.toml" >/dev/null
rg -n --fixed-strings "\"${shared_home_real}/home/.oci\"" "${shared_home}/config.toml" >/dev/null
rg -n --fixed-strings "\"${shared_home_real}/shared.env\"" "${shared_home}/config.toml" >/dev/null
rg -n --fixed-strings 'OCI_CLI_AUTH = "security_token"' "${shared_home}/config.toml" >/dev/null
rg -n --fixed-strings 'OCI_SESSION_AUTO_REFRESH = "true"' "${shared_home}/config.toml" >/dev/null
rg -n --fixed-strings 'OCI_SESSION_AUTO_INTERACTIVE_AUTH = "true"' "${shared_home}/config.toml" >/dev/null
rg -n --fixed-strings 'OCI_SESSION_AUTH_REGION = "us-ashburn-1"' "${shared_home}/config.toml" >/dev/null
rg -n --fixed-strings 'OCI_SESSION_TENANCY_NAME = "bmc_operator_access"' "${shared_home}/config.toml" >/dev/null
rg -n --fixed-strings 'OCI_SESSION_EXPIRATION_MINUTES = "60"' "${shared_home}/config.toml" >/dev/null
rg -n --fixed-strings 'OCI_SESSION_REFRESH_TIMEOUT_SECONDS = "600"' "${shared_home}/config.toml" >/dev/null
rg -n --fixed-strings 'LTS_ENDPOINT = "https://load-testing.us-westjordan-1.ocp.oraclecloud16.com"' "${shared_home}/config.toml" >/dev/null
rg -n --fixed-strings 'LTS_AUTH = "oci"' "${shared_home}/config.toml" >/dev/null
rg -n --fixed-strings 'OCI_PROFILE = "DEFAULT"' "${shared_home}/config.toml" >/dev/null
rg -n --fixed-strings 'OCI_SESSION_AUTH_REGION = "us-westjordan-1"' "${shared_home}/config.toml" >/dev/null
rg -n --fixed-strings '[marketplaces.devplat-plugins]' "${shared_home}/config.toml" >/dev/null
rg -n --fixed-strings '[plugins."mcp-gateway-plugin@devplat-plugins"]' "${shared_home}/config.toml" >/dev/null
rg -n --fixed-strings 'approval_mode = "approve"' "${shared_home}/config.toml" >/dev/null
rg -n 'LOG_DIRECTORY = ".*/log"' "${shared_home}/config.toml" >/dev/null
rg -n --fixed-strings 'Generated by Codex bootstrap for mcp-dope.' "${shared_home}/shared.env" >/dev/null
rg -n --fixed-strings "python3 ${repo_root}/skills/codex-bootstrap/scripts/refresh_auth.py op-token --env-file <this-file>" "${shared_home}/shared.env" >/dev/null
! rg -n --fixed-strings 'Generated by Codex bootstrap for stlm-mcp.' "${shared_home}/shared.env" >/dev/null
! rg -n --fixed-strings 'OCI_CONFIG_FILE=' "${shared_home}/shared.env" >/dev/null
! rg -n --fixed-strings 'OCI_PROFILE=' "${shared_home}/shared.env" >/dev/null
! rg -n --fixed-strings 'OCI_CLI_AUTH=security_token' "${shared_home}/shared.env" >/dev/null
! rg -n '/ABSOLUTE/PATH/TO|<your-' "${shared_home}/shared.env" >/dev/null
for mcp_name in chrome-devtools sqlcl mcp-atlassian-jira-sd mcp-atlassian-jira-oci centralconfluence playwright ots mcp_shepherd lts-mcp; do
  rg -n --fixed-strings "[mcp_servers.${mcp_name}]" "${shared_home}/config.toml" >/dev/null
done

"${python_bin}" "${script_dir}/bootstrap_codex.py" \
  --repo-root "${repo_root}" \
  --codex-home "${browser_home}" \
  --output "${browser_home}/config.toml" \
  --workspace-parent "$(dirname "${repo_root}")" \
  --agents-mode copy \
  --agents-target "${browser_home}/AGENTS.md" \
  --bitbucket-auth-state ready \
  --bitbucket-env-file "${browser_home}/bitbucket-pr.env" \
  --jira-auth-state ready \
  --home-dir "${browser_home}/home" \
  --disable-mcp stlm-mcp \
  --disable-mcp mcp-dope \
  --enable-mcp chrome-devtools >/dev/null

test -f "${browser_home}/config.toml"
! rg -n --fixed-strings '[[skills.config]]' "${browser_home}/config.toml" >/dev/null
for skill_name in authZ-permissions-yaml-generator bitbucket-pr cm-review codex-bootstrap create-module-knowledge-skills internal-confluence-page jira-ticket mfo-region-build-status object-store oncall-investigation ots-ticket pr-description release-check repository-version-preflight scm-pr; do
  test -L "${browser_home}/skills/${skill_name}"
  test -f "${browser_home}/skills/${skill_name}/SKILL.md"
done
rg -n --fixed-strings '[mcp_servers.chrome-devtools]' "${browser_home}/config.toml" >/dev/null
rg -n --fixed-strings -- '--channel=canary' "${browser_home}/config.toml" >/dev/null
rg -n --fixed-strings '[marketplaces.devplat-plugins]' "${browser_home}/config.toml" >/dev/null
rg -n --fixed-strings '[plugins."mcp-gateway-plugin@devplat-plugins"]' "${browser_home}/config.toml" >/dev/null
for mcp_name in sqlcl mcp-atlassian-jira-sd mcp-atlassian-jira-oci centralconfluence playwright ots mcp_shepherd lts-mcp; do
  rg -n --fixed-strings "[mcp_servers.${mcp_name}]" "${browser_home}/config.toml" >/dev/null
done
! rg -n '/ABSOLUTE/PATH/TO|<your-' "${browser_home}/config.toml" >/dev/null
test -f "${browser_home}/agents/software-architect.toml"
rg -n 'agents/software-architect\.toml"' "${browser_home}/config.toml" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/ots-ticket/SKILL.md\`" "${browser_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/jira-ticket/SKILL.md\`" "${browser_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/cm-review/SKILL.md\`" "${browser_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/create-module-knowledge-skills/SKILL.md\`" "${browser_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/internal-confluence-page/SKILL.md\`" "${browser_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/oncall-investigation/SKILL.md\`" "${browser_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/object-store/SKILL.md\`" "${browser_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/pr-description/SKILL.md\`" "${browser_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/repository-version-preflight/SKILL.md\`" "${browser_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/mfo-region-build-status/SKILL.md\`" "${browser_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/release-check/SKILL.md\`" "${browser_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/authZ-permissions-yaml-generator/SKILL.md\`" "${browser_home}/AGENTS.md" >/dev/null

"${python_bin}" "${script_dir}/bootstrap_codex.py" \
  --repo-root "${repo_root}" \
  --codex-home "${copy_home}" \
  --output "${copy_home}/config.toml" \
  --workspace-parent "$(dirname "${repo_root}")" \
  --agents-mode copy \
  --agents-target "${copy_home}/AGENTS.md" \
  --bitbucket-auth-state ready \
  --bitbucket-env-file "${copy_home}/bitbucket-pr.env" \
  --jira-auth-state ready \
  --home-dir "${copy_home}/home" \
  --disable-mcp stlm-mcp \
  --disable-mcp mcp-dope

test -f "${copy_home}/config.toml"
test -f "${copy_home}/AGENTS.md"
! test -L "${copy_home}/AGENTS.md"
! rg -n '/ABSOLUTE/PATH/TO' "${copy_home}/config.toml" >/dev/null
! rg -n --fixed-strings '[[skills.config]]' "${copy_home}/config.toml" >/dev/null
for skill_name in authZ-permissions-yaml-generator bitbucket-pr cm-review codex-bootstrap create-module-knowledge-skills internal-confluence-page jira-ticket mfo-region-build-status object-store oncall-investigation ots-ticket pr-description release-check repository-version-preflight scm-pr; do
  test -L "${copy_home}/skills/${skill_name}"
  test -f "${copy_home}/skills/${skill_name}/SKILL.md"
done
! rg -n --fixed-strings '/.m2/repository' "${copy_home}/config.toml" >/dev/null
for mcp_name in chrome-devtools sqlcl mcp-atlassian-jira-sd mcp-atlassian-jira-oci centralconfluence playwright ots mcp_shepherd lts-mcp; do
  rg -n --fixed-strings "[mcp_servers.${mcp_name}]" "${copy_home}/config.toml" >/dev/null
done
test -f "${copy_home}/agents/software-architect.toml"
rg -n 'agents/software-architect\.toml"' "${copy_home}/config.toml" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/ots-ticket/SKILL.md\`" "${copy_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/jira-ticket/SKILL.md\`" "${copy_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/cm-review/SKILL.md\`" "${copy_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/create-module-knowledge-skills/SKILL.md\`" "${copy_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/internal-confluence-page/SKILL.md\`" "${copy_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/oncall-investigation/SKILL.md\`" "${copy_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/object-store/SKILL.md\`" "${copy_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/pr-description/SKILL.md\`" "${copy_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/repository-version-preflight/SKILL.md\`" "${copy_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/mfo-region-build-status/SKILL.md\`" "${copy_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/release-check/SKILL.md\`" "${copy_home}/AGENTS.md" >/dev/null
rg -n --fixed-strings "\`${repo_root}/skills/authZ-permissions-yaml-generator/SKILL.md\`" "${copy_home}/AGENTS.md" >/dev/null

if env -u BASE_URL -u BITBUCKET_TOKEN -u JIRA_URL -u JIRA_TOKEN -u JIRA_PERSONAL_TOKEN \
  "${python_bin}" "${script_dir}/bootstrap_codex.py" \
  --repo-root "${repo_root}" \
  --codex-home "${test_home}" \
  --output "${test_home}/config.toml" \
  --workspace-parent "$(dirname "${repo_root}")" \
  --agents-mode symlink \
  --agents-target "${test_home}/AGENTS.md" >/dev/null 2>"${test_home}/stderr.log"; then
  echo "Expected MCP validation failure when required flags are omitted." >&2
  exit 1
fi

rg -n --fixed-strings "Default-enabled MCP servers require explicit local settings" "${test_home}/stderr.log" >/dev/null
rg -n --fixed-strings -- "--env-file" "${test_home}/stderr.log" >/dev/null

if env -u BASE_URL -u BITBUCKET_TOKEN -u JIRA_URL -u JIRA_TOKEN -u JIRA_PERSONAL_TOKEN \
  "${python_bin}" "${script_dir}/bootstrap_codex.py" \
  --repo-root "${repo_root}" \
  --codex-home "${test_home}" \
  --output "${test_home}/config.toml" \
  --workspace-parent "$(dirname "${repo_root}")" \
  --agents-mode copy \
  --agents-target "${test_home}/AGENTS.md" \
  --bitbucket-auth-state needs-setup \
  --bitbucket-base-url "https://bitbucket.example.com" \
  --bitbucket-env-file "${test_home}/bitbucket-pr.env" \
  --jira-auth-state needs-setup \
  --jira-oci-base-url "https://jira.oci.oraclecorp.com" \
  --generate-jira-oci-mcp-env \
  --home-dir "${test_home}/home" \
  --disable-mcp stlm-mcp \
  --disable-mcp mcp-dope >/dev/null 2>"${test_home}/auth-stderr.log"; then
  echo "Expected auth validation failure when enabled skills are missing configured auth." >&2
  exit 1
fi

test -f "${test_home}/bitbucket-pr.env"
test -f "${test_home}/home/.env.jira-oci"
rg -n --fixed-strings 'export BASE_URL="https://bitbucket.example.com"' "${test_home}/bitbucket-pr.env" >/dev/null
rg -n --fixed-strings 'export BITBUCKET_TOKEN=""' "${test_home}/bitbucket-pr.env" >/dev/null
rg -n --fixed-strings '# Generated by Codex bootstrap for mcp-atlassian-jira-oci.' "${test_home}/home/.env.jira-oci" >/dev/null
rg -n --fixed-strings 'JIRA_URL="https://jira.oci.oraclecorp.com"' "${test_home}/home/.env.jira-oci" >/dev/null
rg -n --fixed-strings 'JIRA_PERSONAL_TOKEN=""' "${test_home}/home/.env.jira-oci" >/dev/null
rg -n --fixed-strings 'JIRA_SSL_VERIFY="true"' "${test_home}/home/.env.jira-oci" >/dev/null
rg -n --fixed-strings "Enabled skills require configured auth" "${test_home}/auth-stderr.log" >/dev/null
rg -n --fixed-strings "bitbucket-pr (BASE_URL, BITBUCKET_TOKEN)" "${test_home}/auth-stderr.log" >/dev/null
rg -n --fixed-strings "jira-ticket (JIRA_URL and JIRA_PERSONAL_TOKEN in ~/.env and ~/.env.jira-oci)" "${test_home}/auth-stderr.log" >/dev/null

"${python_bin}" "${script_dir}/bootstrap_codex.py" \
  --repo-root "${repo_root}" \
  --codex-home "${undo_home}" \
  --output "${undo_home}/config.toml" \
  --workspace-parent "$(dirname "${repo_root}")" \
  --agents-mode copy \
  --agents-target "${undo_home}/AGENTS.md" \
  --bitbucket-auth-state ready \
  --bitbucket-env-file "${undo_home}/bitbucket-pr.env" \
  --jira-auth-state ready \
  --home-dir "${undo_home}/home" \
  --disable-mcp stlm-mcp \
  --disable-mcp mcp-dope

test -f "${undo_home}/config.toml"
test -f "${undo_home}/AGENTS.md"
test -f "${undo_home}/bitbucket-pr.env"
test -f "${undo_home}/home/.env"
test -f "${undo_home}/home/.env.jira-oci"

"${python_bin}" "${script_dir}/bootstrap_codex.py" \
  --repo-root "${repo_root}" \
  --codex-home "${undo_home}" \
  --output "${undo_home}/config.toml" \
  --workspace-parent "$(dirname "${repo_root}")" \
  --agents-mode copy \
  --agents-target "${undo_home}/AGENTS.md" \
  --env-file "${undo_home}/mcp.env" \
  --generate-mcp-env stlm-mcp \
  --generate-mcp-env mcp-dope \
  --home-dir "${undo_home}/home" \
  --log-directory "${undo_home}/log" >/dev/null

test -f "${undo_home}/mcp.env"

"${python_bin}" "${script_dir}/bootstrap_codex.py" \
  --codex-home "${undo_home}" \
  --output "${undo_home}/config.toml" \
  --agents-target "${undo_home}/AGENTS.md" \
  --home-dir "${undo_home}/home" \
  --undo >/dev/null

! test -e "${undo_home}/config.toml"
! test -e "${undo_home}/AGENTS.md"
! test -e "${undo_home}/skills/codex-bootstrap"
! test -e "${undo_home}/skills/ots-ticket"
! test -e "${undo_home}/skills/authZ-permissions-yaml-generator"
! test -e "${undo_home}/bitbucket-pr.env"
test -e "${undo_home}/home/.env"
! test -e "${undo_home}/home/.env.jira-oci"
! test -e "${undo_home}/mcp.env"

echo "Bootstrap verification passed. Temporary verification directories were cleaned up."
