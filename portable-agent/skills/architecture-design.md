# Architecture Design

## Purpose
Design the solution at conceptual and logical levels — components, interfaces, integration points, data flows, and key technology decisions — recording each significant decision as an Architecture Decision Record (ADR). Ensure the design satisfies confirmed requirements and NFR constraints, not invented scope.

## When to use
Invoke when asked to design a solution, define architecture, evaluate technology options, propose system structure, or when moving from confirmed requirements to implementation planning.

## Prerequisites
- Confirmed requirements (at least P0 items) — never design against assumed scope.
- Known constraints: existing stack, team skills, budget, timeline, compliance.
- NFR assessment (from `nfr-review`) identifying design-forcing quality attributes.

## Procedure

1. **Read context.** Review requirements, NFR register, risk register, existing architecture, and database documentation.
2. **Confirm scope baseline.** If requirements are still unconfirmed, flag and ask — do not design against assumptions.
3. **NFR → design constraint mapping.** For each design-forcing NFR:
   - State which architecture decision it constrains.
   - Eliminate options that violate design-forcing NFRs.
   - Document the constraint as a given in the relevant ADR.
4. **Identify key design decisions.** These are the choices that, once made, constrain everything downstream:
   - Deployment model (monolith, microservices, serverless, hybrid).
   - Data architecture (single DB, polyglot, CQRS, event sourcing).
   - Integration patterns (sync, async, event-driven, API gateway).
   - Authentication/authorization model (SSO, OAuth2, API key, RBAC/ABAC).
5. **For each key decision, produce an ADR:**
   a. **Context:** what forces are at play.
   b. **Options:** 2–3 viable alternatives with pros/cons.
   c. **Decision:** recommended option with rationale.
   d. **Consequences:** what follows from this decision, positive and negative.
   e. **Trade-offs acknowledged:** what is given up.
6. **Design the components:**
   - Use C4 model levels as appropriate:
     - **L1 (Context):** system boundary, external actors, and integrations.
     - **L2 (Containers):** deployable units, their responsibilities, and tech stack.
     - **L3 (Components):** internal structure — only for complex or disputed boundaries.
   - Describe each component: responsibility, interfaces in/out, data owned.
7. **Map interfaces and integration points:**
   - External APIs consumed and exposed.
   - Data flows between components.
   - Contract ownership and versioning responsibility.
8. **Data architecture:**
   - Database(s), storage, and caching layers.
   - Data models, ownership boundaries, and shared state.
   - Migration and schema evolution strategy.
9. **Cross-cutting concerns:**
   - Logging and observability.
   - Error handling and resilience patterns.
   - Configuration management.
   - Deployment and release strategy.

## Output contract
- Architecture overview: system context, key design decisions (as ADRs), component diagram.
- Component inventory: Component | Responsibility | Tech Stack | Interfaces | Data Owned
- Integration map: Source → Target | Protocol | Contract | Owner
- ADR register: ID | Title | Status | Decision Summary
- Risks and trade-offs acknowledged.

## Safety and approval gates
- Architecture design is planning — do not implement until design is reviewed and approved.
- Do not propose architecture that contradicts confirmed requirements or design-forcing NFRs.
- Flag irreversible decisions (database engine choice, cloud vendor lock-in) explicitly.
- If the design requires capabilities not confirmed in the existing stack or team, flag the gap.

## Verification
- Every design-forcing NFR is addressed by a specific architecture decision.
- Key decisions are captured as ADRs with alternatives and rationale.
- Component responsibilities are clear with no ambiguous ownership of data or behavior.
- Integration points have defined contract ownership.
