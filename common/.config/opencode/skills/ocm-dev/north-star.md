# OCM North Star

Primary 2026 doc:
- https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=18171568883

Older (background/context):
- https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12787908822

## 2026 highlights
- Positioning: OCM as a universal migration hub + extensible platform.
- Strategic objectives: cloud revenue + UX + scope beyond VMs; “everything everywhere” (all realms / cross-realm); differentiation via novel migration use cases (e.g., IaC conversion / code migration).
- Execution model: 3 parallel streams:
  1) increase cloud revenue (VMware opportunity + more Oracle destinations)
  2) source/destination expansion (pluggable platform)
  3) migration hub (non-VM use cases)
- Roadmap:
  - Phase 1 FY26–FY27: Windows migration improvements/BYOS network, shapes/pricing integration, automation (Ansible), Cloud Advisor enablement, modular agent work.
  - Phase 2 FY28: **AI-prompt based chat as Migration Assistant on Console** (Q2FY28), Azure→OCI, broader destinations.
  - Phase 3 FY29+: **AI Powered Migration Automation** (Q4FY29), cross-realm OCI→OCI migration, broader workload/network migration.
- Metrics/success: quarterly growth targets for active customers, VM/OCPU migration counts, attributable revenue.
- Risks: exec support for hub unification; VMware pricing changes; competitor parity.

## Streams (what we’re building)

### Stream 1 — Increase Cloud Revenue
- VMware opportunity (Broadcom licensing churn) + expand migration targets (OCI + Oracle destinations like C3).
- Reduce friction: BYOL Windows, BYOS private network/endpoints, shape selection.
- Cost/pricing as product surface: integrate pricing sources; show “OCI vs source” cost computation.

### Stream 2 — Source and Destination Expansion (VMs)
- Build a **pluggable/modular** platform (plugin model per source/destination; reuse existing capabilities).
- Next big source: Azure → OCI.
- Longer-term: OCI → OCI (cross-realm), GCP → OCI, OLVM → OCI.

### Stream 3 — Migration Hub (beyond VMs)
- Treat OCM as the orchestrator/hub for non-VM migrations (without owning every resource’s domain).
- Near-term proving ground: AWS Lambda → OCI Functions.
- Longer-term: network migration (AWS Transform analogue), DB migration integrations (ZDM), containers, bare metal.

## Roadmap (milestones to track)

### Phase 1 (FY26–FY27)
- Q3FY26: BYOL Windows migration improvements; BYOS private network/endpoints; enable all/new compute shapes; integrate with SPS (pricing).
- Q4FY26: cost estimator tool redesign.
- Q1FY27: automate OVA install/maintenance via Ansible.
- Q2FY27: Cloud Advisor enablement.
- Q3FY27: OCM as OCI’s “sales infrastructure” tool.
- Q4FY27: VMware/AWS → C3; pluggable/modular platform (Replication Agent); Lambda → Functions prototype.

### Phase 2 (FY28)
- Q1FY28: pluggable/modular platform (Discovery Agent).
- Q2FY28: **AI-prompt based chat as Migration Assistant on Console**; Lambda → Functions (GA).
- Q4FY28: cross-cluster VMware migration; VMware/AWS → Private Cloud Appliance + Roving Edge; Migrate360 integration.

### Phase 3 (FY29+)
- Q4FY29: **AI Powered Migration Automation**.
- ~Q4FY29: OCI → OCI (cross-realm); GCP → OCI; OLVM → OCI.
- ~Q4FY29: container migration (OpenShift, OKE, OMK); bare metal migration; automated network discovery & migration; DB migration tools integration (ZDM); Azure + GCP Functions migration.

## Product posture notes
- UX pivot: redesign Console plugin for “frictionless” first-time OCI experience.
- Capability pivot: from an “Apple-like” fixed experience to a more configurable “Android-like” experience (e.g., modifiable Terraform scripts).

## Metrics / success criteria (North Star 2026)
- Goals (quarterly): active customers +15%; VM migration count +25%; OCPU migration count +25%; attributable revenue +15%; competitor license cost saved +10%.
- FY26 Q2 status (as written in the doc): active customers +12% (+100% YoY); VM migration count +7% (+156% YoY); OCPU +11% (+141% YoY); ACR for OCM customers ~$100M (+163% YoY); all OCI services ACR $164.2M (+138% YoY).

## Risks / mitigations
- Migration hub directive: needs exec support across orgs to unify tools/systems.
- VMware pricing model change: invest in other source/destinations + on-prem pipeline.
- Competitor parity: platform/framework investment to onboard more combinations.

## How to use this facet
- Map any engineering initiative to a phase/stream.
- For implementation details, see INDEX.md (routing table) or ai/INDEX.md (AI/MCP foundations).
