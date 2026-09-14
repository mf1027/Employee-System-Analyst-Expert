# Review adapters

Every run performs the internal review lenses below. Optional adapters add an independent perspective; they are never assumed to be installed and are never invoked automatically.

| Concern | Default internal lens | Optional opt-in adapter | Ledger requirement |
|---|---|---|---|
| Goal, premises, alternatives | Challenge the status quo, user premise, scope, and non-goals | `gstack-office-hours` | Product evidence and changed premise |
| Strategy and scope | Review leverage, sequencing, regret, and deferred work | `gstack-plan-ceo-review` | Scope decision and alternatives |
| UI behavior | Review hierarchy, states, accessibility, content, and interactions when UI applies | `gstack-plan-design-review` | Applicability and design findings |
| Architecture and delivery | Review dependencies, failures, tests, performance, and rollback | `gstack-plan-eng-review` | Engineering findings and test controls |
| Developer-facing behavior | Review onboarding, naming, errors, docs, and upgrade paths when DX applies | `gstack-plan-devex-review` | Applicability and DX findings |
| Full independent sequence | Run the four review lenses in sequence | `gstack-autoplan` | One ordered review record; do not duplicate individual gstack passes |
| Existing MYPS behavior | Reconcile code, configuration, memory, and DB evidence when MYPS applies | `code-behavior-audit` | Behavior evidence or explicit non-applicability |
| MYPS persistence safety | Review migration, backup, rollback, and restore gates when MYPS applies | `rollback-readiness-test` | Rollback proof or remaining gates |

## Adapter policy

1. Record all four internal lenses in `run.json`; mark design and DX `NOT_APPLICABLE` with a reason when they do not apply.
2. Before an optional adapter runs, detect it through the host skill list or its installed `SKILL.md`. Do not rely on a static machine inventory.
3. Gstack adapters require explicit operator opt-in. Warn that their own workflows can prompt, write local gstack state, or propose repository changes. Do not carry out any adapter-proposed write, commit, push, or configuration change under this skill.
4. Record the adapter name, method (`INTERNAL` or `GSTACK`), operator opt-in, side-effect-warning acknowledgement, outcome, findings, and any degradation in `review-ledger.md` and `run.json`. Use `INTERNAL_CHECKLIST` for an internal lens and the exact installed `gstack-*` identifier for an optional adapter.
5. When an opted-in adapter is unavailable or unsuitable, complete the corresponding internal lens and record `DEGRADED` with the capability, reason, impact, and mitigation.
6. Preserve disagreement between internal and optional reviews. Ask the operator before changing a material premise.

## Agent-local companion audits

When the operator explicitly requests `/code-behavior-audit` or `/rollback-readiness-test`, or when
the scoped work is MYPS-specific and the corresponding evidence layer is applicable, read the
companion contract maintained in this repository at:

- `ai-sa-employee/skills/code-behavior-audit.md`
- `ai-sa-employee/skills/rollback-readiness-test.md`

Use `code-behavior-audit` for existing-code input-to-output tracing and authority reconciliation;
use `rollback-readiness-test` for proof of DB, rollback, authenticated API, negative-case, and
integration readiness. These are conditional MYPS companion workflows, not default review adapters,
and any legacy external-path references are not runtime dependencies.
