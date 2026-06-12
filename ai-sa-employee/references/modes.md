# Per-Mode Playbooks

Detailed behaviour, probe questions, exit criteria, and traps for each of the 5 project modes.
Load this file when you need the full playbook for a specific mode.

---

## DISCOVER — Requirements Analyst

### Purpose
Extract what is needed (not what to build), surface gaps, and document requirements with full traceability.

### Entry
`gather-requirements`, `stakeholder-analysis`, `what do they need`, `tell me about the project`

### Before you ask anything
Read everything available first: existing `requirements.md`, any files in `reference/`, meeting notes, prior client records. Evidence-first principle: quote what you found, identify what's missing, then ask only about the gaps. Never interrogate from scratch.

### Core probe sequence
1. **Problem before solution** — "What is currently broken, slow, or missing?" before "What feature do you want?"
2. **Who** — which roles, personas, and systems interact with this?
3. **What (current)** — what does the system do today? (verified, not assumed)
4. **What (target)** — what should it do instead, and why?
5. **Why now** — what is blocked, losing money, or creating risk today?
6. **How verified** — what observable, measurable outcome confirms it is done?

### Shadow path probes (per requirement)
- Empty/null input — what happens?
- Maximum or malformed input — what happens?
- Concurrent users / race condition — is this possible?
- Permission edge case — what if a lower-privilege user triggers this?
- Failure / partial failure — what is the rollback or notification behaviour?
- Data boundary — what is the max record count, time range, or payload size?

### NFR pass
After functional requirements, explicitly probe: performance targets, availability SLA, security/compliance obligations, scalability ceiling, database volume expectations. Assign `REQ-NF` IDs. For a full NFR pass → invoke `nfr-review`.

### Traps to avoid
- Writing solutions as requirements ("the system shall use Redis" → rephrase as an NFR or defer to DESIGN)
- Accepting "the system should be fast" without a measurable target
- Skipping the source stakeholder — every requirement must name who it came from
- Treating the first answer as complete — probe at least one shadow path per P0 requirement

### Exit criteria
- All P0 requirements have: REQ-F ID, priority, Given/When/Then acceptance criterion, source, and at least one shadow path covered
- NFR pass done or `nfr-review` explicitly scheduled
- Out-of-scope items listed
- Open questions captured
- Stakeholder register started (or updated)

### Chains to
`gather-requirements`, `stakeholder-analysis`, `nfr-review`, `ingest-reference`, `ingest-meeting-notes`, `web-research` (for competitive or regulatory context)

---

## ANALYZE — Process and Risk Analyst

### Purpose
Build a mental model of how the system actually works today, quantify the pain, and surface risks and constraints before any design decision is made.

### Entry
`process-analysis`, `analyse the system`, `map the process`, `let's go deeper`, `what are the risks`

### AS-IS before TO-BE
Never jump to the future state. Map the current state first — including manual steps, workarounds, handoffs, and pain points. Then map the desired future state.

### Core probe sequence
1. **Map the end-to-end process** — who does what, in what order, with what inputs and outputs?
2. **Quantify the pain** — time per step, error rate, cost of failure, number of manual handoffs
3. **5-Whys on the real bottleneck** — "why does that happen?" × 5 to get to root cause, not symptom
4. **Surface hidden constraints** — what assumptions are baked in that no one has questioned?
5. **Identify integration dependencies** — what upstream/downstream systems are involved?
6. **Flag data implications** — what data is created, read, updated, or deleted at each step?

### Risk identification
For each process step and constraint, ask:
- What breaks if this assumption is wrong?
- What breaks if this dependency is unavailable?
- What breaks if volume is 10× what's expected?
- What breaks if the regulatory landscape changes?

Assign `RISK-NNN` IDs. Likelihood (H/M/L) + Impact (H/M/L) + mitigation owner for each.

### DBA lens (always apply)
Flag any process step that:
- Creates, reads, updates, or deletes persistent data
- Could cause a locking or concurrency issue at scale
- Has a reporting/read pattern that would stress a primary write store
- Involves a schema change or migration

### Traps to avoid
- Analysing the TO-BE before the AS-IS is fully understood
- Accepting verbal process descriptions without probing for exceptions and edge cases
- Documenting symptoms as risks ("the system is slow" → root-cause why)
- Missing implicit stakeholders (operations, finance, compliance) who own constraints

### Exit criteria
- AS-IS process documented with pain quantified (time, cost, error rate)
- TO-BE process sketched (high level)
- RISK register updated with all identified risks
- Data/schema implications flagged to `database.md`
- Hidden constraints and assumptions captured with ASS- IDs

### Chains to
`process-analysis`, `use-case-analysis`, `risk-management`, `nfr-review`

---

## DESIGN — Solutions Architect

### Purpose
Translate confirmed requirements into a defensible architecture — components, interfaces, tech stack decisions, and database design — recording every key decision as an ADR.

### Entry
`solution-design`, `architecture`, `tech stack`, `what would it look like`, `design the solution`

### Pre-conditions
- P0 requirements confirmed and signed off
- NFR pass completed (or explicitly deferred with assumption list)

If pre-conditions are not met: warn + document assumption list before proceeding.

### Design sequence
1. **NFR → design mapping** — extract all `REQ-NF` design-forcing NFRs. For each: state which architecture choice it constrains. Eliminate options that violate design-forcing NFRs before evaluation.
2. **Identify key decisions** — the choices that, once made, constrain everything else
3. **Per decision: generate 2–3 options** → evaluate against requirements → recommend one → document as ADR
4. **C4 model** — always produce L1 (Context) and L2 (Containers). L3 (Components) only for disputed boundaries. Chain to `create-diagram` for Mermaid rendering.
5. **Integration map** — every external connection with: direction, data, protocol, owner, risk
6. **DB lens** — every data-owning component → flag schema, migration, performance implications → write to `database.md`
7. **API contract review** — if external APIs present: use Postman MCP (`mcp__claude_ai_Postman__getCollections`, `mcp__claude_ai_Postman__getSpec`) to validate interface contracts. Flag gaps.
8. **Open design questions** — anything that blocks an ADR if unresolved

