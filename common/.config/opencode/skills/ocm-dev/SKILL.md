---
name: ocm-dev
description: Use when maintaining OCM engineering workflows across multiple repos or services and you need the canonical OCM runbooks, shepherd/release anchors, prerequisites context, or TC handoff guidance.
metadata:
  owner: ocm
  last_updated: 2026-03-09
  audience: maintainers
  workflow: ocm, release, shepherd, docs
---

## What I do
- Provide a service/team-level map for OCM engineering work:
  - deploy/release via shepherd
  - operate and troubleshoot (oncall)
  - manage prerequisites stacks (customer onboarding)
  - keep public docs / Confluence aligned (TC handoff)

## When to use me
- You’re an OCM maintainer working across multiple repos (shepherd, runbooks, ops tools, service repos).

## When not to use
- You’re working in a single repo and the answer depends on that repo’s local conventions (commands, pinned tool versions, CI gates). Use that repo’s layered `AGENTS.md` and local docs first.
- You need step-by-step UI clicking guidance for Console/operator tasks. Use the relevant runbook/playbook instead of relying on memory.
- You’re doing generic harness setup or tool governance that isn’t OCM-specific. Prefer the aipack-core `aipack-system` skill or the oracle/mcp repo.

## Verify
- Confirm you’re operating with the **repo-local rules** loaded:
  - The repo has an `AGENTS.md` (or equivalent rules discovery) and it contains the repo-specific commands/versions you should follow.
  - If guidance conflicts, follow the most specific rule closest to the working directory.
- If you changed anything in this pack (skills, agents, rules, workflows, MCP allowlists/templates):
  - Run `aipack doctor` and ensure it exits 0.
- Before sharing guidance broadly:
  - Prefer canonical anchors already listed in this skill (runbooks, shepherd/release process, TC handoff pages) over ad-hoc links.

## Failure modes
- **Symptom:** Advice is too high-level and misses repo-specific reality (different make targets, scripts, pinned versions).
  - **Recovery:** Stop and pivot to the target repo’s `AGENTS.md` / README; re-derive the answer from repo-local commands and validation steps.
- **Symptom:** You don’t have access to a referenced internal system (Confluence/Bitbucket/DevOps), or the tool surface is not enabled.
  - **Recovery:** Use the appropriate ops agent routing described under “Tool routing”, or fall back to “ask for the missing artifact/link” instead of guessing.

## Start here
- `INDEX.md` — consolidated routing table (workflows, Confluence anchors, repos, developer phases)

## Substantive facets
- `ai/` — OCM AI practice, MCP governance, Migration Assistant playbook
- `north-star.md` — OCM North Star 2026 roadmap (streams, phases, metrics)
- `release-terms.md` — release/deployment glossary (15 terms)
- `scripts.md` — oracle-quickstart script inventory (classified by mutability)
- `safety-rubric.md` — script safety classification + preflight checklist
- `cm-operations.md` — manual CM creation/validation (CHANGE project field mappings, process, location alignment)

## Repo anchors (local)
- `ocm-shepherd`: {env:HOME}/src/bb/ocicm/ocm-shepherd
- `ocm-runbooks`: {env:HOME}/src/bb/ocicm/ocm-runbooks
- `ocm-ops-tools`: {env:HOME}/src/bb/ocicm/ocm-ops-tools
- `ocm-onboarding`: {env:HOME}/src/bb/ocicm/ocm-onboarding

## Canonical Confluence anchors (OCM-specific)
- Realm Build Runbook (includes shepherd policies + sequencing): https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12075203796
- Deployment plan (release-cycle tracker): https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19083594114
- OCM on-call: plugin deployment: https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19047080351
- Technical Content dashboard (TC engagement): https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12404907423
- Creating Migration Prerequisites (engineering source): https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=18525161800

## Tool routing
- Use ops agents for Confluence/Bitbucket/DevOps.

## Layering rule (keeps this skill reusable)
- This skill links to “what OCM does” and “where the canonical process lives”.
- For a specific repo’s:
  - commands
  - pinned tool versions
  - validation steps
  - directory layout
  …use that repo’s `AGENTS.md`.
