---
name: plan-analysis
description: Thoroughly perform evidence-gated root-cause analysis, gap analysis, multi-perspective plan review, and repeated re-audits before implementation.
metadata:
  short-description: Thorough RCA, gap analysis, and plan review
allowed-tools:
  - Read
  - Write
  - Grep
  - Glob
  - Bash
  - AskUserQuestion
---

# Plan Analysis

Use this skill when a user needs a plan that is thorough, exhaustive, independently challenged, and safe to implement. The skill produces an implementation-ready plan and evidence bundle; it does not implement the target project unless a separate request explicitly authorizes that work.

**Ported from `~/.codex/skills/plan-analysis/` (2026-08-31), global to every project on this machine, not MYPS-specific.** The methodology below is unchanged from the source — only the platform-integration seams are adapted for Claude Code. See `references/portable-usage.md` for how to run this same skill under a different LLM/tool if the content is ever copied elsewhere.

**Not the same skill as MYPS's `ai-sa-employee/skills/deep-analysis.md`.** Both do RCA + gap analysis + adversarial review + a verdict, but `deep-analysis` is narrower and MYPS-flavored (no review-adapter orchestration, no `run.json`/artifact-bundle contract, no explicit cycle cap). Use `deep-analysis` for MYPS-scoped work when its own trigger phrases apply; use `plan-analysis` for the fuller, artifact-bundle-backed, multi-cycle version, anywhere.

## Non-negotiable quality contract

- Read all relevant code, configuration, documentation, tests, history, memory, and operational evidence before making a conclusion.
- Analyze every applicable workflow and failure path. Never replace a required pass with "looks good."
- Separate symptoms, confirmed root causes, probable causes, contributing factors, assumptions, and external blockers.
- Require evidence for every closed finding and a testable control for every proposed fix.
- Reconcile contradictions between requirements, code, configuration, docs, and project memory.
- Use independent review voices when available and record missing capabilities explicitly.
- Redact credentials, tokens, private keys, raw secrets, internal diagnostics, and sensitive payloads.
- Prefer reversible changes, explicit interfaces, bounded scope, and observable rollback paths.
- Never convert unavailable evidence into confidence.
- Never promise "100% perfection." Completion means every discoverable critical issue is closed or explicitly blocked, all residual risk is dispositioned, and the evidence limits are stated.

## Operating rules

1. Ask questions one at a time only when the answer materially changes the goal, premise, scope, authorization, or acceptance criteria. **Claude Code integration:** use the `AskUserQuestion` tool for this — it already enforces one-question-at-a-time framing with recommendations and tradeoffs, so there is no separate portable question protocol to run in parallel.
2. Human confirmation is required for premises and material changes to the user's direction.
3. Mechanical decisions may be automated. Taste decisions must include a recommendation and alternatives. A consensus challenge from independent reviewers must be surfaced, not silently applied.
4. Default to plan-only behavior. Do not edit target-project source, apply migrations, deploy, send external messages, or mutate production data. **Claude Code integration:** this is the same rule as Claude Code's own plan-gate. Use `EnterPlanMode` to run Phases 1–5 below, and `ExitPlanMode` to request approval before any write — don't run a second, separate plan-only gate on top of it.
5. If project writes are unavailable, return the same structured artifacts in chat and mark the run non-persistent.

## Workflow

### Phase 1 — Intake and context

Capture the goal, audience, desired outcome, success criteria, in/out of scope, constraints, authorization, current state, evidence sources, unknowns, and external dependencies. Read the repository and its documented memory before asking questions. Record an authority order when sources disagree.

### Phase 2 — Thorough root-cause analysis

For every symptom or requested change, record:

- Expected versus observed behavior.
- Reproduction, affected flow, timeline, and blast radius.
- Candidate causes with supporting and contradicting evidence.
- Source provenance and confidence.
- Classification: `SYMPTOM`, `ROOT_CAUSE_CONFIRMED`, `ROOT_CAUSE_PROBABLE`, `CONTRIBUTING_FACTOR`, `ASSUMPTION`, or `EXTERNAL_BLOCKER`.
- Corrective control, owner, and verification test.

A cause is `ROOT_CAUSE_CONFIRMED` only when its mechanism is evidenced, alternatives have been challenged, it passes a counterfactual check, and the control can be tested.

### Phase 3 — Thorough gap analysis

Inspect every applicable category: product/scope, architecture/code behavior, security/privacy, data/migrations, API/error contracts, UX/accessibility, testing/observability, deployment/rollback, documentation/developer experience, and external integrations/runtime evidence.

Every gap receives a unique ID, severity (`P0`–`P3`), evidence references, impact, existing control, missing control, remediation, owner, verification, and disposition (`OPEN`, `CLOSED`, `ACCEPTED`, `BLOCKED`, or `OUT_OF_SCOPE`).

### Phase 4 — Review adapters

Use available review skills without duplicating work. Read `references/review-adapters.md` for the exact mapping, including which capabilities are actually confirmed installed globally versus MYPS-scoped-only versus needing the portable fallback. When Autoplan exists, preserve its order:

```text
CEO → Design when UI applies → Engineering → DX when developer-facing scope applies
```

Use Office Hours for intent, status quo, premises, and alternatives. Use OpenClaw Office Hours as an independent or fallback product-thinking voice. Add code-behavior, rollback, security, design, or DX reviews when the plan's scope requires them. If a tool is unavailable, execute the portable equivalent checklist and record degradation.

### Phase 5 — Decision-complete plan

The plan must specify the problem, confirmed causes, complete gap registry, existing controls to reuse, alternatives, recommendation, interfaces, schemas, state transitions, data flow, security and error behavior, migration and rollback, tests, acceptance criteria, rollout monitoring, stop conditions, explicit non-scope, external evidence gates, and the next concrete action.

### Phase 6 — Re-audit and convergence

Run a new RCA and Gap Analysis against the plan itself. Check for omitted causes, newly introduced gaps, regressions, unverified assumptions, missing failure or rollback paths, unowned risks, weak tests, scope drift, sensitive-data exposure, and incomplete review coverage. Revise and repeat according to `references/cycle-protocol.md`.

Default to three complete cycles with a hard maximum of five. Escalate a critical finding that survives two cycles. Never claim completion merely because the maximum was reached.

## Completion gate

`COMPLETE` requires:

```text
P0/P1 open findings = 0
high-impact assumptions = evidenced or explicitly blocked
all residual risks = owned and dispositioned
all acceptance criteria = testable
all applicable review phases = completed or degradation-recorded
```

Use `COMPLETE_WITH_RESIDUAL_RISKS` when only non-critical, owned risks remain. Use `NEEDS_INPUT` or `BLOCKED` when completion depends on user decisions, unavailable evidence, or external runtime access.

## Artifacts

When writes are authorized, create `docs/plans/<slug>/` (relative to whatever project the skill is invoked in) containing:

```text
plan.md
rca.md
gap-analysis.md
review-ledger.md
test-rollout.md
run.json
```

Follow `references/evidence-schema.md`. Run `scripts/validate-artifacts.py` before reporting completion. If the project has a memory register or mind-map, update it with the skill path, run status, and evidence links without storing secrets — but do not let this bundle replace or fork a project's own existing ADR/decision-log convention where one already exists (e.g. MYPS's `decisions.md`/`risks.md` lane files); treat the bundle as an additive research artifact, cross-reference it from the project's own log instead of duplicating that log's role.

## Final response

Lead with the completion status and the most important findings. Include artifact paths, unresolved blockers, degradation notes, acceptance evidence, and the required next action. Do not imply that local analysis proves live deployment or external behavior.
