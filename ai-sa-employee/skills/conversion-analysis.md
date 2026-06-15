# Skill: conversion-analysis

## Purpose
Drive an application **conversion / re-platforming / migration** project — rewriting or porting
an existing ("legacy") application into a new language or stack (e.g. PHP→Node, AngularJS→React,
monolith→microservices, on-prem→cloud, MySQL→PostgreSQL). These projects have a fundamentally
different shape than greenfield builds: **two systems exist at once**, and success =
*functional parity + intentional, signed-off improvement — proven, not assumed*. This skill
sets up the dual document resource (legacy vs target), builds the **Parity Matrix** so nothing is
silently dropped, and runs the conversion-specific discovery so every necessary requirement is
captured.

> Not a developer role: the employee does not write the migration code. It analyses the legacy
> system, designs the target, governs parity/data/cutover, and hands the developer a spec where
> every legacy capability has a tracked target equivalent and a verification method.

## Trigger
Invoke when the operator says:
- "convert / migrate / port / re-platform / rewrite [app] to [language/stack]"
- "legacy modernization", "lift and shift", "strangler", "rebuild the old system in [X]"
- engagement type **C (Migration)**, or a type **B (Enhancement)** that is actually a
  language/stack rewrite
- "old docs and new docs", "set up the legacy/target resource", "parity matrix"

## Minimum context required
- The client + project, the **source (legacy) stack**, and the **target stack**.
If missing: ask "Which project, and what's the from→to stack (e.g. PHP/Laravel → Node/NestJS)?"

---

## What makes a conversion project different (the operating premise)
1. **Two systems, one truth.** Legacy docs describe what *is*; target docs describe what *will be*.
   Conflating them is the #1 failure mode — a legacy doc is not a target requirement.
2. **The code is often the spec.** Real business rules are buried in legacy code with no doc.
   Surfacing them is the core analysis work.
3. **Parity is the contract.** Every legacy capability must be explicitly accounted for —
   migrated, deliberately changed, or deliberately dropped. Never accidentally lost.
4. **Reversibility.** A cutover without a rollback is a gamble, not a plan.

---

## Steps

1. **Read context.** `memory/memory.md`, `memory/clients/[client]/[client].md`, and the project's
   `README.md`, `requirements.md`, `decisions.md`, `risks.md`, `database.md`. Search claude-mem:
   `mem search "[project] legacy target parity"` (filter `system:legacy` vs `system:target`).
2. **Confirm the conversion profile** — source stack → target stack, and the *reason* for converting
   (EOL stack, performance, hiring pool, cost, scalability). Log the reason as an `ADR-` (it frames
   every later trade-off).
3. **Set up the dual resource** (if not already present) — the project's `migration/` folder:
   ```
   [project]/migration/
   ├── legacy/   ← OLD system source material   (README.md = inventory + ingestion status)
   ├── target/   ← NEW system source material    (README.md = inventory + ingestion status)
   └── conversion.md  ← the parity engine (template below)
   ```
   Tell the operator to drop legacy exports into `migration/legacy/` and target/design material
   into `migration/target/`. Ingestion is via `ingest-reference` with `system:legacy` /
   `system:target` tags — never mixed.
   **Boundary — what does NOT go in `migration/`:** only material that *describes a system* (old or
   new) belongs here. Client-wide docs that describe neither — contracts, RFPs, briefs, business case,
   domain glossary — stay in the client `reference/` (`memory/clients/[client]/reference/`). The
   `migration/legacy|target` folders are specialised shelves, not a replacement for `reference/`.
4. **Run the conversion DISCOVER probes** (below) — capture answers as `REQ-`/`ASS-`/open questions.
5. **Build the stack delta** — old→new per component, risk-flag each swap.
6. **Build the Parity Matrix** — enumerate every legacy capability and map it to a target equivalent,
   migration status, and verification method. Mint `PAR-NNN` per item. This is the deliverable that
   proves coverage.
