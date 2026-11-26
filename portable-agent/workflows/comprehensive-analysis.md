# Comprehensive Analysis Workflow

Use this workflow for substantial system/product analysis that requires coordinated requirements, system, process, architecture, RCA, GAP, risk and verification reasoning. It is an orchestration workflow, not another skill or independent analysis engine.

## Ownership

- The workflow owns sequencing and completeness of a comprehensive analysis.
- `requirements-analysis` owns needs, scope and acceptance.
- `system-analysis` owns current-state system tracing and system-level gap analysis.
- `process-analysis` owns business/process flows.
- `diagnosing-bugs` owns defect-specific RCA when an observed failure exists.
- `database-analysis`, `security-review`, `domain-modeling`, `architecture-design`, `api-contract-design`, `nfr-review`, `risk-management` and `test-strategy` are scoped specialists/support procedures only when evidence and scope require them.
- A host-native `plan-analysis` skill may orchestrate this same lifecycle, but it must not create a competing portable skill authority.

## Procedure

1. **Classify scope and depth.** Distinguish quick explanation, bounded analysis and comprehensive analysis. Use this workflow only when broad multi-discipline analysis is warranted.
2. **Recover authority and context.** Read the canonical agent contract, applicable project instructions, approved requirements/decisions/risks, and current project artifacts. Identify unavailable sources explicitly.
3. **Establish the baseline.** Record what is directly observed, user-supplied, inferred, assumed and unknown. Inspect current implementation and relevant consumers before declaring a gap.
4. **Establish the problem and target.** Use `requirements-analysis` when needs, scope or acceptance are unclear. Do not confuse a proposed solution with a requirement.
5. **Trace current state.** Use `system-analysis` as the primary current-state/system-gap procedure. Add `process-analysis` for actor/process/decision/handoff behavior.
6. **Perform RCA only when a symptom/defect/incident exists.** Use `diagnosing-bugs` for the causal chain and discriminating evidence. For a non-defect architecture or capability review, do not manufacture a root cause; report causes of observed gaps as hypotheses with confidence labels.
7. **Load specialists selectively.** Use `database-analysis` for actual schema/data/SQL/migration concerns; `security-review` for threat boundaries; `domain-modeling` for concepts/invariants; `architecture-design` for target architecture; `api-contract-design` for API contracts; `nfr-review` for relevant quality attributes.
8. **Build the gap register.** For each material gap include current evidence, target requirement, impact, priority, recommended remedy, owner/authority, dependencies and acceptance/verification method.
9. **Challenge the analysis.** Test alternative explanations, hidden consumers, null/empty/duplicate cases, concurrency, migration/rollback, permission boundaries, compatibility and simpler alternatives. Stop after a bounded number of review cycles; record unresolved uncertainty.
10. **Assess risk and sequence remediation.** Use `risk-management` and `project-planning` only when a material risk register or implementation roadmap is needed.
11. **Define verification.** Use `test-strategy` to define observable pass/fail criteria. Distinguish structural evidence from live host/model behavior.
12. **Report and stop at the requested mode.** Deliver findings, recommendation, options, implementation sequence and operator decisions. Do not implement unless the user has authorized implementation.

## Output contract

For comprehensive analysis, include: executive verdict; scope/source boundary; evidence ledger; current vs target state; RCA or explicit not-applicable statement; gap register; architecture/process/security/data impacts as relevant; conflict/overlap analysis; options and recommendation; prioritized remediation; acceptance tests; operator decisions; limitations and confidence.

## Failure exits

Stop or downgrade confidence when critical source files, runtime access, schema evidence, project authority or required permissions are unavailable. Never substitute an invented system model or claim that a live test ran when only static inspection was possible.
