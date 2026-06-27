# Improvement Backlog

Agent self-improvement log. Managed by the `self-improvement` skill (`/check-improvements`).
**System-level, not client-specific** — this tracks how the *agent* evolves, so it is pushed.

- **Breadcrumbs** are cheap, passive records of friction. One line, no analysis, no ID.
- **Proposals (`SKL-`)** are minted only when `/check-improvements` promotes a breadcrumb.
- **Resolved** holds breadcrumbs/proposals that were acted on or consciously declined.

Format for a breadcrumb:
`- YYYY-MM-DD · <pattern> · <one-line observation> · [client or "system"]`

Patterns: `repeated-manual-work` · `ad-hoc-process` · `skill-fell-short` ·
`recurring-error` · `manual-bridge` · `post-mortem`

---

Next-ID: SKL-011
Next-WFC: WFC-005

> **2026-06-26 — `workflow-capture` merged into `self-improvement`.** The two are now one
> dual-lens skill: Lane A (friction → `SKL-`), Lane B (successful workflows → `WFC-`).
> `/check-improvements` runs both; `/capture-workflow` is an alias. Backlog keeps both
> *Breadcrumbs* (Lane A) and *Workflow candidates* (Lane B) sections.

---

## Breadcrumbs (awaiting `/check-improvements` — Lane A)

_None open — all resolved into SKL-008/009/010 below._

## Workflow candidates (awaiting `/check-improvements` — Lane B)

- 2026-06-23 · DBA schema chain (ingest→interview→trace→review→drill) ran clean (69/69 drill pass)
  across MYPS modules · already codified as the `database-admin` chain · [myps] → captured, no action
- 2026-06-25 · 4-diagram module documentation set (workflow state + data-flow + ERD + module-map) · [myps]
  → candidate, observed once — keep observing before codifying

## Proposals (`SKL-` / `WFC-`)

| ID | Title | Priority | Recommendation | Status |
|---|---|---|---|---|
| SKL-005 | Standardize sqlcmd invocation across shells | 🟡 | Standing instruction: always use PowerShell for sqlcmd (3x recurrence) | Open — tackle later |
| SKL-006 | Ground in the as-built source before building | 🔴 | Applied: `dba-schema-ingest` §5 + `CLAUDE.md` §9 + cross-session memory | **Resolved** 2026-06-25 |
| SKL-007 | Drills must use full-content fixtures, not hollow | 🔴 | Applied: `dba-schema-drill` §7 + §1 + fail criteria + checklist | **Resolved** 2026-06-25 |
| SKL-008 | Extend grounding to generated FORMATS + derivation rules | 🔴 | Applied: `dba-schema-ingest` §5.5 + `CLAUDE.md` §9 — verify generated IDs (e.g. `BP01000001LZ`) + rollups, not just enum values. Caught after SKL-006 "resolved" (invented ProjectId). | **Resolved** 2026-06-26 |
| SKL-009 | Completeness must enumerate the FULL child graph | 🔴 | Applied: `dba-schema-drill` §7 — assert every FK-child (funding/costs/cost-yr/work/locations/statuses), not a hand-picked subset. Caught after SKL-007 "resolved" (component-depth gap). | **Resolved** 2026-06-26 |
| WFC-001 | Transactional routing drill (force→verify→ROLLBACK) | 🟢 | Applied: codified as a technique in `dba-schema-drill` (Reusable techniques). Proven 4+ times across revision views. | **Resolved** 2026-06-26 |
| WFC-002 | Seed / drill split (reusable fixture + validation gate) | 🟢 | Applied: convention in `dba-schema-drill` (Reusable techniques). `*-mock-data.sql` (persistent seed) + `drill-*.sql` (validate). | **Resolved** 2026-06-26 |
| SKL-010 | Schema change isn't "done" until consumer docs updated (same pass) | 🔴 | Applied: definition-of-done gate in `dba-cross-domain-impact` + `dba-schema-changelog` + `CLAUDE.md` §9; step-6 widened to FK width + GO-batch checks. Operator prompted 2× re docs this session — docs are consumers, not follow-ups. | **Resolved** 2026-06-27 |
| WFC-003 | Synonym-based env-switch for external dependencies | 🟢 | Applied: pattern note in `references/integrations.md`. dev (Mock_PCMA) vs prod (linked server) via one synonym; views never hardcode environment. | **Resolved** 2026-06-27 |
| WFC-004 | Live-overlay view for externally-owned data (don't store) | 🟢 | Applied: pattern note in `references/integrations.md`. External-system-owned fields (PCMA construction status) → read-time view overlay, not stored columns. | **Resolved** 2026-06-27 |

**SKL-010 root cause (definition-of-done gap):** the *grounding* lessons (SKL-006/008) landed —
this session I verified ComponentId/casing/FK against the real source before designing. But the
*"done means consumers updated"* lesson hadn't: I changed the schema, declared done, left 6 docs
stale until the operator asked twice. The skill (`dba-cross-domain-impact`) already lists docs as
consumers — the gap was not firing it. Fix makes consumer-update part of definition-of-done.

**Root cause (SKL-006/007/008/009): circular validation** — generating data from assumption X,
building code assuming X, drilling against that data. All share X, so the drill can't catch a
wrong X. Only an external source (as-built system, operator) breaks the circle. SKL-006/007
fixed the *enum* and *snapshot* cases; SKL-008/009 extended the same principle to *generated
formats* and the *full child graph* after the operator caught both recurrences in the same session.
The deeper fix is behavioral: confirm formats + graph shape with the operator **up front**, before
building — cheaper than any post-hoc drill assertion. See [[verify-against-as-built-before-building]].

## Resolved

| ID | Source breadcrumb | Outcome | Date |
|---|---|---|---|
| SKL-001 | repeated-manual-work: migrated 40 lookup tables by hand + post-mortem: seed circular-dependency | Built `data-migration-playbook` skill (map→transform→order→validate→rollback; circular-dep trap designed out) | 2026-06-24 |
| SKL-002 | manual-bridge: schema→developer handoff done freehand | Built `developer-handoff` skill (`DEV-` tickets, acceptance criteria, build order, coverage check) | 2026-06-24 |
| SKL-003 | skill-fell-short: create-diagram Mermaid-only, needed C4 | Enhanced `create-diagram` with C4 Context/Container + Data Flow Diagram templates | 2026-06-24 |
| SKL-004 | recurring-error: column-mismatch bugs after ADR-018 bulk rename | Enhanced `dba-cross-domain-impact` with the cascade-rename paired-list trap (grep old+new name, verify INSERT↔SELECT/JOIN pairing) | 2026-06-24 |
| — | ad-hoc-process: building views/TVFs with no guiding skill | **No new skill** — already covered by existing `dba-sql-object-chain` (purpose→deps→draft→plan→drill); declined as duplicate | 2026-06-24 |

> Also built in the same enhancement (plan-driven, not breadcrumb-driven): the meta-skill trio
> `self-improvement` / `workflow-capture` / `memory-hygiene`, plus `api-contract-design`,
> `test-strategy`, and `calibration-review`. Full record in root `CLAUDE.md` → Build Status.
