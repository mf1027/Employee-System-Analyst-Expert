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

Next-ID: SKL-008

---

## Breadcrumbs (awaiting `/check-improvements`)

- 2026-06-25 · ad-hoc-process · drill didn't mandate state-coverage check (all revisions terminal, queues untested until manual intervention) · [myps]
- 2026-06-25 · ad-hoc-process · EF [Key] uniqueness check (COUNT vs COUNT DISTINCT) done ad-hoc — should be a standard drill step for EF-mapped objects · [system]

## Workflow candidates (awaiting `/capture-workflow`)

- 2026-06-23 · DBA schema chain (ingest→interview→trace→review→drill) ran clean (69/69 drill pass)
  across MYPS modules · already codified as the `database-admin` chain · [myps] → captured, no action
- 2026-06-25 · Transactional routing drill: BEGIN TRAN → force rows into distinct states → verify routing → ROLLBACK. Worked clean for revision queue views. Cross-project pattern for any status-filtered view. · [system]

## Proposals (`SKL-`)

| ID | Title | Priority | Recommendation | Status |
|---|---|---|---|---|
| SKL-005 | Standardize sqlcmd invocation across shells | 🟡 | Standing instruction: always use PowerShell for sqlcmd (3x recurrence) | Open — tackle later |
| SKL-006 | Ground in the as-built source before building | 🔴 | Applied: enhanced `dba-schema-ingest` §5 (as-built semantics verification) + standing rule in `CLAUDE.md` §9 + cross-session memory | **Resolved** 2026-06-25 |
| SKL-007 | Drills must use full-content fixtures, not hollow | 🔴 | Applied: enhanced `dba-schema-drill` §7 (referential-completeness asserts) + §1 (full-content fixture rule) + fail criteria + quality checklist | **Resolved** 2026-06-25 |

**Root cause linking SKL-006/007: circular validation** — generating data from assumption X,
building code assuming X, drilling against that data. All share X, so the drill can't catch a
wrong X. Only an external source (as-built system, operator) breaks the circle. This session the
operator was the external check 4 times (invented enum, hollow data ×2, unread process flow).

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
