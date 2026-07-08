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

Next-ID: SKL-024
Next-WFC: WFC-007

> **2026-06-26 — `workflow-capture` merged into `self-improvement`.** The two are now one
> dual-lens skill: Lane A (friction → `SKL-`), Lane B (successful workflows → `WFC-`).
> `/check-improvements` runs both; `/capture-workflow` is an alias. Backlog keeps both
> *Breadcrumbs* (Lane A) and *Workflow candidates* (Lane B) sections.

---

## Breadcrumbs (awaiting `/check-improvements` — Lane A)

- 2026-07-07 · post-mortem · paused mid-execution of an already-approved destructive action (Pass-column
  drop) partway through dependent-checks, needed a "you stopped" nudge to finish · [system] → one-off,
  no proposal — an approved action with passing dependent-checks should run to completion without a
  restart prompt. Promote if this recurs.

## Workflow candidates (awaiting `/check-improvements` — Lane B)

- 2026-06-25 · 4-diagram module documentation set (workflow state + data-flow + ERD + module-map) · [myps]
  → candidate, observed once — keep observing before codifying
- 2026-07-01 · User-level process walkthrough (plain-language ①–⑧ flow, confirm each step) before schema
  design on a business-rule-heavy module · [myps] → **log only, reviewed 2026-07-07** — the RBAC build
  ran process-first too, but that was `dba-process-interview` (the existing DBA chain) doing its job,
  not self-initiated freehand work. For DB modules this is already covered — only still a live
  candidate for **non-DB** modules where no chain currently mandates a process walkthrough first.

## Proposals (`SKL-` / `WFC-`)

