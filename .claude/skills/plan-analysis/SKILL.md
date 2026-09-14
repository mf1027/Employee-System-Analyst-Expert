---
name: plan-analysis
description: Produce evidence-backed, client-scoped implementation plans for work managed by this employee agent. Use for thorough root-cause analysis, gap analysis, and plan challenges; not routine lookups or implementation.
metadata:
  short-description: Client-scoped RCA, gap analysis, and planning
allowed-tools:
  - Read
  - Write
  - Grep
  - Glob
  - Bash
  - AskUserQuestion
---

# Plan Analysis

Use this agent-local skill from the Employee System Analyst Expert workspace. It analyzes and plans work for any client project managed under `memory/clients/`; it does not install itself globally, copy itself into a client repository, or modify application code.

## Scope and invocation

- Default to plan-only behavior. Do not edit client source, apply migrations, deploy, send external messages, or create commits or pushes.
- A request may provide a client/project context and a mode. If omitted, use `live` mode and resolve client context only when it materially affects the analysis.
- `live` is the default for an interactive session. `bundle` is used only when the operator explicitly requests persistent evidence or confirms it after being asked.
- For `bundle` mode, resolve `memory/clients/<client>/<project>/` before any write. If it cannot be derived from the active task, ask one question and do not create a fallback directory.

Read [agent usage](references/agent-usage.md) for the client-resolution and persistence contract.

## Quality contract

- Read relevant current source, configuration, tests, history, client memory, and operational evidence before concluding.
- Documentation, comments, and prior write-ups describe the source; re-read the current file, query result, or runtime evidence before citing it as proof.
- Separate symptoms, confirmed and probable causes, contributing factors, assumptions, and external blockers.
- Give every finding evidence, an owner, a disposition, and a testable control. Never turn unavailable evidence into confidence.
- Reconcile contradictions between requirements, code, configuration, and client records. Redact secrets and sensitive payloads from every artifact.
- Prefer reversible changes, bounded scope, explicit interfaces, and observable rollback paths. Do not promise perfection or live-runtime proof that was not obtained.

## Modes

### Live

Run intake, RCA, gap analysis, and a decision-complete plan in chat. Before presenting the plan, perform one mandatory self-challenge: re-read each stated conclusion against its evidence, verify field/metric attribution, and identify missing failure, rollback, or ownership controls. State that this pass ran, what it checked, and the evidence limits. Live mode produces no filesystem writes.

### Bundle

Run the six phases below and persist the evidence bundle only after client context and write authorization are available. Store it at:

```text
memory/clients/<client>/<project>/deliverables/documents/plan-analysis/<slug>/
```

If persistence is unavailable, return the same structured material in chat with `persistence: CHAT_ONLY`; do not write anywhere else.

## Workflow

1. **Intake and authority.** Capture the goal, audience, success criteria, scope, constraints, authorization, evidence sources, unknowns, and source-authority order.
2. **RCA.** Trace expected and observed behavior, affected flows, timeline, blast radius, competing causes, confidence, corrective control, owner, and verification. Mark a cause confirmed only when its mechanism and alternatives are evidenced.
3. **Gap analysis.** Cover applicable product, architecture, security, data, contracts, UX, testing, observability, deployment, rollback, documentation, and integration gaps. Assign `P0`-`P3`, evidence, impact, control, remediation, owner, verification, and disposition.
4. **Review coverage.** Run the internal product, design, engineering, and DX lenses. Mark each applicable or not applicable and record findings. Use optional gstack review skills only after explicit operator opt-in; see [review adapters](references/review-adapters.md).
5. **Decision-complete plan.** Specify causes, alternatives, recommendation, interfaces, state and data flow, security/error behavior, migration/rollback, tests, acceptance criteria, rollout, monitoring, stop conditions, non-scope, and next action.
6. **Re-audit and convergence.** Re-run RCA and gap analysis against the plan. Record changed evidence and unresolved risks. Target three complete cycles and never exceed five; escalate a critical finding that survives two cycles. Follow [the cycle protocol](references/cycle-protocol.md).

## Completion and evidence

Use `COMPLETE`, `COMPLETE_WITH_RESIDUAL_RISKS`, `NEEDS_INPUT`, or `BLOCKED` as defined in [the cycle protocol](references/cycle-protocol.md). A `COMPLETE` result requires closed or explicitly out-of-scope P0/P1 findings and high-impact assumptions, testable acceptance criteria, and completed or degraded applicable reviews. An unresolved high-impact assumption yields `NEEDS_INPUT` or `BLOCKED`, not `COMPLETE`.

For bundle mode, create `plan.md`, `rca.md`, `gap-analysis.md`, `review-ledger.md`, `test-rollout.md`, and `run.json` following [the v2 evidence schema](references/evidence-schema.md). Validate a persisted bundle before reporting completion:

```text
node .claude/skills/plan-analysis/scripts/validate-artifacts.mjs <bundle-directory>
```

## Final response

Lead with the mode, persistence, completion status, and most important findings. Include the client/project context, artifact path when present, review/degradation coverage, evidence limits, residual risks, and the required next action. Do not imply that local analysis proves live deployment or external behavior.
