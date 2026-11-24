# New Project Workflow

Use for a greenfield request or when evidence confirms there is no existing implementation to continue. Do not assume greenfield because the conversation is new.

## 1. Intake / discovery
- Identify project/client, objective, stakeholders/users, business value, current pain, operating environment and success measures.
- Elicit user journeys, triggers, decisions, exceptions, outputs, permissions, data, integrations, constraints and explicit exclusions.
- Distinguish confirmed requirements, assumptions, unknowns, conflicting statements and deferred items. Ask only high-impact clarifications.

## 2. Requirements baseline
- Consolidate functional requirements, business rules, terminology/domain concepts, roles/authorization, workflows, NFRs, data needs, constraints and acceptance criteria.
- Use IDs where traceability is useful; avoid over-formal artifacts for small work.
- Check completeness, consistency, testability, feasibility, scope and risks.
- Preserve source/decision trace and identify owner for open questions.

## 3. Analysis / domain
- Analyze process and actors; define boundaries, states, invariants and exceptions.
- Model domain concepts before schema; validate definitions with examples.
- Do not invent relationships, constraints, enums, permissions or data requirements.

## 4. Architecture / options
- Derive architecture from requirements and constraints. Compare only credible options.
- Define responsibilities, modules, data ownership, API/integration contracts, runtime, security, failure behavior, observability, scalability and maintainability.
- Prefer minimal architecture; reject premature microservices, speculative abstractions, duplicate memory or parallel PM systems.
- Record material decisions as an ADR using existing canonical project files.

## 5. Plan / readiness
- Sequence vertical slices with dependencies, owners, risks, effort ranges/confidence, acceptance and tests.
- Identify migrations, external integrations, security review, tooling, and approval-sensitive actions.
- Build a developer handoff with scope, requirement IDs, constraints, acceptance, files/modules expected, test plan and next step.
- Ready gate: objective/requirements sufficiently clear, critical design decisions made or explicitly deferred, scope approved, dependencies identified, and implementation authorized.

## 6. Implementation / QA
- Implement only approved slices. Use `implementation.md` and `approval-gate.md`.
- Verify against acceptance, run focused and regression tests, review risks, and update traceability.
- Do not equate code completion with project acceptance.

## Outputs (proportionate)
Intake brief; requirements/baseline; glossary/domain; current/target process; architecture/options/ADRs; risk register; plan/handoff; acceptance and verification evidence; open decisions.
