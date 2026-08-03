# Memory — AI SA Employee

## Operator Profile

| Field | Value |
|---|---|
| Name | Michael Angelo A. Ferrer (Newbie) |
| Company | ERGONS |
| Role | Full-stack developer + AI employee project owner |
| Comms style | Taglish; concrete examples preferred; tap-friendly options over open interrogation |
| Real projects | MYPS, Khen Panel, Binance bots |
| Approval preference | Always propose before creating/modifying files — explicit go-ahead required |
| Core values | Token efficiency, speed, generality, honest limitations |

## Employee Behavior Notes

- **Triple-lens** on every deliverable: SA (requirements + process) + PM (risk + governance) + DBA (data + schema)
- **Understanding Check** TIERED (2026-06-12) — Tier 1 hard gate for deliverables/file changes/client-facing/estimates; Tier 2 direct answer for read-only informational asks
- **Auto-capture** — decisions, requirements, risks, assumptions logged mid-conversation without being asked
- **Meeting notes** = immediate extraction: ADR / REQ / RISK / action items / open questions
- **Client outputs** — drafts only, never sent directly; operator reviews before sending
- **RED risks** — escalated immediately per `memory/communication.md`; never left unaddressed

## Working Memory

> Updated each session — current task state. Clear when stale (>2 sessions old).

### Active Tasks

| Task | Client/Project | Status | Next action | RAG |
|---|---|---|---|---|
| User Permissions (RBAC) module | MYPS / myps-system | ✅ Reverted to LOCAL-MYPS as-is shape 2026-07-10 (ADR-031, supersedes ADR-026 + ADR-030) — schema+views+drills green | None — done | 🟢 |
| LS Wallet (Module 11) | MYPS / myps-system | Design locked (ADR-025); workflow doc completed 2026-07-08; build not started | Resume schema/build session when prioritized | 🟡 |
| Multi-Year Planning (Module 12) | MYPS / myps-system | **ON HOLD 2026-07-10** — 2 independently-sourced drafts reconciled (REQ-F101–F122 vs. new user-stories file); 1 unresolved mechanism conflict (auto PIP-sync vs. manual AIP-linking) | Dedicated client/operator reconciliation session before any further design | 🟡 |
| Bulk project import (Excel → background) | MYPS / myps-system | ✅ Core mechanism BUILT 2026-07-16 (ADR-043) — `tImportJob` hard-reject lock + `tProjectIdSequence`/`pReserveProjectIdBlock` atomic ID allocation, drilled 10/10. Hangfire REC (2026-07-15) still the recommended queue layer. | Kafka/SignalR/EF Core backend integration is specified (`project-import-kafka-signalr-flow.md`) but **not yet implemented** — dev/infra lane. Category-range exhaustion deliberately deferred (operator decision). | 🟢 |
| Data-access filtering (`ApplyFilter`, program + project level) | MYPS / myps-system | ⏸️ **UNBLOCKED 2026-07-17** — was on hold (RISK-046) pending the admin-area lock, which is now done (ADR-047). The region resolver (`vAdminOfficeRegion`) this depends on already exists. | Resume via the DBA interview chain (operator's chosen path) when prioritized — open questions + deliverable shape in `data-access-filtering-onhold.md` | 🟡 |

### Last Session

- **2026-07-15 → 2026-07-17:** Bulk Project Import System built (ADR-043 — `tImportJob` hard-reject
  lock + `tProjectIdSequence`/`pReserveProjectIdBlock` atomic ID allocation, replacing the as-built
  full-scan+race mechanism). AlternateId relocated to `tProjects` (ADR-044). Canonical
  `projects-and-revisions-design.md` written (consolidates ADR-037–046, SKL-021). `IsPublishable`
  moved from an app-side C# batch-loop to a proven SQL proc, `pRecomputeProjectPublishable`
  (ADR-045) — found + fixed a likely AsNoTracking non-persist bug in the original C# (RISK-044), then
  found the *replacement* C# integration draft repeat the same failure class on the caller side
  (RISK-045, corrected pattern given, not yet confirmed applied). Detail-chain stage-advance copy
  (funding/components/per-year/work-items/locations/docs/notes) moved to a set-based proc,
  `pCopyProjectDetailChain` (ADR-046) — remap via `MERGE...OUTPUT`, scoped for 100K+ projects/program.
  **Admin Area schema locked** (ADR-047) after the full DBA chain: `GdbId` dropped from all 5 tables
  (zero DB deps, SKL-028), geography re-keyed on `Code`, 8 per-OfficeType views + a region resolver
  built — RISK-031 closed won't-fix ("region-only is enough"), RISK-032 (Ñ-encoding) resolved by a
  fresh operator-supplied source. That source's own Excel scientific-notation corruption + missing
  Pangasinan deferred to a data-backfill pass (not a schema blocker). **Data-access filtering
  (`ApplyFilter`, program + project level) put ON HOLD** (RISK-046) pending the admin-area lock —
  now unblocked, ready to resume; full findings in `data-access-filtering-onhold.md`. Self-improvement
  pass: 6 proposals raised, 5 applied (SKL-030–033, WFC-009 — CSV code-integrity precheck, drill-suite
  registry discipline, mock-prefix isolation, `QUOTED_IDENTIFIER`-at-CREATE-time, a new read-only
  reference-lock drill archetype), 1 deferred (SKL-034, weak evidence). Full detail in
  `memory/clients/myps/myps-system/decisions.md` (ADR-043–047), `risks.md`, `improvement-backlog.md`.
- **2026-07-08 → 2026-07-10:** Admin Area re-split into 5 tables (ADR-029, since restructured/locked
  under ADR-047 — see above); RBAC reverted to LOCAL-MYPS's as-is CSV-blob shape (ADR-031); LS Wallet
  workflow doc completed (RISK-033); Module 12 Multi-Year put on hold. Archived —
  `memory/archive/claude-mem-archive.md`.
- **2026-06-12 → 2026-07-07:** Prior work (system build-out, RBAC's original ADR-026 build) —
  archived at `memory/archive/claude-mem-archive.md`.

## Client Index

| Client | Industry | Active Projects | Record |
|---|---|---|---|
| MYPS | Government (DPWH, Philippines) | myps-system (SQL Server rebuild + conversion) | `memory/clients/myps/myps.md` |

## Knowledge Base Summary

> Distilled KB entries stored in claude-mem — retrieve with `mem search [topic]`.
> This section lists CATEGORIES only; full entries retrieved on demand.

| Category | Count | Key topics |
|---|---|---|
| — | — | — |
