# Project Planning

## Purpose
Build a structured project plan — phases, milestones, work breakdown structure (WBS), schedule, critical path, and resource needs — grounded in confirmed requirements and known risks, not assumptions.

## When to use
Invoke when asked to create a project plan, build a timeline, define phases and milestones, estimate effort, build a WBS, or when structuring the delivery approach for confirmed requirements.

## Prerequisites
- A project name and confirmed scope (at least rough requirements baseline).
- Known constraints: deadline, budget, team size, skill availability.
- Risk register (if available).

## Procedure

1. **Read context.** Review requirements, risk register, architecture, and any existing plan or constraints documentation.
2. **Confirm scope baseline.** If requirements are still unconfirmed, flag it — never plan against assumed scope. Ask the operator to confirm before proceeding.
3. **Build the Work Breakdown Structure (WBS):**
   a. Decompose into phases (e.g., Discovery, Design, Build, Test, Deploy).
   b. Decompose each phase into work packages.
   c. Decompose each work package into estimable tasks.
   d. Each task should be independently deliverable and verifiable.
4. **Estimate each work package:**
   - Three-point estimation: Optimistic (O) / Most Likely (M) / Pessimistic (P).
   - PERT estimate: (O + 4M + P) / 6.
   - Flag high-variance estimates (wide O–P spread) as risk items.
5. **Sequence tasks with dependencies.** Identify:
   - Hard dependencies (must complete A before starting B).
   - Soft dependencies (preferred order but not required).
   - External dependencies (third-party delivery, approvals, infrastructure).
6. **Identify the critical path** — the longest chain of dependent tasks that determines the minimum project duration. Flag tasks on the critical path as schedule-sensitive.
7. **Set milestones** tied to deliverables:
   - Each milestone is a verifiable completion point, not just a date.
   - Include decision gates (scope sign-off, design approval, UAT sign-off).
8. **Resource mapping:**
   - Required skills per work package.
   - Availability constraints and key-person dependencies.
   - Concurrent workload limits.
9. **Risk integration:** Feed planning risks (high-variance estimates, external dependencies, key-person risk) into the risk register.
10. **Present the plan.** Wait for confirmation before writing to project files.

## Output contract
- WBS: Phase | Work Package | Task | Estimate (days) | Dependencies | Milestone | Owner
- Critical path identification.
- Milestone schedule: Milestone | Deliverable | Target Date | Decision Gate?
- Resource requirements summary.
- Planning assumptions and risks.

## Safety and approval gates
- Planning is analysis — do not begin implementation based on a plan alone without authorization.
- Distinguish confirmed effort estimates from assumptions.
- Flag milestones that depend on external delivery or approvals.
- If the plan exceeds the deadline constraint, present options (scope reduction, phasing, resource addition) instead of silently accepting risk.

## Verification
- Every task has an estimate and at least one verifiable completion criterion.
- Critical path is identified and flagged.
- Milestones are deliverable-based, not just date-based.
- Risks from high-variance estimates are logged.