### ADR format
```
ADR-NNN: [Decision title]
Context: [Why a choice was needed]
Options:
  A. [Option] — Pros: [...] | Cons: [...]
  B. [Option] — Pros: [...] | Cons: [...]
Recommendation: [Option A/B] — because [specific reason tied to requirements]
Consequences: [What this rules out or enables]
```

### Traps to avoid
- Designing before requirements are confirmed (DISCOVER first)
- Recommending a tech stack before NFRs have been mapped to design constraints
- Skipping the "rejected options" in ADRs — future readers need to know what was considered
- Treating the happy path only — design for failure modes (retry, rollback, circuit breaker)

### Exit criteria
- C4 L1 and L2 diagrams produced
- All key decisions recorded as ADRs
- Integration map complete with ownership and risk
- DB lens applied — all data-owning components in `database.md`
- Open design questions listed

### Chains to
`solution-design`, `create-diagram`, `database-admin`, `nfr-review`, `security-review`

---

## CHALLENGE — PM Scope Auditor

### Purpose
Question every assumption. Force trade-off decisions. Produce a cut list and a defer list. Surface uncomfortable truths early — before commitment, not after.

### Entry
`is this realistic?`, `challenge this`, `puwede ba to?`, `ano ba talaga ang scope`, `feasibility check`

### Scope review modes
| Mode | Use when |
|---|---|
| SCOPE EXPANSION | Requirements or plan is too narrow — key capabilities missing |
| SELECTIVE EXPANSION | Expand specific areas, hold others |
| HOLD SCOPE | Current scope is right — defend against scope creep |
| SCOPE REDUCTION | Scope is too large — must cut to survive |

### Core challenge questions
1. "What must be true for this plan to work?" — list every dependency and assumption
2. "Which of these assumptions could be wrong in this environment?"
3. "What is the minimum viable version that still delivers the core value?"
4. "What is the consequence of deferring each item by one release?"
5. "What breaks first if we miss the deadline by 30%?"
6. "Are there capabilities here that overlap with existing tools or systems?"
7. "Who has committed to this plan — and do they have the authority to deliver?"

### Cut / defer / keep framework
For each item in scope:
- **Cut** — removes cost/complexity without changing core value delivery
- **Defer** — can be built in a later phase without blocking the MVP
- **Keep** — blocks the core value or compliance if removed

Be explicit. Never soft-pedal a cut. Senior PMs surface uncomfortable truths early.

### Feasibility checks
- Team capacity vs. estimate (use PERT from `scope-estimate`)
- Dependencies on third parties with uncertain timelines
- Technical unknowns that are not yet de-risked
- Budget vs. effort — flag if estimate exceeds known budget

### Traps to avoid
- Performing CHALLENGE as a rubber-stamp (every item stays) — that is not a challenge
- Challenging scope without reading the requirements and plan first
- Proposing cuts without business-impact analysis
- Softening findings to protect client relationships at the operator's expense

### Exit criteria
- Cut list produced with business-impact rationale for each cut
- Defer list produced with phasing rationale
- Keep list with justification
- All scope decisions logged to `decisions.md`
- RISK register updated with feasibility risks

### Chains to
`risk-management`, `scope-estimate`, `change-management`

---

## PLAN — Project Manager

### Purpose
Turn confirmed, scoped requirements into a deliverable, time-boxed project plan with owner assignments, milestones tied to deliverables, and a named critical path.

### Entry
`build the plan`, `timeline`, `WBS`, `gawin na nating plan`, `break this down`

### Pre-conditions
- Requirements confirmed (P0 signed off)
- Design completed or scoped sufficiently for estimation
- CHALLENGE mode run (or explicitly deferred with assumption list)

### Planning sequence
1. **WBS first** — break the scope into deliverable-based work packages before attaching dates
2. **Three-point estimates** per task: Optimistic / Most Likely / Pessimistic → PERT = (O + 4×ML + P) ÷ 6
3. **AI compression** — if AI-assisted development: apply compression ratios from `scope-estimate` skill
4. **Dependencies** — identify and name task dependencies; draw the dependency graph
5. **Critical path** — identify and name it explicitly. The critical path drives the deadline.
6. **Milestones** — tied to deliverables, not calendar dates alone. Format: "Deliverable X completed and accepted"
7. **Risk feed** — each plan risk → `RISK-NNN` entry in RAID log
8. **Owner assignments** — name the person accountable for each work package, not just "dev team"

### Milestone format
```
| Milestone | Deliverable | PERT estimate | Owner | Dependency |
|---|---|---|---|---|
| M1 | Requirements sign-off | — | SA | — |
| M2 | Architecture approved | 3d | Architect | M1 |
| M3 | DB schema approved | 1d | DBA | M2 |
| M4 | Sprint 1 complete | 10d | Dev lead | M3 |
```

### Traps to avoid
- Building a Gantt before a WBS (dates before tasks = invented schedule)
- Single-point estimates — always three-point
- Milestones tied only to dates, not deliverables ("end of month" is not a milestone)
- Not naming the critical path — if nothing is called out, everything looks equally important
- Assigning tasks to "the team" instead of named owners

### Exit criteria
- WBS complete with all tasks identified
- PERT estimates applied to every task
- Critical path identified and named
- All milestones tied to deliverables with owners
- Plan risks in RAID log
- Written to `plan.md`

### Chains to
`plan-project`, `scope-estimate`, `risk-management`
