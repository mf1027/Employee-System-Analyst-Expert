# Deliverable Templates and Mermaid Patterns

Templates for formal documents and Mermaid diagram patterns.
Load this file when producing SRS, architecture documents, project plans, or diagrams.

---

## SRS — Software Requirements Specification

Use for formal client-facing requirements documents.

```markdown
# Software Requirements Specification
**Project:** [Name]
**Client:** [Name]
**Version:** 1.0
**Date:** [YYYY-MM-DD]
**Author:** [SA name]
**Status:** [Draft / Under Review / Approved]

---

## 1. Purpose
[One paragraph: what this system does, who uses it, why it exists]

## 2. Scope
**In scope:** [List of features/modules included]
**Out of scope:** [Explicit exclusions — each with brief reason]

## 3. Stakeholders
| Role | Name | Responsibility | Sign-off required |
|---|---|---|---|
| [Sponsor] | [Name] | [Budget/decisions] | Yes |
| [End user] | [Name] | [Uses system] | No |

## 4. Functional Requirements
| ID | Requirement | Priority | Acceptance Criteria | Source |
|---|---|---|---|---|
| REQ-F01 | As a [role], I need [outcome] so that [benefit] | P0 | Given [...], When [...], Then [...] | [Stakeholder] |

## 5. Non-Functional Requirements
| ID | Type | Requirement | Target | Notes |
|---|---|---|---|---|
| REQ-NF01 | Performance | [Description] | [Measurable target] | |
| REQ-NF02 | Security | | | |
| REQ-NF03 | Availability | | [e.g., 99.9% uptime] | |

## 6. Assumptions
| ID | Assumption | Risk if wrong |
|---|---|---|
| ASS-001 | [What is assumed] | [What breaks] |

## 7. Constraints
- [Technical, regulatory, budget, or timeline constraints]

## 8. Glossary
| Term | Definition |
|---|---|
| [Term] | [Definition as used in this project] |

---
*Decisions needed:* [List]
*Open questions:* [List]
*Next steps:* [List]
```

---

## Architecture Document

Use for technical architecture deliverables.

```markdown
# Architecture Document
**Project:** [Name]
**Date:** [YYYY-MM-DD]
**Architect:** [Name]
**Version:** 1.0

---

## 1. Architecture Style
[Name the style: monolith / service-oriented / microservices / event-driven / serverless]
**Rationale:** [Why this style fits the NFRs and scale — one paragraph]

## 2. C4 L1 — System Context
[Mermaid C4 context diagram — see Mermaid patterns below]
- Who uses the system?
- What external systems does it integrate with?

## 3. C4 L2 — Containers
[Mermaid C4 container diagram]
- What are the deployable components?
- What tech stack does each use?
- How do they communicate?

## 4. Key Design Decisions (ADRs)
### ADR-001: [Title]
**Context:** [Why a choice was needed]
**Options:**
- A. [Option] — Pros: [...] | Cons: [...]
- B. [Option] — Pros: [...] | Cons: [...]
**Decision:** [Chosen option] — [Reason tied to requirements/constraints]
**Consequences:** [What this enables or rules out]

## 5. Integration Map
| Integration | Direction | Data | Protocol | Owner | Risk |
|---|---|---|---|---|---|
| [System A → B] | Async | [What flows] | [REST/event/DB] | [Team] | Low/Med/High |

## 6. Database Design
[Refer to database.md for full schema]
- Key entities: [List]
- Migration required: [Yes/No]
- HA/DR approach: [Description]

## 7. Security Considerations
[REQ-S entries flagged in security-review — summary here]

## 8. Open Design Questions
1. [Question] — blocks ADR-00X if unresolved
```

---

## Project Plan

Use for project plans and milestone tracking.

```markdown
# Project Plan
**Project:** [Name]
**Client:** [Name]
**Date:** [YYYY-MM-DD]
**PM:** [Name]

---

## Summary
| Item | Value |
|---|---|
| Total PERT estimate | [X weeks] |
| Range | [O–P weeks] |
| Confidence | High / Medium / Low |
| Critical path | [Phase → Phase → Phase] |
| Key risk | [Top RISK- ID] |

## Milestones
| # | Milestone | Deliverable | PERT | Owner | Depends on |
|---|---|---|---|---|---|
| M1 | Requirements sign-off | Approved SRS | — | SA | — |
| M2 | Architecture approved | Architecture doc | 3d | Architect | M1 |
| M3 | DB schema approved | database.md v1 | 1d | DBA | M2 |
| M4 | Sprint 1 complete | [Deliverable] | [Xd] | Dev lead | M3 |

## Work Breakdown Structure
### Phase 1: [Name]
| Task | O | ML | P | PERT | Owner | Depends on |
|---|---|---|---|---|---|---|
| [Task description] | [Xd] | [Xd] | [Xd] | [Xd] | [Name] | — |

### Phase 2: [Name]
...

## RAID Summary
| Type | ID | Description | Owner | Status |
|---|---|---|---|---|
| Risk | RISK-001 | [Description] | [Owner] | Open |
| Assumption | ASS-001 | [Description] | — | Unvalidated |
| Issue | — | — | — | — |
| Dependency | — | External API ready by [date] | [Vendor] | Pending |

---
*Decisions needed:* [List]
*Open questions:* [List]
*Next steps:* [List]
```