7. **Log divergences** — any intentional behavior change vs legacy → an `ADR-` + a `Changed` row in
   the matrix. Distinguishes improvement from regression.
8. **Define equivalence verification** — how parity is *proven* (golden-master, parallel run, diffing).
9. **Define cutover & rollback** — strategy, coexistence window, rollback triggers, go/no-go, legacy
   decommission.
10. **Seed conversion risks** into `risks.md` (see risk seeds below).
11. **Triple-lens** (SA: parity coverage complete? · PM: cutover/rollback/scope-creep governed? ·
    DBA: data migration + reconciliation safe?). Surface ≥1 proactive `REC-`.
12. **Show output. Wait for confirmation before writing** `conversion.md`, `migration/` READMEs,
    and new IDs to their lane files.

---

## Conversion DISCOVER probes (ask these — gaps become open questions, never assumptions)
1. **Why convert?** EOL/security, performance, hiring, cost, scalability — the driver frames trade-offs.
2. **Parity scope?** 100% parity · parity-minus-deprecated · parity-plus-new features.
3. **Source of truth for legacy behavior?** Docs / code / SMEs / existing tests — rank by reliability.
   If "the code is the spec," plan for behavior extraction.
4. **Undocumented business rules?** Edge cases, hidden validations, batch jobs, cron, reports.
5. **Data:** volume, schema complexity, data quality, downtime tolerance, reconciliation needs.
6. **Integrations:** every external system the legacy talks to (APIs, files, webhooks, DB links) —
   each must keep working or be explicitly migrated.
7. **NFR parity:** must the new system match the old SLAs/performance/throughput? By how much?
8. **Cutover approach:** big-bang vs strangler-fig/incremental; coexistence period; rollback.
9. **Legacy decommission:** when and how the old system is retired (and who signs off).
10. **Constraints:** frozen legacy (no more changes) vs moving target (legacy still being changed)?

---

## conversion.md template

```markdown
# Conversion — [Project Name]

> Next-ID: PAR-001 — read before minting; increment after every write.
> Profile: [source stack] → [target stack] · Driver: [why] (ADR-NNN) · Parity scope: [100%/minus/plus]

## 1. Stack Delta
| Layer | Legacy | Target | Risk | Notes |
|---|---|---|---|---|
| Language | [PHP 7] | [Node 20 / TS] | 🟡 | |
| Framework | [Laravel] | [NestJS] | | |
| Database | [MySQL 5.7] | [PostgreSQL 15] | 🔴 | data migration — see database.md |
| Frontend | [Blade] | [React] | | |
| Infra/Host | [on-prem] | [AWS ECS] | | |
| Integrations | [list] | [list] | | each must keep working |

## 2. Parity Matrix  (the coverage proof — nothing legacy is silently lost)
| PAR-ID | Legacy capability | Target equivalent | Status | Verification | Notes / ADR |
|---|---|---|---|---|---|
| PAR-001 | [Login w/ LDAP] | [OAuth2 + LDAP bridge] | Not started | parallel-run diff | |
| PAR-002 | [Monthly report job] | [scheduled worker] | Migrated | golden-master | |
| PAR-003 | [Legacy SOAP export] | — (dropped) | Dropped | n/a | ADR-007 sign-off |
> Status ∈ {Not started · In progress · Migrated · Verified · Dropped}. Every Dropped/Changed
> row MUST reference an ADR with explicit sign-off.

## 3. Divergence Log  (intentional change vs legacy — not accidental regression)
| Divergence | Legacy behavior | New behavior | Reason | ADR | Signed off by |
|---|---|---|---|---|---|

## 4. Equivalence Verification  (how we PROVE parity)
- **Method(s):** golden-master tests / parallel run (shadow traffic) / output diffing / UAT scripts.
- **Coverage target:** [e.g. all P0 PAR items verified before cutover].
- **Reconciliation:** [data + behavior comparison plan].

## 5. Cutover & Rollback
- **Strategy:** [strangler-fig incremental / big-bang].
- **Coexistence window:** [both systems live? for how long? source of truth during?].
- **Rollback triggers:** [error rate, data drift, failed reconciliation].
- **Go/No-Go criteria:** [checklist].
- **Legacy decommission:** [when, how, who signs off, data archival].

## 6. Open conversion questions
- [ ] [blocking question]
```

