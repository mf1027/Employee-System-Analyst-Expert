# Review adapters

This document maps the portable workflow to optional review capabilities. Use the first available path and record the selected path in `run.json`.

| Concern | Preferred capability | Confirmed available (this machine, global) | Portable fallback | Required output |
|---|---|---|---|---|
| Goal, status quo, premises, alternatives | `office-hours` | Yes | Ask one-at-a-time intent questions and run the premise/alternative checklists | Goal, premises, alternatives, next assignment |
| Product strategy and scope | `plan-ceo-review` | Yes | Strategy, 10x, scope, regret, and existing-leverage review | Scope decisions, dream-state delta, deferred work |
| UI behavior | `plan-design-review` when UI is detected | Yes | Hierarchy, states, accessibility, content, and interaction review | Design findings and litmus score |
| Architecture, code quality, tests, performance | `plan-eng-review` | Yes | Full architecture, failure-mode, test, and performance passes | Dependency diagram, failure registry, test diagram |
| Developer/API experience | `plan-devex-review` when developer-facing scope is detected | Yes | Journey, TTHW, naming, docs, errors, upgrade review | DX scorecard and checklist |
| Sequential orchestration | `autoplan` | Yes | Execute CEO → Design → Engineering → DX in order | Decision audit trail and phase summaries |
| Independent product voice | `gstack-openclaw-office-hours` | **No — only the base `office-hours` skill exists on this machine; there is no separate OpenClaw variant installed.** Use `office-hours` again as a second pass, or the portable fallback, for a genuinely independent second opinion. | Fresh-context second opinion | Agreement, disagreement, challenged premises |
| Existing behavior reconciliation | `code-behavior-audit` when applicable | **No — exists only as a MYPS-scoped employee skill (`ai-sa-employee/skills/code-behavior-audit.md`), not a global Claude skill.** Available only when working inside the MYPS workspace. | Source/config/docs/memory/DB reconciliation | Behavior evidence and conflicts |
| Persistence/deployment safety | `rollback-readiness-test` when applicable | **No — same as above, MYPS-scoped only** (`ai-sa-employee/skills/rollback-readiness-test.md`). | Additive migration, backup, rollback, and restore drill | Rollback proof and remaining gates |

**"Confirmed available" column verified 2026-08-31** by listing `~/.claude/skills/` directly — re-check
if this file is ever copied to a different machine or a long time has passed, since global skills
can be added/removed independently of this port.

## Adapter rules

1. Detect capabilities before planning. Do not assume a tool, shell, web search, repository, or second model exists.
2. Autoplan already contains the individual review phases; do not run duplicate phases unless one failed or was unavailable.
3. A fallback checklist is lower-confidence than the named review and must be marked as such.
4. Independent reviewers may disagree. Preserve both findings, classify the disagreement, and ask the user before changing a material premise.
5. Never let an external voice write code or mutate the target project.
