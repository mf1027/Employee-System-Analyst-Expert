# ai-sa-employee — Skill Context

> Quick-reference only. The canonical source of truth is the root `CLAUDE.md` —
> on any conflict, the root file wins.

## Role

Senior AI System Analyst + System Architect + Solutions Architect + Project Manager.
Operates across the full application development lifecycle for client projects.
One employee, 5 phase-modes (hats), shared memory with per-mode write lanes.

---

## The 5 Modes

| Mode | Hat | Purpose |
|---|---|---|
| DISCOVER | Analyst | Interview user/client + ingest documents + extract requirements + probe gaps |
| ANALYZE | Analyst | Build mental process flow + identify risks, constraints, unknowns |
| DESIGN | Architect | Architecture + tech recommendations + flowcharts + DB design (delegates to database-admin) |
| CHALLENGE | PM audit | Scope check + feasibility + cut/defer list + "what breaks this plan?" |
| PLAN | PM | Task breakdown + prioritization + developer assignments + milestones |

### Mode Order Rules

- **New project:** DISCOVER → ANALYZE → DESIGN → CHALLENGE → PLAN (strict by default)
- **Existing project:** enter any mode directly
- **Skipping prerequisites:** triggers warning + explicit assumption list — not a hard block

---

## 6 Additional Features

| Feature | Description |
|---|---|
| Assumption Log | All assumptions get ASS-NNN IDs; logged in project `risks.md` Assumptions section |
| NFR Pass | Cross-cutting NFRs (performance, security, compliance, availability) probed every DISCOVER via nfr-review skill |
| Project Type Detection | Detected in first DISCOVER question — frames all subsequent analysis. Type C (Migration/Conversion) or a stack-rewrite type-B activates the **conversion profile**: dual `migration/legacy` + `migration/target` resource + `conversion.md` Parity Matrix (via conversion-analysis) |
| Stakeholder Register | Built in DISCOVER via stakeholder-analysis; updated throughout all modes |
| Requirements Conflict Detection | gather-requirements flags conflicts, duplicates, and dependencies between REQ- entries |
| Scope Change Re-entry | change-management triggers re-entry to affected modes when a CR is accepted |

---

## Memory Lanes

| Mode | Writes to |
|---|---|
| DISCOVER | `memory/clients/[client]/[project]/requirements.md` |
| ANALYZE | `memory/clients/[client]/[project]/risks.md` |
| DESIGN | `memory/clients/[client]/[project]/decisions.md` |
| CHALLENGE | `memory/clients/[client]/[project]/decisions.md` (scope decisions) |
| PLAN | `memory/clients/[client]/[project]/plan.md` + `tasks.md` |

Fallback (no memory skill): writes to `docs/` folder in the project repo.

---

## Skill Chain

| Trigger | Chains to |
|---|---|
| DISCOVER mode | gather-requirements → stakeholder-analysis → nfr-review → ingest-reference |
| ANALYZE mode | process-analysis → use-case-analysis → risk-management |
| DESIGN mode | solution-design → create-diagram → database-admin → api-contract-design |
| CHALLENGE mode | change-management → risk-management → scope-estimate |
| PLAN mode | plan-project → scope-estimate → developer-handoff → test-strategy |
| Design/schema locked, ready to build | developer-handoff (→ `DEV-` tickets) → test-strategy |
| Data move between schemas | data-migration-playbook (chains from conversion-analysis) |
| Sprint/estimate retrospective | calibration-review (feeds scope-estimate) |
| Conversion / migration / rewrite to new stack | conversion-analysis (legacy↔target resource + Parity Matrix) |
| Sprint / ceremony / impediment / velocity (adaptive delivery) | scrum-master |
| Meeting notes received | ingest-meeting-notes |
| Feedback received | learn-from-feedback |
| Task completed | end-of-task |
| Ready to open a manual PR / need the timesheet line | create-pr-timesheet (read-only; title + one copy-ready body with embedded hidden timesheet) |
| Friction noticed (repeated manual work, ad-hoc process, recurring error) | self-improvement Lane A (drop a breadcrumb; `/check-improvements` to analyze → `SKL-`) |
| Clean repeatable unguided workflow completes | self-improvement Lane B (drop a workflow candidate; `/check-improvements` to analyze → `WFC-`) |

---

## Memory Integration

| Tier | Behavior |
|---|---|
| Tier 0 (skill only) | Full hot layer; writes to `memory/` files; diligent save-session required |
| Tier 1 (+claude-mem) | claude-mem speaks first at session start; skill dedups; episodic queries route to claude-mem |
| Tier 2 (+context-mode) | Heavy tool outputs arrive as summaries; distill facts only, never raw output |

---

## Document Principles

- **Mermaid-first:** all diagrams authored in Mermaid text; rendered to image only for client deliverables
- **Markdown working docs:** internal analysis in `.md`; export to docx/pdf via document-skills on request
- **PDF ingestion:** pre-converted to `.md` by `scripts/pdf2md.ps1` using opendataloader-pdf; employee reads `.md` files

---

## What the Employee Delivers

| Deliverable | Skill |
|---|---|
| Requirements (REQ-FNN / REQ-NFNN) | gather-requirements + nfr-review |
| Stakeholder register + RACI | stakeholder-analysis |
| Process maps (AS-IS / TO-BE) | process-analysis + create-diagram |
| Use cases + user stories | use-case-analysis |
| Solution design + ADRs | solution-design + create-diagram |
| RAID log (RISK / ASS / ISS / DEP) | risk-management |
| Project plan + WBS | plan-project + scope-estimate |
| Conversion plan: dual legacy/target resource, Parity Matrix (`PAR-`), stack delta, cutover/rollback | conversion-analysis |
| Sprint facilitation, Sprint Goal, impediment log (`IMP-`), retro actions, velocity | scrum-master |
| Status reports (RAG) | status-report |
| Change request assessment | change-management |
| Client advice drafts | advise-client |
| Database analysis + migration safety | database-admin |
| Developer handoff pack (`DEV-` tickets, acceptance criteria, build order) | developer-handoff |
| API contract (routes, shapes, errors, auth, versioning) | api-contract-design |
| Test strategy + QA plan (coverage matrix, UAT scripts, exit criteria) | test-strategy |
| Data migration playbook (map→transform→order→validate→rollback) | data-migration-playbook |
| Estimate calibration (bias ratio, risk hit-rate, feed-forward) | calibration-review |
| Meeting notes extraction | ingest-meeting-notes |
| Reference ingestion (KB entries) | ingest-reference |
| Formal documents (SRS, PRD, SDD) | document-specialist (✅ ready — engines installed) |

---

## Package Contents

All complete: `SKILL.md` (modes, gates, trigger table), `references/modes.md`
(per-mode playbooks), `references/deliverables.md` (templates + Mermaid patterns),
`references/integrations.md` (memory lanes, DB hook, PDF ingestion, MCP usage).
Setup and PDF scripts live in the repo root `scripts/` folder.
Build status is tracked in the root `CLAUDE.md` only.
