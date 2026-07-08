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
| User Permissions (RBAC) module | MYPS / myps-system | ✅ Shipped 2026-07-07 (ADR-026) — schema+seed+drill green | None — done | 🟢 |
| LS Wallet (Module 11) | MYPS / myps-system | Design locked (ADR-025); build not started | Resume schema/build session when prioritized | 🟡 |
| Multi-Year Planning (Module 12) | MYPS / myps-system | URD drafted (REQ-F101–F122); Phase 1 vs Phase 2 scope unconfirmed (RISK-007) | Confirm scope with client before build | 🟡 |

### Last Session

- **2026-06-12 → 2026-06-16:** System build-out — Phase 2 document engines (LibreOffice+Poppler),
  `ai-sa-employee/` consolidation + hybrid `engines/` strategy, PDF workflow (`pdf-source/` +
  Java/opendataloader), `scrum-master` skill (31st), `conversion-analysis` skill (32nd), docs
  boundary cleanup. Durable facts live in root `CLAUDE.md` Build Status table; full narrative
  archived at `memory/archive/claude-mem-archive.md`.
- **2026-07-07:** MYPS User Permissions (RBAC) module fully shipped — see Active Tasks + ADR-026
  in `memory/clients/myps/myps-system/decisions.md`. Memory-hygiene pass run same day (this entry).

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
