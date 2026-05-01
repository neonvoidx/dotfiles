# MCP Server Inventory

From AI Adoption page (pageId=18485604686):

| MCP Server | What it provides | Key reference |
|---|---|---|
| atlassian-mcp | Jira/Confluence (issues, pages, comments, search) | pageId=19068724656 |
| bitbucket-mcp | Bitbucket Server (browse, search, PR workflows) | pageId=17328607595 |
| devops-mcp (DOPE) | OCI DevOps operational surfaces (uses operator token) | pageId=15620655155 |
| oci-ops-cli-mcp | Internal OCI CLI for substrate+overlay (Tier 1-3 operators) | pageId=CLOUDSHELL:OCI-OPS+MCP+Installation+Guide |
| oci-kb-mcp | OCI internal documentation queries | pageId=19107448073 |
| ots-mcp | Oracle Ticketing System (uses OCI session token) | pageId=15773600623 |
| oci-mcp | OCI customer-facing MCP | github.com/oracle/mcp |
| maven | Maven artifact versions + Javadoc retrieval | OHAI_CLINICAL/mcp-common repo |

Also: STLM MCP server (Platform org) for PreCAR/ECAR review.

**oci-ops SCM use case confirmed (2026-03-18):** `oci-ops mcp --profile <profile>` exposes modular service tools. Known services: scm, sccp, ssv2, ticketing, shepherd, jira, runbooks. Do NOT set OCI_OPS_SERVICES to "ALL" — thousands of tools overwhelms LLM context and causes 500 errors. Setup guide: confluence.oraclecorp.com/confluence/display/CLOUDSHELL/OCI-OPS+MCP+Installation+Guide.

**OCI KB internal docs MCP (2026-02):** Agent-friendly markdown KB for OCI internal tooling. Repo: devops.oci.oraclecorp.com/t/Fp96Fx (WFaaS, metrics). Evolution: MCP backed by GenAI service RAG tool with ALL internal developer docs. Code: devops.oci.oraclecorp.com/t/Zm_nnQ. Cross-tenancy BOAT access policy enables any BOAT user to query.

**NOT available via MCP or OCI CLI:** OCI Build Service (`devops.oci.oraclecorp.com/build`). Build logs must be downloaded manually from the UI. `oci devops` CLI commands target the OCI DevOps managed service, which is a separate system.

Config matrix for Codex/Cline: pageId=19529341022 (CPLAT space)