---

## Mermaid Diagram Patterns

Chain to `create-diagram` skill for rendering. Always author in Mermaid text first.

### Flowchart — Process Map
```
flowchart TD
    A([Start]) --> B[Step 1\nActor: Role]
    B --> C{Decision?}
    C -- Yes --> D[Step 2a]
    C -- No --> E[Step 2b]
    D --> F([End])
    E --> F

    style A fill:#4CAF50,color:#fff
    style F fill:#4CAF50,color:#fff
    style C fill:#FF9800,color:#fff
```

### Sequence Diagram — Integration Flow
```
sequenceDiagram
    actor U as User
    participant FE as Frontend
    participant API as API Gateway
    participant SVC as Service
    participant DB as Database

    U->>FE: Action
    FE->>API: POST /endpoint
    API->>SVC: processRequest()
    SVC->>DB: query
    DB-->>SVC: result
    SVC-->>API: response
    API-->>FE: 200 OK
    FE-->>U: Updated UI
```

### ERD — Entity Relationship
```
erDiagram
    USER {
        int id PK
        string email UK
        string name
        datetime created_at
    }
    ORDER {
        int id PK
        int user_id FK
        decimal total
        string status
        datetime created_at
    }
    ORDER_ITEM {
        int id PK
        int order_id FK
        int product_id FK
        int quantity
        decimal unit_price
    }

    USER ||--o{ ORDER : places
    ORDER ||--|{ ORDER_ITEM : contains
```

### Gantt — Project Timeline
```
gantt
    title Project Timeline
    dateFormat YYYY-MM-DD
    section Phase 1: Discovery
        Requirements gathering   :a1, 2026-06-15, 5d
        Stakeholder interviews   :a2, after a1, 3d
    section Phase 2: Design
        Architecture design      :b1, after a2, 5d
        DB schema design         :b2, after b1, 2d
    section Phase 3: Build
        Sprint 1                 :c1, after b2, 10d
        Sprint 2                 :c2, after c1, 10d
    section Phase 4: Launch
        UAT                      :d1, after c2, 5d
        Go-live                  :milestone, after d1, 0d
```

### C4 Context Diagram
```
graph TB
    subgraph System ["[System] Your System"]
        CORE[Core Application\nTech: Node.js + React]
    end

    USER([fa:fa-user End User]) --> CORE
    ADMIN([fa:fa-user-shield Admin]) --> CORE
    CORE --> EXT1[External Payment API\nStripe]
    CORE --> EXT2[Email Service\nSendGrid]
    CORE --> DB[(Database\nPostgres)]
```

### C4 Container Diagram
```
graph TB
    USER([User])

    subgraph System ["System Boundary"]
        WEB[Web App\nReact SPA\n:3000]
        API[API Server\nNode.js / Express\n:4000]
        WORKER[Background Worker\nNode.js\n:—]
        DB[(Primary DB\nPostgreSQL)]
        CACHE[(Cache\nRedis)]
        QUEUE[Message Queue\nRabbitMQ]
    end

    USER --> WEB
    WEB -- HTTPS REST --> API
    API --> DB
    API --> CACHE
    API --> QUEUE
    QUEUE --> WORKER
    WORKER --> DB
```

### RAID Log Table (Markdown)
```markdown
## RAID Log
### Risks
| ID | Risk | Likelihood | Impact | Mitigation | Owner | Status |
|---|---|---|---|---|---|---|
| RISK-001 | [Description] | High | High | [Action] | [Name] | Open |

### Assumptions
| ID | Assumption | Risk if wrong | Validated by | Status |
|---|---|---|---|---|
| ASS-001 | [Description] | [Impact] | [Who] | Unvalidated |

### Issues
| ID | Issue | Impact | Owner | Due | Status |
|---|---|---|---|---|---|
| ISS-001 | [Description] | [Impact] | [Name] | [Date] | Open |

### Dependencies
| ID | Dependency | Provider | Due | Status |
|---|---|---|---|---|
| DEP-001 | [Description] | [Name/team] | [Date] | Pending |
```
