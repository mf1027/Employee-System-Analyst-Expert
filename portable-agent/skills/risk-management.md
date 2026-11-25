# Risk Management

## Purpose
Identify, score, and manage risks, assumptions, issues, and dependencies (RAID). Ensure every risk has an owner, mitigation plan, and contingency. Escalate high-severity findings.

## When to use
Invoke when asked to identify risks, update the risk register, assess what could go wrong, log an issue, add a dependency, or when beginning any material project work that requires risk awareness.

## Prerequisites
- A project name or scope description.
- Access to existing requirements, plan, and prior risk records if available.

## Procedure

1. **Read context.** Review existing project documentation, requirements, plan, architecture, and any prior risk records. Identify previously logged risks and their current status.
2. **Identify new risks** across all categories:
   - **Schedule:** dependencies, resource availability, estimation confidence.
   - **Technical:** integration complexity, new technology, vendor stability, performance.
   - **People:** key-person dependency, stakeholder resistance, skill gaps.
   - **Compliance/regulatory:** data residency, audit requirements, legal obligations.
   - **Data/database:** migration locking, data loss, schema breakage, replication.
   - **Commercial:** budget overrun, contract gaps, procurement delays.
   - **Operational:** deployment, monitoring, incident response readiness.
3. **Score each risk:**
   a. Probability (1–5) × Impact (1–5) = Score.
   b. RAG: 🔴 Score ≥ 16 | 🟡 Score 6–15 | 🟢 Score ≤ 5.
   c. Assign an **owner** (a named person or role, not "the team").
   d. Define a **trigger** — the early-warning indicator to watch.
   e. Define a **mitigation** — action to reduce probability or impact now.
   f. For RED risks: define a **contingency** and escalation path.
4. **Log assumptions** with rationale. State what is assumed, why, and what breaks if wrong. Link to affected requirements or plan items.
5. **Log issues** (things already going wrong). Classify: Blocker / High / Medium / Low. Assign owner and target resolution date.
6. **Log dependencies** with owner (internal/external) and due date. Flag critical-path dependencies.
7. **Review existing entries.** Flag any risks, assumptions, issues, or dependencies that are stale, resolved, or superseded.
8. **Produce output.** Present consolidated RAID register.

## Output contract
- Risk register table: ID | Risk | Probability | Impact | Score | RAG | Owner | Trigger | Mitigation | Contingency | Status
- Assumptions table: ID | Assumption | Rationale | Impact if wrong | Status
- Issues table: ID | Issue | Severity | Owner | Target date | Status
- Dependencies table: ID | Dependency | Owner | Due date | Critical path? | Status
- Summary of RED risks with escalation recommendation
- List of stale/resolved entries recommended for closure

## Safety and approval gates
- Risk identification is analysis — no implementation or remediation without authorization.
- Do not invent risks with false numeric precision; explain the reasoning behind scores.
- Avoid generic risks ("project might be late"); each risk should be specific and actionable.
- Reassess when scope, evidence, or project state changes materially.

## Verification
- Every risk has a named owner, not "TBD" or "the team."
- Every RED risk has both mitigation and contingency defined.
- Assumptions link to the requirements or plan items they affect.
- No duplicate entries; superseded items are marked, not deleted.