| ID | Title | Priority | Recommendation | Status |
|---|---|---|---|---|
| SKL-023 | Post-deploy metadata drift + as-built NULL/domain profiling before seed | 🟡 | Applied: `dba-schema-drill.md` new Step 0 (metadata assert — cascade actions, nullability, uniqueness vs. deployed reality) + rule 9 + checklist item. `data-migration-playbook.md` stage 2 (TRANSFORM) + step 3 + checklist — profile source NULLs/domains against every target column that tightens a constraint before the load runs. Caught live: `tUserGroupMemberships` FKs deployed `NO_ACTION` vs documented `CASCADE` (caught by a pre-drill metadata query); seed `Msg 515` from `tGroups.CreatedDate` nullable-in-source/NOT-NULL-in-target (cost a full children-first reseed). Both from the same RBAC deployment session. | **Resolved** 2026-07-07 |
| SKL-022 | claude-mem MCP tools unreachable — documented everywhere, absent in practice | 🟡 | **Diagnosed, fix pending user action.** Root cause found (not "plugin is dead"): claude-mem's worker process is genuinely healthy (`.claude-mem/worker.pid` → live PID on port 37777), but its MCP server (`'.mcp.json'`, command `"sh"`) never registers because `sh.exe` (`C:\Program Files\Git\bin\sh.exe` / `...\Git\usr\bin\sh.exe`) is **not on the Windows system PATH** — only `C:\Program Files\Git\cmd` is, which has `git` but not `sh`. Claude Code spawns MCP servers as native Windows processes, so the `sh -c "..."` command silently fails to launch and the tools never surface, even though `enabledPlugins` says `true` and the plugin is correctly installed at `C:\Users\Msi\.claude\plugins\cache\thedotmack\claude-mem\13.4.0`. Confirmed live: `sh` resolves fine inside the Bash tool's Git Bash environment but `Get-Command sh` fails in native PowerShell. **Fix (one-time, operator action):** add `C:\Program Files\Git\bin` to the Windows System PATH (System Properties → Environment Variables → Path → New), then restart Claude Code. Not applied automatically — editing the machine-wide PATH is a persistent, machine-wide change outside repo scope, and its effect can't be verified until a fresh session start (MCP servers load once at session start). Docs (`CLAUDE.md` memory-tier table, `memory-hygiene.md`) left as-is pending verification — re-documenting to "claude-mem may be absent" would be premature given the fix is this concrete and cheap. | **Diagnosed 2026-07-07 — awaiting PATH fix + next-session verification** |
| SKL-017 | Tier-1 plan-gate drift — crisp instruction treated as confirmation | 🔴 | Applied: `CLAUDE.md` Standing Instruction #1 — multi-file or DB-mutating work requires a numbered plan + explicit go signal; a crisp request is not itself confirmation. Caught live: operator had to say "plan first, wait for my go" 3× in two days before this became the default. | **Resolved** 2026-07-07 |
| SKL-018 | Concurrent-session lane-file writes — no convention, near-miss | 🟡 | Applied: `CLAUDE.md` Standing Instruction #7 — re-read the lane file (and its `Next-ID` header) immediately before writing, never from stale context; merge alongside unexpected rows, never overwrite. Caught live: two parallel sessions both mutated `tasks.md`/`decisions.md` in the same window; no data lost only because the harness surfaced the diff. | **Resolved** 2026-07-07 |
| SKL-019 | T-SQL authoring + verification traps (sqlcmd bracket-strip, STRING_AGG, content-vs-count drills) | 🟡 | Applied: `dba-sql-object-chain.md` rules 6–7 (STRING_AGG WITHIN GROUP over undefined `@var += ORDER BY`; classic ODBC sqlcmd silently drops `[`-leading first lines of PRINT output — guard by never letting a bracket line be first). `dba-schema-drill.md` rule 8 + checklist — assert generated output CONTENT, not just row counts/LEN. Caught live: an hour chasing a vanished `[Table(...)]` line that two "green" checks (row counts, LEN) never would have caught. | **Resolved** 2026-07-07 |
| SKL-020 | Traceability gate missing from developer-handoff (RISK-026 root cause) | 🟡 | Applied: `developer-handoff.md` step 6 — bidirectional coverage check (forward REQ→ticket, reverse ticket→REQ; unbacked functions minted as DRAFT REQ- on the spot) as a standing handoff-time step, not audit-only. Closes RISK-026's recommendation (`myps/risks.md`). Caught live: 2 functions (incl. Program's most complex capability) shipped with zero requirement citation, found only on a later re-audit. | **Resolved** 2026-07-07 |
| SKL-021 | Design scatter — module spec re-assembled from 5+ docs, 3 separate times | 🟡 | Applied: `solution-design.md` step 12 + `database-admin.md` rule 7 — once a module's spec spans 3+ docs, build one canonical `<module>-schema.md` (wins on conflict, others point to it) proactively, not after a 3rd re-ask. Modeled on `ls-wallet-schema.md`, built 2026-07-07 after the operator asked for the same LS Wallet field list a third time. | **Resolved** 2026-07-07 |
| WFC-006 | Consumer-sync pass + terminal stale-term consistency grep | 🟢 | Applied: `dba-cross-domain-impact.md` Definition-of-Done rule 6 — after editing every consumer, grep the superseded concept's exact terms across all touched files; done only at zero live hits, reported as evidence. Merges the 2026-07-01 "consumer-suite audit-and-repair" candidate (same root pattern). Observed 2×: 07-01 drill-suite repair (6/6 green) and the 07-06/07 nine-document LS Wallet rewrite — both caught real stragglers the grep found that a read-through missed. | **Resolved** 2026-07-07 |
| WFC-005 | Module delivery pack: developer-handoff → test-strategy → FE/BE breakdown → user-level QA plan → board cards | 🟢 | Applied: documented as a "natural chain" in `developer-handoff.md` (Trigger section) + a pointer in `skills.md` §6 for both `developer-handoff.md` and `test-strategy.md`. No new skill built — the chain reuses 4 existing skills; only the sequencing + the two success factors (sync consumers same pass; one owner per shared service) needed writing down. Observed 6× (Program/Project-Components/Groups/Revision/tTransactionLog in this thread + LS Wallet in a parallel session — independent re-derivation was the strongest promotion signal). | **Resolved** 2026-07-03 |
| SKL-016 | New-skill "done" = ALL five consumers updated (wrapper, CLAUDE.md, skills.md, README, counts) | 🟡 | Applied: consumer checklist added to `new-skill` step 6 (slash wrapper + CLAUDE.md + skills.md + README + counts); all 52 skills registered as `.claude/commands/` wrappers same day (SKL-012 visibility resolved). Caught live: task-board build declared done with README stale — SKL-010's lesson recurring for skill additions. | **Resolved** 2026-07-03 |
| SKL-015 | Homonym trap: renamed column shares its name with a live column on another table | 🟢 | Applied: homonym caveat added to `dba-cross-domain-impact` §6b (cascade-rename). A global find-replace of a renamed column is unsafe when the old name still legitimately names a column on a *different* table (`TransactionId` dropped from tTransactionLog but live on tRevisionDetails) — disambiguate by table, then re-grep the old name and confirm every survivor's table still owns it; stragglers hide in the WHERE/DELETE filter position, not the INSERT/SELECT you edited. Caught live: `WHERE TransactionId IN (…)` cleanup line survived the rename; drill re-run (SKL-013) flagged it. | **Resolved** 2026-07-01 |
| SKL-013 | Re-run EVERY drill + verify green after any schema change (extends SKL-010) | 🔴 | Applied: DoD gate extended in `dba-cross-domain-impact` (rules 5–6 + checklist), `dba-schema-changelog` (DoD + rule 6), `dba-schema-drill` (rule 6 + checklist), `CLAUDE.md` §9. Drills are executable consumers — execute EVERY drill to green after a schema change; no doc labels a drill valid without an execution. Caught live: 5/6 broken while docs vouched for all 6. | **Resolved** 2026-07-01 |
| SKL-014 | Drill-authoring hygiene: isolated keys + self-seed/clean-slate + `QUOTED_IDENTIFIER` | 🟡 | Applied: `dba-schema-drill` new "Drill-authoring conventions (SKL-014)" section + rule 7 + checklist (header SET options, unique business-ID namespace, self-seed FK parents, full-truncate/clean-slate, idempotent). Shipped reusable `memory/clients/myps/myps-system/scripts/reset-transactional.sql` (children-first, `QUOTED_IDENTIFIER ON`). Enables SKL-013 to run cleanly. | **Resolved** 2026-07-01 |
| SKL-012 | Trigger table says "Invoke X" but employee skills aren't registered Skill-tools | 🟢 | Applied 2026-07-01: one-line note in `skills.md` §6 — employee skills are read-not-invoked; `Skill()` returns *Unknown skill*, read the `.md` file instead. **Superseded 2026-07-03:** the actual visibility gap was closed by SKL-016 — all 52 skills registered as `.claude/commands/` wrappers, so they now appear as real slash commands. The read-not-invoked note stays valid for the `Skill()` tool path. | **Resolved** 2026-07-01 (fix completed 2026-07-03, see SKL-016) |
| SKL-005 | Standardize sqlcmd invocation across shells | 🟡 | Applied: standing instruction in `CLAUDE.md` §9 — always run sqlcmd via PowerShell (`& sqlcmd … -Q`/`-i`), never Git Bash (the `-i` path throws a misleading "-E and -U/-P mutually exclusive" error). 4th+ recurrence, 0 failures once switched. | **Resolved** 2026-07-01 |
| SKL-011 | Design preflight: read the project's OWN prior deliverables before re-interviewing a module | 🔴 | Applied: `dba-schema-ingest` §0 (design preflight) + `CLAUDE.md` §9 standing rule. A NEW circle beyond SKL-006/008 — ground in your own confirmed deliverables, not just the source system. Caught live: ~10-turn `tLumpSumDetails` interview when confirmed `tLSWallets` C4 model + 8 flows already existed. | **Resolved** 2026-07-01 |
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
