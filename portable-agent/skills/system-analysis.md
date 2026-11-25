# System Analysis

## Purpose
Analyse an existing system or proposed system: its components, data flows, integration points, user interactions, and technical characteristics. Produce a structured understanding that enables informed decision-making.

## When to use
Invoke when asked to analyse a system, understand how something works, map dependencies, audit the current state, assess technical debt, or when beginning work on an unfamiliar codebase or system.

## Prerequisites
- Access to the system: source code, architecture documentation, deployment configuration, API specs, or running instances.
- Context: what question is the analysis supposed to answer.

## Procedure

1. **Define the analysis scope.** What system or subsystem? What question does the analysis answer? State boundaries explicitly.
2. **Read existing documentation.** Architecture docs, READMEs, API specs, deployment configs, and any prior analysis reports.
3. **Map the components:**
   a. Identify each component: services, applications, databases, queues, caches, external systems.
   b. For each component: purpose, tech stack, data owned, interfaces exposed/consumed.
   c. Deployment model: where does each component run? How is it scaled?
4. **Map the data flows:**
   a. What data enters the system, from where, in what format?
   b. How does data move between components (sync APIs, async events, shared DB, files)?
   c. What data leaves the system, to where?
   d. Where is the authoritative source of truth for each data entity?
5. **Map the integration points:**
   a. External services and APIs consumed.
   b. Protocols, authentication, and contract ownership.
   c. Failure modes: what happens when an integration is down?
   d. Rate limits, SLAs, and cost implications.
6. **Assess the current state:**
   a. Technical debt: outdated dependencies, deprecated patterns, untested code.
   b. Operational concerns: monitoring, alerting, logging, backup, disaster recovery.
   c. Security posture: auth model, data protection, known vulnerabilities.
   d. Performance characteristics: known bottlenecks, scaling limits.
7. **Identify risks and gaps.** Cross-reference against requirements or expected capabilities.
8. **Produce output.** Structured analysis with evidence references.

## Output contract
- System overview: purpose, boundaries, key characteristics.
- Component inventory: Component | Purpose | Tech Stack | Data Owned | Interfaces
- Data flow diagram (text or Mermaid).
- Integration map: External System | Protocol | Auth | Contract Owner | Failure Mode
- Current state assessment: findings by category with severity.
- Risks, gaps, and recommendations.

## Safety and approval gates
- System analysis is analysis — do not modify the system without authorization.
- Do not probe production systems with destructive or high-load operations.
- Flag security findings immediately — especially exposed credentials, unpatched vulnerabilities, or missing auth.
- Distinguish confirmed facts from inferences. Label what you verified vs what you assumed.

## Verification
- Every component is identified with its purpose and interfaces.
- Data flows trace from source to destination with named paths.
- Assertions about the system are supported by evidence (code, config, docs, observation).
- Risks are specific and actionable, not generic.
