# Skill: new-project

## Purpose
Create a structured SA/PM project folder for a new engagement. Populates it with
the core deliverable templates the employee reads and updates throughout the project
lifecycle. These are working documents, not client deliverables — they drive the
employee's behavior for this engagement.

## Trigger
Invoke when the operator says "new project", "set up project docs for [name]",
"start a project called [name]", or "create a project folder for [client]".

## Minimum context required
- A project name and a one-line description.
- The client name (to place the folder correctly).
If missing: ask for project name, description, and which client.

---

## Steps

1. Read `memory/clients/[client-name].md` (if it exists) to inherit the client
   context — constraints, domain glossary, comms style.

2. Confirm the project name and folder: `memory/clients/[client-name]/[project-name]/`

3. Gather minimum inputs — ask at most 2 questions if the brief is vague:
   - What is the core problem this project solves?
   - Who are the primary users / beneficiaries?

4. Create the project folder and generate all 9 files populated with what is known.
   Mark unknowns as `[TBC]`.

5. Output a summary of what was created and flag which `[TBC]` items need filling
   before work begins.

---

## Project folder structure

```
memory/clients/[client-name]/[project-name]/
├── README.md            ← Project identity — what, who, why, when
├── requirements.md      ← What must be delivered — REQ- entries, scope, NFRs
├── stakeholders.md      ← Who is involved — power/interest grid, RACI, comms plan
├── risks.md             ← RAID log — RISK/ASS/ISS/DEP entries with owners
├── plan.md              ← Project plan — phases, milestones, WBS, critical path
├── tasks.md             ← Active tasks — owner, status, due, linked REQ-/RISK- ID
├── decisions.md         ← ADRs and decisions log
├── communication.md     ← Comms log — RAG history, escalations, notification log
├── database.md          ← Database context — schemas, migration notes, DB risks
└── deliverables/        ← All outputs sent to or prepared for the client
    ├── reports/         ← Date-stamped RAG status reports
    ├── diagrams/        ← Standalone diagram files (flowcharts, ERDs, Gantt)
    ├── documents/       ← Formal documents (SRS, PRD, SDD) — versioned
    └── pdf/             ← PDF exports (document-skills/pdf output)
```

---

## File templates

### README.md
```markdown
# [Project Name]

## What This Project Is
[One paragraph: the problem being solved, who it's for, and the desired outcome.]

## Client
- **Name:** [Client name]
- **Contact:** [Name, role, channel]
- **Project folder:** memory/clients/[client]/[project]/

## Goals (in priority order)
1. [Primary goal — the one thing that defines success]
2. [Secondary goal]

## Timeline
| Milestone | Target Date | Status |
|---|---|---|
| Requirements sign-off | [TBC] | Pending |
| Solution design approved | [TBC] | Pending |
| UAT | [TBC] | Pending |
| Go-live | [TBC] | Pending |

## Key Links
- Repository: [TBC]
- Staging / demo: [TBC]
- Designs / wireframes: [TBC]

## Employee behaviour notes
[Any project-specific rules: e.g. "Client uses British English",
"No recommendations without cost estimate", "All dates in dd/mm/yyyy"]
```

### requirements.md
```markdown
# Requirements — [Project Name]

## Confirmed Scope

### Must Have (P0)
- REQ-F01 — [Requirement] — Accepted by: [TBC]

### Should Have (P1)
- [ ] [TBC]

### Nice to Have (P2)
- [ ] [TBC]

## Explicitly Out of Scope
- [Item] — Reason: [TBC]

## Non-Functional Requirements
| ID | Requirement | Target | Notes |
|---|---|---|---|
| REQ-NF01 | [Performance] | [TBC] | |
| REQ-NF02 | [Security / compliance] | [TBC] | |
| REQ-NF03 | [Availability] | [TBC] | |

## Assumptions
1. [TBC]

## Acceptance Criteria
| REQ- | Feature | Criteria | Verified by |
|---|---|---|---|
| REQ-F01 | [Feature] | [Specific, testable condition] | [UAT / automated test] |
```

### stakeholders.md
```markdown
# Stakeholders — [Project Name]

## Stakeholder Register
| Name | Role | Power | Interest | Engagement Strategy |
|---|---|---|---|---|
| [TBC] | [Sponsor] | High | High | Manage closely — weekly decisions sync |
| [TBC] | [End user rep] | Low | High | Keep informed — include in UAT |

## RACI
| Decision / Deliverable | Responsible | Accountable | Consulted | Informed |
|---|---|---|---|---|
| Requirements sign-off | SA/PM | [Sponsor] | [TBC] | [TBC] |
| Go-live approval | SA/PM | [Sponsor] | [TBC] | [TBC] |

## Comms plan
| Audience | Frequency | Channel | Format |
|---|---|---|---|
| [Sponsor] | Weekly | [Email/Slack] | RAG status report |
| [TBC] | [TBC] | [TBC] | [TBC] |
```

### risks.md
```markdown
# RAID Log — [Project Name]

## Risks
| ID | Risk | Category | P | I | Score | RAG | Response | Owner | Status |
|---|---|---|---|---|---|---|---|---|---|
| RISK-001 | [TBC] | [Schedule/Technical/Vendor/DB] | [1-5] | [1-5] | [P×I] | 🟡 | Mitigate | [TBC] | Open |

## Risk Details

### RISK-001 — [Risk Name]
- **Description:** [What could go wrong]
- **Trigger:** [Leading indicator]
- **Mitigation:** [Preventive action]
- **Contingency:** [What we do if it happens]

## Assumptions
| ID | Assumption | Risk if wrong |
|---|---|---|
| ASS-001 | [TBC] | [TBC] |

## Issues
| ID | Issue | Impact | Owner | Due | Status |
|---|---|---|---|---|---|
| ISS-001 | [TBC] | [TBC] | [TBC] | [TBC] | Open |

## Dependencies
| ID | Dependency | Owner | Due | Status |
|---|---|---|---|---|
| DEP-001 | [TBC] | [TBC] | [TBC] | Pending |
```