(Data migration detail — schema map old→new, transform rules, reconciliation, migration window —
lives in `database.md` under Migration plan, governed by the DBA lens. Do not duplicate it here.)

---

## Risk seeds (open these in risks.md for every conversion project)
- **RISK — Behavioral drift:** new system silently behaves differently from legacy. Trigger: failed
  diff/reconciliation. Mitigation: golden-master + parallel run before cutover.
- **RISK — Lost business logic:** undocumented legacy rules omitted. Mitigation: code-as-spec extraction;
  SME review of the Parity Matrix.
- **RISK — Data loss/corruption on migration:** see `database.md`; reconciliation mandatory.
- **RISK — Integration breakage:** a downstream consumer of the legacy breaks. Mitigation: integration
  inventory + contract tests.
- **RISK — Scope creep ("while we're rewriting…"):** new features smuggled into a parity project.
  Mitigation: Divergence Log + CHALLENGE-mode gate; parity-plus features go to a separate backlog.
- **RISK — Moving target:** legacy keeps changing during conversion. Mitigation: freeze legacy or
  track legacy changes as new PAR items.

---

## Output format

```
CONVERSION ANALYSIS — [Project] · [source stack] → [target stack]
Client: [name] | Date: [YYYY-MM-DD] | Parity scope: [100%/minus/plus]
---
Context: I read [files]. Driver: [why] (ADR-NNN). Confidence: [level].

Dual resource: migration/legacy ✓  migration/target ✓  (ingest with system:legacy / system:target)

Stack delta: [N] component swaps — highest risk: [component] 🔴

Parity Matrix: [N] PAR items — [x] Migrated · [y] In progress · [z] Not started · [d] Dropped(ADR)
  Coverage gaps (legacy capabilities not yet mapped): [list or "none"]

Divergences (intentional, ADR-backed): [N]
Equivalence verification: [method] — [coverage target]
Cutover: [strategy] · Rollback triggers: [list] · Legacy decommission: [when]

Conversion risks opened: RISK-NNN [behavioral drift], RISK-NNN [data], ...
Triple-lens: SA [parity coverage] · PM [cutover/scope governance] · DBA [data migration safety]
Proactive: REC-NNN — [recommendation]

Decisions needed · Open questions · Next steps
```

---

## Quality checklist — before I deliver
- [ ] Understanding Check confirmed by the operator.
- [ ] Source→target stack and conversion driver confirmed (driver logged as ADR-).
- [ ] `migration/legacy/` and `migration/target/` exist; ingestion tags `system:legacy`/`system:target` — never mixed.
- [ ] **Every legacy capability appears in the Parity Matrix** with a status and verification method (coverage is provable).
- [ ] Every Dropped/Changed parity row references an ADR with explicit sign-off.
- [ ] Data migration handled in `database.md` with a reconciliation step (DBA lens).
- [ ] Integration inventory captured; each integration has a keep-working or migrate decision.
- [ ] NFR-parity probed (does the new system have to match old SLAs?).
- [ ] Cutover has a rollback trigger and a legacy decommission step.
- [ ] Conversion risk seeds opened in `risks.md`; PAR-/REQ-/ADR- IDs logged to their lane files.
- [ ] Triple-lens applied; ≥1 proactive REC- surfaced.
- [ ] Output ends with **Decisions needed / Open questions / Next steps**.

## Failure exit
"Cannot run conversion analysis without the project and the from→to stack. Tell me the project and
the source→target stack (e.g. PHP/Laravel → Node/NestJS), and drop legacy material into
`migration/legacy/` so I can map parity."