### plan.md
```markdown
# Project Plan — [Project Name]

## Phases & Milestones
| Phase | Milestone | Target Date | Status |
|---|---|---|---|
| Discovery | Requirements sign-off | [TBC] | Not started |
| Design | Solution design approved | [TBC] | Not started |
| Delivery | MVP ready for UAT | [TBC] | Not started |
| Go-live | Production deployment | [TBC] | Not started |

## WBS (high level)
1. Discovery
   - 1.1 Stakeholder interviews
   - 1.2 Requirements elicitation
   - 1.3 Requirements sign-off
2. Design
   - 2.1 Process analysis (as-is / to-be)
   - 2.2 Solution design + ADRs
   - 2.3 Design approval
3. Delivery
   - 3.1 [TBC]
4. Test & Go-live
   - 4.1 UAT planning + execution
   - 4.2 Go-live readiness review
   - 4.3 Go-live + hypercare

## Critical Path
[TBC — identify after milestones and dependencies are confirmed]

## Estimates
| Work package | Optimistic | Most likely | Pessimistic | PERT |
|---|---|---|---|---|
| [TBC] | | | | |
```

### decisions.md
```markdown
# Decisions Log — [Project Name]

## Architecture Decision Records (ADRs)

### ADR-001 — [Decision title]
- **Status:** [Proposed / Accepted / Superseded]
- **Context:** [The situation and why a decision was needed]
- **Options considered:** [List]
- **Decision:** [What was decided]
- **Consequences:** [What this means going forward]
- **Date:** YYYY-MM-DD

## General decisions
| Date | Decision | Rationale | Owner |
|---|---|---|---|
| [TBC] | | | |
```

### tasks.md
```markdown
# Active Tasks — [Project Name]

## Current Tasks
| ID | Task | Owner | Due | Status | Linked |
|---|---|---|---|---|---|
| TASK-001 | [TBC] | [TBC] | [TBC] | Not started | REQ-/RISK- |

## Completed Tasks
| ID | Task | Completed | Notes |
|---|---|---|---|
| | | | |

## Action Items (from meetings)
| Source | Action | Owner | Due | Done? |
|---|---|---|---|---|
| [YYYY-MM-DD meeting] | [TBC] | [TBC] | [TBC] | [ ] |
```

### communication.md
```markdown
# Comms Log — [Project Name]

## RAG Status History
| Date | RAG | Summary | Sent by | Sent to |
|---|---|---|---|---|
| [TBC] | 🟢 | Project initiated | [TBC] | [Sponsor] |

## Escalation Log
| Date | ID | Issue/Risk | Escalated to | Resolution | Status |
|---|---|---|---|---|---|
| [TBC] | RISK-/ISS- | [TBC] | [TBC] | [TBC] | Open |

## Notification Log
| Date | Event | Notified | Channel | Notes |
|---|---|---|---|---|
| [TBC] | CR-NNN accepted | [Stakeholders] | Email | |

## Comms decisions
| Date | Decision | Rationale |
|---|---|---|
| [TBC] | [TBC] | [TBC] |
```

### database.md
```markdown
# Database Context — [Project Name]

## Overview
- **Platform(s):** [e.g. PostgreSQL 15 on AWS RDS — or TBC]
- **Environment:** [Cloud provider, region — or TBC]
- **Approximate size:** [Row counts / storage — or TBC]

## Schema notes
[Known tables, relationships, or constraints relevant to this project — or TBC]

## Migration plan
| Migration | Description | Risk | Status |
|---|---|---|---|
| [TBC] | | | Pending |

## DB-specific risks
| ID | Risk | Type | Notes |
|---|---|---|---|
| RISK-DB01 | [TBC] | [Lock/Data loss/Replication] | |

## Performance notes
[Known slow queries, index gaps, connection pool settings — or TBC]

## Compliance notes
[Data residency, encryption, audit logging requirements — or TBC]
```

---

## Output format

```
PROJECT INITIALISED: [Client] / [Project Name]

Folder: memory/clients/[client]/[project]/

Files created:
  ✓ README.md           — Project identity and employee behaviour notes
  ✓ requirements.md     — REQ- entries, scope, NFRs, acceptance criteria
  ✓ stakeholders.md     — Register, RACI, comms plan
  ✓ risks.md            — RAID log (RISK/ASS/ISS/DEP entries)
  ✓ plan.md             — Phases, milestones, WBS, critical path
  ✓ tasks.md            — Active tasks, action items, owner + due tracking
  ✓ decisions.md        — ADRs and decisions log
  ✓ communication.md    — RAG history, escalation log, notification log
  ✓ database.md         — DB context, migration plan, DB risks
  ✓ deliverables/       — Output folders ready:
      reports/          ← RAG status reports (YYYY-MM-DD-status-report.md)
      diagrams/         ← Standalone diagram files (YYYY-MM-DD-[type]-[name].md)
      documents/        ← Formal docs — SRS, PRD, SDD (YYYY-MM-DD-[name]-v1.md)
      pdf/              ← PDF exports (YYYY-MM-DD-[name].pdf)

[TBC] items to resolve before work begins:
  - requirements.md: [specific gaps]
  - plan.md: [milestone dates not set]
  - database.md: [platform unknown]
```

## Failure exit
"Cannot create project folder without a project name and client name."
